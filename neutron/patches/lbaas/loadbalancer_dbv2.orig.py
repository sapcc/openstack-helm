#
# Copyright 2014-2015 Rackspace.  All rights reserved
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import re

from neutron.api.v2 import attributes
from neutron.callbacks import events
from neutron.callbacks import registry
from neutron.callbacks import resources
from neutron.db import common_db_mixin as base_db
from neutron import manager
from neutron.plugins.common import constants
from neutron_lib import constants as n_constants
from neutron_lib import exceptions as n_exc
from oslo_db import exception
from oslo_log import log as logging
from oslo_utils import excutils
from oslo_utils import uuidutils
from sqlalchemy import orm
from sqlalchemy.orm import exc

from neutron_lbaas._i18n import _
from neutron_lbaas import agent_scheduler
from neutron_lbaas.db.loadbalancer import models
from neutron_lbaas.extensions import l7
from neutron_lbaas.extensions import loadbalancerv2
from neutron_lbaas.extensions import sharedpools
from neutron_lbaas.services.loadbalancer import constants as lb_const
from neutron_lbaas.services.loadbalancer import data_models


LOG = logging.getLogger(__name__)


class LoadBalancerPluginDbv2(base_db.CommonDbMixin,
                             agent_scheduler.LbaasAgentSchedulerDbMixin):
    """Wraps loadbalancer with SQLAlchemy models.

    A class that wraps the implementation of the Neutron loadbalancer
    plugin database access interface using SQLAlchemy models.
    """

    @property
    def _core_plugin(self):
        return manager.NeutronManager.get_plugin()

    def _get_resource(self, context, model, id, for_update=False):
        resource = None
        try:
            if for_update:
                query = self._model_query(context, model).filter(
                    model.id == id).with_lockmode('update')
                resource = query.one()
            else:
                resource = self._get_by_id(context, model, id)
        except exc.NoResultFound:
            with excutils.save_and_reraise_exception(reraise=False) as ctx:
                if issubclass(model, (models.LoadBalancer, models.Listener,
                                      models.L7Policy, models.L7Rule,
                                      models.PoolV2, models.MemberV2,
                                      models.HealthMonitorV2,
                                      models.LoadBalancerStatistics,
                                      models.SessionPersistenceV2)):
                    raise loadbalancerv2.EntityNotFound(name=model.NAME, id=id)
                ctx.reraise = True
        return resource

    def _resource_exists(self, context, model, id):
        try:
            self._get_by_id(context, model, id)
        except exc.NoResultFound:
            return False
        return True

    def _get_resources(self, context, model, filters=None):
        query = self._get_collection_query(context, model,
                                           filters=filters)
        return [model_instance for model_instance in query]

    def _create_port_for_load_balancer(self, context, lb_db, ip_address):
        # resolve subnet and create port
        subnet = self._core_plugin.get_subnet(context, lb_db.vip_subnet_id)
        fixed_ip = {'subnet_id': subnet['id']}
        if ip_address and ip_address != attributes.ATTR_NOT_SPECIFIED:
            fixed_ip['ip_address'] = ip_address

        port_data = {
            'tenant_id': lb_db.tenant_id,
            'name': 'loadbalancer-' + lb_db.id,
            'network_id': subnet['network_id'],
            'mac_address': attributes.ATTR_NOT_SPECIFIED,
            'admin_state_up': False,
            'device_id': lb_db.id,
            'device_owner': n_constants.DEVICE_OWNER_LOADBALANCERV2,
            'fixed_ips': [fixed_ip]
        }

        port = self._core_plugin.create_port(context, {'port': port_data})
        lb_db.vip_port_id = port['id']
        for fixed_ip in port['fixed_ips']:
            if fixed_ip['subnet_id'] == lb_db.vip_subnet_id:
                lb_db.vip_address = fixed_ip['ip_address']
                break

        # explicitly sync session with db
        context.session.flush()

    def _create_loadbalancer_stats(self, context, loadbalancer_id, data=None):
        # This is internal method to add load balancer statistics.  It won't
        # be exposed to API
        data = data or {}
        stats_db = models.LoadBalancerStatistics(
            loadbalancer_id=loadbalancer_id,
            bytes_in=data.get(lb_const.STATS_IN_BYTES, 0),
            bytes_out=data.get(lb_const.STATS_OUT_BYTES, 0),
            active_connections=data.get(lb_const.STATS_ACTIVE_CONNECTIONS, 0),
            total_connections=data.get(lb_const.STATS_TOTAL_CONNECTIONS, 0)
        )
        return stats_db

    def _delete_loadbalancer_stats(self, context, loadbalancer_id):
        # This is internal method to delete pool statistics. It won't
        # be exposed to API
        with context.session.begin(subtransactions=True):
            stats_qry = context.session.query(models.LoadBalancerStatistics)
            try:
                stats = stats_qry.filter_by(
                    loadbalancer_id=loadbalancer_id).one()
            except exc.NoResultFound:
                raise loadbalancerv2.EntityNotFound(
                    name=models.LoadBalancerStatistics.NAME,
                    id=loadbalancer_id)
            context.session.delete(stats)

    def _load_id(self, context, model_dict):
        model_dict['id'] = uuidutils.generate_uuid()

    def assert_modification_allowed(self, obj):
        status = getattr(obj, 'provisioning_status', None)
        if status in [constants.PENDING_DELETE, constants.PENDING_UPDATE,
                      constants.PENDING_CREATE]:
            id = getattr(obj, 'id', None)
            raise loadbalancerv2.StateInvalid(id=id, state=status)

    def test_and_set_status(self, context, model, id, status):
        with context.session.begin(subtransactions=True):
            db_lb_child = None
            if model == models.LoadBalancer:
                db_lb = self._get_resource(context, model, id, for_update=True)
            else:
                db_lb_child = self._get_resource(context, model, id)
                db_lb = self._get_resource(context, models.LoadBalancer,
                                           db_lb_child.root_loadbalancer.id)
            # This method will raise an exception if modification is not
            # allowed.
            self.assert_modification_allowed(db_lb)

            # if the model passed in is not a load balancer then we will
            # set its root load balancer's provisioning status to
            # PENDING_UPDATE and the model's status to the status passed in
            # Otherwise we are just setting the load balancer's provisioning
            # status to the status passed in
            if db_lb_child:
                db_lb.provisioning_status = constants.PENDING_UPDATE
                db_lb_child.provisioning_status = status
            else:
                db_lb.provisioning_status = status

    def update_loadbalancer_provisioning_status(self, context, lb_id,
                                                status=constants.ACTIVE):
        self.update_status(context, models.LoadBalancer, lb_id,
                           provisioning_status=status)

    def update_status(self, context, model, id, provisioning_status=None,
                      operating_status=None):
        with context.session.begin(subtransactions=True):
            if issubclass(model, models.LoadBalancer):
                try:
                    model_db = (self._model_query(context, model).
                                filter(model.id == id).
                                options(orm.noload('vip_port')).
                                one())
                except exc.NoResultFound:
                    raise loadbalancerv2.EntityNotFound(
                        name=models.LoadBalancer.NAME, id=id)
            else:
                model_db = self._get_resource(context, model, id)
            if provisioning_status and (model_db.provisioning_status !=
                                        provisioning_status):
                model_db.provisioning_status = provisioning_status
            if (operating_status and hasattr(model_db, 'operating_status') and
                    model_db.operating_status != operating_status):
                model_db.operating_status = operating_status

    def create_loadbalancer(self, context, loadbalancer, allocate_vip=True):
        with context.session.begin(subtransactions=True):
            self._load_id(context, loadbalancer)
            vip_address = loadbalancer.pop('vip_address')
            loadbalancer['provisioning_status'] = constants.PENDING_CREATE
            loadbalancer['operating_status'] = lb_const.OFFLINE
            lb_db = models.LoadBalancer(**loadbalancer)
            context.session.add(lb_db)
            context.session.flush()
            lb_db.stats = self._create_loadbalancer_stats(
                context, lb_db.id)
            context.session.add(lb_db)

        # create port outside of lb create transaction since it can sometimes
        # cause lock wait timeouts
        if allocate_vip:
            LOG.debug("Plugin will allocate the vip as a neutron port.")
            try:
                self._create_port_for_load_balancer(context, lb_db,
                                                    vip_address)
            except Exception:
                with excutils.save_and_reraise_exception():
                    context.session.delete(lb_db)
                    context.session.flush()
        return data_models.LoadBalancer.from_sqlalchemy_model(lb_db)

    def update_loadbalancer(self, context, id, loadbalancer):
        with context.session.begin(subtransactions=True):
            lb_db = self._get_resource(context, models.LoadBalancer, id)
            lb_db.update(loadbalancer)
        return data_models.LoadBalancer.from_sqlalchemy_model(lb_db)

    def delete_loadbalancer(self, context, id, delete_vip_port=True):
        with context.session.begin(subtransactions=True):
            lb_db = self._get_resource(context, models.LoadBalancer, id)
            context.session.delete(lb_db)
        if delete_vip_port and lb_db.vip_port:
            self._core_plugin.delete_port(context, lb_db.vip_port_id)

    def prevent_lbaasv2_port_deletion(self, context, port_id):
        try:
            port_db = self._core_plugin._get_port(context, port_id)
        except n_exc.PortNotFound:
            return
        if port_db['device_owner'] == n_constants.DEVICE_OWNER_LOADBALANCERV2:
            filters = {'vip_port_id': [port_id]}
            if len(self.get_loadbalancers(context, filters=filters)) > 0:
                reason = _('has device owner %s') % port_db['device_owner']
                raise n_exc.ServicePortInUse(port_id=port_db['id'],
                                             reason=reason)

    def subscribe(self):
        registry.subscribe(
            _prevent_lbaasv2_port_delete_callback, resources.PORT,
            events.BEFORE_DELETE)

    def get_loadbalancers(self, context, filters=None):
        lb_dbs = self._get_resources(context, models.LoadBalancer,
                                     filters=filters)
        return [data_models.LoadBalancer.from_sqlalchemy_model(lb_db)
                for lb_db in lb_dbs]

    def get_loadbalancer(self, context, id):
        lb_db = self._get_resource(context, models.LoadBalancer, id)
        return data_models.LoadBalancer.from_sqlalchemy_model(lb_db)

    def _validate_listener_data(self, context, listener):
        pool_id = listener.get('default_pool_id')
        lb_id = listener.get('loadbalancer_id')
        if lb_id:
            if not self._resource_exists(context, models.LoadBalancer,
                                         lb_id):
                raise loadbalancerv2.EntityNotFound(
                    name=models.LoadBalancer.NAME, id=lb_id)
        if pool_id:
            if not self._resource_exists(context, models.PoolV2, pool_id):
                raise loadbalancerv2.EntityNotFound(
                    name=models.PoolV2.NAME, id=pool_id)
            pool = self._get_resource(context, models.PoolV2, pool_id)
            if ((pool.protocol, listener.get('protocol'))
                not in lb_const.LISTENER_POOL_COMPATIBLE_PROTOCOLS):
                raise loadbalancerv2.ListenerPoolProtocolMismatch(
                    listener_proto=listener['protocol'],
                    pool_proto=pool.protocol)
        if lb_id and pool_id:
            pool = self._get_resource(context, models.PoolV2, pool_id)
            if pool.loadbalancer_id != lb_id:
                raise sharedpools.ListenerPoolLoadbalancerMismatch(
                    pool_id=pool_id,
                    lb_id=pool.loadbalancer_id)

    def _validate_l7policy_data(self, context, l7policy):
        if l7policy['action'] == lb_const.L7_POLICY_ACTION_REDIRECT_TO_POOL:
            if not l7policy['redirect_pool_id']:
                raise l7.L7PolicyRedirectPoolIdMissing()
            if not self._resource_exists(
                context, models.PoolV2, l7policy['redirect_pool_id']):
                raise loadbalancerv2.EntityNotFound(
                    name=models.PoolV2.NAME, id=l7policy['redirect_pool_id'])

            pool = self._get_resource(
                context, models.PoolV2, l7policy['redirect_pool_id'])

            listener = self._get_resource(
                context, models.Listener, l7policy['listener_id'])

            if pool.loadbalancer_id != listener.loadbalancer_id:
                raise sharedpools.ListenerAndPoolMustBeOnSameLoadbalancer()

        if (l7policy['action'] == lb_const.L7_POLICY_ACTION_REDIRECT_TO_URL
            and 'redirect_url' not in l7policy):
            raise l7.L7PolicyRedirectUrlMissing()

    def _validate_l7rule_data(self, context, rule):
        def _validate_regex(regex):
            try:
                re.compile(regex)
            except Exception as e:
                raise l7.L7RuleInvalidRegex(e=str(e))

        def _validate_key(key):
            p = re.compile(lb_const.HTTP_HEADER_COOKIE_NAME_REGEX)
            if not p.match(key):
                raise l7.L7RuleInvalidKey()

        def _validate_cookie_value(value):
            p = re.compile(lb_const.HTTP_COOKIE_VALUE_REGEX)
            if not p.match(value):
                raise l7.L7RuleInvalidCookieValue()

        def _validate_non_cookie_value(value):
            p = re.compile(lb_const.HTTP_HEADER_VALUE_REGEX)
            q = re.compile(lb_const.HTTP_QUOTED_HEADER_VALUE_REGEX)
            if not p.match(value) and not q.match(value):
                raise l7.L7RuleInvalidHeaderValue()

        if rule['compare_type'] == lb_const.L7_RULE_COMPARE_TYPE_REGEX:
            _validate_regex(rule['value'])

        if rule['type'] in [lb_const.L7_RULE_TYPE_HEADER,
                            lb_const.L7_RULE_TYPE_COOKIE]:
            if ('key' not in rule or not rule['key']):
                raise l7.L7RuleKeyMissing()
            _validate_key(rule['key'])

        if rule['compare_type'] != lb_const.L7_RULE_COMPARE_TYPE_REGEX:
            if rule['type'] == lb_const.L7_RULE_TYPE_COOKIE:
                _validate_cookie_value(rule['value'])
            else:
                if rule['type'] in [lb_const.L7_RULE_TYPE_HEADER,
                                  lb_const.L7_RULE_TYPE_HOST_NAME,
                                  lb_const.L7_RULE_TYPE_PATH]:
                    _validate_non_cookie_value(rule['value'])
                elif (rule['compare_type'] ==
                      lb_const.L7_RULE_COMPARE_TYPE_EQUAL_TO):
                    _validate_non_cookie_value(rule['value'])
                else:
                    raise l7.L7RuleUnsupportedCompareType(type=rule['type'])

    def _convert_api_to_db(self, listener):
        # NOTE(blogan): Converting the values for db models for now to
        # limit the scope of this change
        if 'default_tls_container_ref' in listener:
            tls_cref = listener.get('default_tls_container_ref')
            del listener['default_tls_container_ref']
            listener['default_tls_container_id'] = tls_cref
        if 'sni_container_refs' in listener:
            sni_crefs = listener.get('sni_container_refs')
            del listener['sni_container_refs']
            listener['sni_container_ids'] = sni_crefs

    def create_listener(self, context, listener):
        self._convert_api_to_db(listener)
        try:
            with context.session.begin(subtransactions=True):
                self._load_id(context, listener)
                listener['provisioning_status'] = constants.PENDING_CREATE
                listener['operating_status'] = lb_const.OFFLINE
                # Check for unspecified loadbalancer_id and listener_id and
                # set to None
                for id in ['loadbalancer_id', 'default_pool_id']:
                    if listener.get(id) == attributes.ATTR_NOT_SPECIFIED:
                        listener[id] = None

                self._validate_listener_data(context, listener)
                sni_container_ids = []
                if 'sni_container_ids' in listener:
                    sni_container_ids = listener.pop('sni_container_ids')
                listener_db_entry = models.Listener(**listener)
                for container_id in sni_container_ids:
                    sni = models.SNI(listener_id=listener_db_entry.id,
                                     tls_container_id=container_id)
                    listener_db_entry.sni_containers.append(sni)
                context.session.add(listener_db_entry)
        except exception.DBDuplicateEntry:
            raise loadbalancerv2.LoadBalancerListenerProtocolPortExists(
                lb_id=listener['loadbalancer_id'],
                protocol_port=listener['protocol_port'])
        context.session.refresh(listener_db_entry.loadbalancer)
        return data_models.Listener.from_sqlalchemy_model(listener_db_entry)

    def update_listener(self, context, id, listener,
                        tls_containers_changed=False):
        self._convert_api_to_db(listener)
        with context.session.begin(subtransactions=True):
            listener_db = self._get_resource(context, models.Listener, id)

            if not listener.get('protocol'):
                # User did not intend to change the protocol so we will just
                # use the same protocol already stored so the validation knows
                listener['protocol'] = listener_db.protocol
            self._validate_listener_data(context, listener)

            if tls_containers_changed:
                listener_db.sni_containers = []
                for container_id in listener['sni_container_ids']:
                    sni = models.SNI(listener_id=id,
                                     tls_container_id=container_id)
                    listener_db.sni_containers.append(sni)

            listener_db.update(listener)

        context.session.refresh(listener_db)
        return data_models.Listener.from_sqlalchemy_model(listener_db)

    def delete_listener(self, context, id):
        listener_db_entry = self._get_resource(context, models.Listener, id)
        with context.session.begin(subtransactions=True):
            context.session.delete(listener_db_entry)

    def get_listeners(self, context, filters=None):
        listener_dbs = self._get_resources(context, models.Listener,
                                           filters=filters)
        return [data_models.Listener.from_sqlalchemy_model(listener_db)
                for listener_db in listener_dbs]

    def get_listener(self, context, id):
        listener_db = self._get_resource(context, models.Listener, id)
        return data_models.Listener.from_sqlalchemy_model(listener_db)

    def _create_session_persistence_db(self, session_info, pool_id):
        session_info['pool_id'] = pool_id
        return models.SessionPersistenceV2(**session_info)

    def _update_pool_session_persistence(self, context, pool_id, info):
        # removing these keys as it is possible that they are passed in and
        # their existence will cause issues bc they are not acceptable as
        # dictionary values
        info.pop('pool', None)
        info.pop('pool_id', None)
        pool = self._get_resource(context, models.PoolV2, pool_id)
        with context.session.begin(subtransactions=True):
            # Update sessionPersistence table
            sess_qry = context.session.query(models.SessionPersistenceV2)
            sesspersist_db = sess_qry.filter_by(pool_id=pool_id).first()

            # Insert a None cookie_info if it is not present to overwrite an
            # existing value in the database.
            if 'cookie_name' not in info:
                info['cookie_name'] = None

            if sesspersist_db:
                sesspersist_db.update(info)
            else:
                info['pool_id'] = pool_id
                sesspersist_db = models.SessionPersistenceV2(**info)
                context.session.add(sesspersist_db)
                # Update pool table
                pool.session_persistence = sesspersist_db
            context.session.add(pool)

    def _delete_session_persistence(self, context, pool_id):
        with context.session.begin(subtransactions=True):
            sess_qry = context.session.query(models.SessionPersistenceV2)
            sess_qry.filter_by(pool_id=pool_id).delete()

    def create_pool(self, context, pool):
        with context.session.begin(subtransactions=True):
            self._load_id(context, pool)
            pool['provisioning_status'] = constants.PENDING_CREATE
            pool['operating_status'] = lb_const.OFFLINE

            session_info = pool.pop('session_persistence')
            pool_db = models.PoolV2(**pool)

            if session_info:
                s_p = self._create_session_persistence_db(session_info,
                                                          pool_db.id)
                pool_db.session_persistence = s_p

            context.session.add(pool_db)
        return data_models.Pool.from_sqlalchemy_model(pool_db)

    def update_pool(self, context, id, pool):
        with context.session.begin(subtransactions=True):
            pool_db = self._get_resource(context, models.PoolV2, id)
            hm_id = pool.get('healthmonitor_id')
            if hm_id:
                if not self._resource_exists(context, models.HealthMonitorV2,
                                             hm_id):
                    raise loadbalancerv2.EntityNotFound(
                        name=models.HealthMonitorV2.NAME,
                        id=hm_id)
                filters = {'healthmonitor_id': [hm_id]}
                hmpools = self._get_resources(context,
                                              models.PoolV2,
                                              filters=filters)
                if hmpools:
                    raise loadbalancerv2.EntityInUse(
                        entity_using=models.PoolV2.NAME,
                        id=hmpools[0].id,
                        entity_in_use=models.HealthMonitorV2.NAME)

            # Only update or delete session persistence if it was part
            # of the API request.
            if 'session_persistence' in pool.keys():
                sp = pool.pop('session_persistence')
                if sp is None or sp == {}:
                    self._delete_session_persistence(context, id)
                else:
                    self._update_pool_session_persistence(context, id, sp)

            # sqlalchemy cries if listeners is defined.
            listeners = pool.get('listeners')
            if listeners:
                del pool['listeners']
            pool_db.update(pool)
        context.session.refresh(pool_db)
        return data_models.Pool.from_sqlalchemy_model(pool_db)

    def delete_pool(self, context, id):
        with context.session.begin(subtransactions=True):
            pool_db = self._get_resource(context, models.PoolV2, id)
            for l in pool_db.listeners:
                self.update_listener(context, l.id,
                                     {'default_pool_id': None})
            for l in pool_db.loadbalancer.listeners:
                for p in l.l7_policies:
                    if (p.action == lb_const.L7_POLICY_ACTION_REDIRECT_TO_POOL
                        and p.redirect_pool_id == id):
                        self.update_l7policy(
                            context, p.id,
                            {'redirect_pool_id': None,
                             'action': lb_const.L7_POLICY_ACTION_REJECT})
            context.session.delete(pool_db)

    def get_pools(self, context, filters=None):
        pool_dbs = self._get_resources(context, models.PoolV2, filters=filters)
        return [data_models.Pool.from_sqlalchemy_model(pool_db)
                for pool_db in pool_dbs]

    def get_pool(self, context, id):
        pool_db = self._get_resource(context, models.PoolV2, id)
        return data_models.Pool.from_sqlalchemy_model(pool_db)

    def create_pool_member(self, context, member, pool_id):
        try:
            with context.session.begin(subtransactions=True):
                self._load_id(context, member)
                member['pool_id'] = pool_id
                member['provisioning_status'] = constants.PENDING_CREATE
                member['operating_status'] = lb_const.OFFLINE
                member_db = models.MemberV2(**member)
                context.session.add(member_db)
        except exception.DBDuplicateEntry:
            raise loadbalancerv2.MemberExists(address=member['address'],
                                              port=member['protocol_port'],
                                              pool=pool_id)
        context.session.refresh(member_db.pool)
        return data_models.Member.from_sqlalchemy_model(member_db)

    def update_pool_member(self, context, id, member):
        with context.session.begin(subtransactions=True):
            member_db = self._get_resource(context, models.MemberV2, id)
            member_db.update(member)
        context.session.refresh(member_db)
        return data_models.Member.from_sqlalchemy_model(member_db)

    def delete_pool_member(self, context, id):
        with context.session.begin(subtransactions=True):
            member_db = self._get_resource(context, models.MemberV2, id)
            context.session.delete(member_db)

    def get_pool_members(self, context, filters=None):
        filters = filters or {}
        member_dbs = self._get_resources(context, models.MemberV2,
                                         filters=filters)
        return [data_models.Member.from_sqlalchemy_model(member_db)
                for member_db in member_dbs]

    def get_pool_member(self, context, id):
        member_db = self._get_resource(context, models.MemberV2, id)
        return data_models.Member.from_sqlalchemy_model(member_db)

    def delete_member(self, context, id):
        with context.session.begin(subtransactions=True):
            member_db = self._get_resource(context, models.MemberV2, id)
            context.session.delete(member_db)

    def create_healthmonitor_on_pool(self, context, pool_id, healthmonitor):
        with context.session.begin(subtransactions=True):
            hm_db = self.create_healthmonitor(context, healthmonitor)
            pool = self.get_pool(context, pool_id)
            # do not want listener, members, healthmonitor or loadbalancer
            # in dict
            pool_dict = pool.to_dict(listeners=False, members=False,
                                     healthmonitor=False, loadbalancer=False,
                                     listener=False, loadbalancer_id=False)
            pool_dict['healthmonitor_id'] = hm_db.id
            self.update_pool(context, pool_id, pool_dict)
            hm_db = self._get_resource(context, models.HealthMonitorV2,
                                       hm_db.id)
        return data_models.HealthMonitor.from_sqlalchemy_model(hm_db)

    def create_healthmonitor(self, context, healthmonitor):
        with context.session.begin(subtransactions=True):
            self._load_id(context, healthmonitor)
            healthmonitor['provisioning_status'] = constants.PENDING_CREATE
            hm_db_entry = models.HealthMonitorV2(**healthmonitor)
            context.session.add(hm_db_entry)
        return data_models.HealthMonitor.from_sqlalchemy_model(hm_db_entry)

    def update_healthmonitor(self, context, id, healthmonitor):
        with context.session.begin(subtransactions=True):
            hm_db = self._get_resource(context, models.HealthMonitorV2, id)
            hm_db.update(healthmonitor)
        context.session.refresh(hm_db)
        return data_models.HealthMonitor.from_sqlalchemy_model(hm_db)

    def delete_healthmonitor(self, context, id):
        with context.session.begin(subtransactions=True):
            hm_db_entry = self._get_resource(context,
                                             models.HealthMonitorV2, id)
            # TODO(sbalukoff): Clear out pool.healthmonitor_ids referencing
            # old healthmonitor ID.
            context.session.delete(hm_db_entry)

    def get_healthmonitor(self, context, id):
        hm_db = self._get_resource(context, models.HealthMonitorV2, id)
        return data_models.HealthMonitor.from_sqlalchemy_model(hm_db)

    def get_healthmonitors(self, context, filters=None):
        filters = filters or {}
        hm_dbs = self._get_resources(context, models.HealthMonitorV2,
                                     filters=filters)
        return [data_models.HealthMonitor.from_sqlalchemy_model(hm_db)
                for hm_db in hm_dbs]

    def update_loadbalancer_stats(self, context, loadbalancer_id, stats_data):
        stats_data = stats_data or {}
        with context.session.begin(subtransactions=True):
            lb_db = self._get_resource(context, models.LoadBalancer,
                                       loadbalancer_id)
            lb_db.stats = self._create_loadbalancer_stats(context,
                                                          loadbalancer_id,
                                                          data=stats_data)

    def stats(self, context, loadbalancer_id):
        loadbalancer = self._get_resource(context, models.LoadBalancer,
                                          loadbalancer_id)
        return data_models.LoadBalancerStatistics.from_sqlalchemy_model(
            loadbalancer.stats)

    def create_l7policy(self, context, l7policy):
        if l7policy['redirect_pool_id'] == attributes.ATTR_NOT_SPECIFIED:
            l7policy['redirect_pool_id'] = None
        self._validate_l7policy_data(context, l7policy)

        with context.session.begin(subtransactions=True):
            listener_id = l7policy.get('listener_id')
            listener_db = self._get_resource(
                context, models.Listener, listener_id)

            if not listener_db:
                raise loadbalancerv2.EntityNotFound(
                    name=models.Listener.NAME, id=listener_id)
            self._load_id(context, l7policy)

            l7policy['provisioning_status'] = constants.PENDING_CREATE

            l7policy_db = models.L7Policy(**l7policy)
            # MySQL int fields are by default 32-bit whereas handy system
            # constants like sys.maxsize are 64-bit on most platforms today.
            # Hence the reason this is 2147483647 (2^31 - 1) instead of an
            # elsewhere-defined constant.
            if l7policy['position'] == 2147483647:
                listener_db.l7_policies.append(l7policy_db)
            else:
                listener_db.l7_policies.insert(l7policy['position'] - 1,
                                               l7policy_db)

            listener_db.l7_policies.reorder()

        return data_models.L7Policy.from_sqlalchemy_model(l7policy_db)

    def update_l7policy(self, context, id, l7policy):
        with context.session.begin(subtransactions=True):

            l7policy_db = self._get_resource(context, models.L7Policy, id)

            if 'action' in l7policy:
                l7policy['listener_id'] = l7policy_db.listener_id
                self._validate_l7policy_data(context, l7policy)

            if ('position' not in l7policy or
                l7policy['position'] == 2147483647 or
                l7policy_db.position == l7policy['position']):
                l7policy_db.update(l7policy)
            else:
                listener_id = l7policy_db.listener_id
                listener_db = self._get_resource(
                    context, models.Listener, listener_id)
                l7policy_db = listener_db.l7_policies.pop(
                    l7policy_db.position - 1)

                l7policy_db.update(l7policy)
                listener_db.l7_policies.insert(l7policy['position'] - 1,
                                               l7policy_db)
                listener_db.l7_policies.reorder()

        context.session.refresh(l7policy_db)
        return data_models.L7Policy.from_sqlalchemy_model(l7policy_db)

    def delete_l7policy(self, context, id):
        with context.session.begin(subtransactions=True):
            l7policy_db = self._get_resource(context, models.L7Policy, id)
            listener_id = l7policy_db.listener_id
            listener_db = self._get_resource(
                context, models.Listener, listener_id)
            listener_db.l7_policies.remove(l7policy_db)

    def get_l7policy(self, context, id):
        l7policy_db = self._get_resource(context, models.L7Policy, id)
        return data_models.L7Policy.from_sqlalchemy_model(l7policy_db)

    def get_l7policies(self, context, filters=None):
        l7policy_dbs = self._get_resources(context, models.L7Policy,
                                           filters=filters)
        return [data_models.L7Policy.from_sqlalchemy_model(l7policy_db)
                for l7policy_db in l7policy_dbs]

    def create_l7policy_rule(self, context, rule, l7policy_id):
        with context.session.begin(subtransactions=True):
            if not self._resource_exists(context, models.L7Policy,
                                         l7policy_id):
                raise loadbalancerv2.EntityNotFound(
                    name=models.L7Policy.NAME, id=l7policy_id)
            self._validate_l7rule_data(context, rule)
            self._load_id(context, rule)
            rule['l7policy_id'] = l7policy_id
            rule['provisioning_status'] = constants.PENDING_CREATE
            rule_db = models.L7Rule(**rule)
            context.session.add(rule_db)
        return data_models.L7Rule.from_sqlalchemy_model(rule_db)

    def update_l7policy_rule(self, context, id, rule, l7policy_id):
        with context.session.begin(subtransactions=True):
            if not self._resource_exists(context, models.L7Policy,
                                         l7policy_id):
                raise l7.RuleNotFoundForL7Policy(
                    l7policy_id=l7policy_id, rule_id=id)

            rule_db = self._get_resource(context, models.L7Rule, id)
            # If user did not intend to change all parameters,
            # already stored parameters will be used for validations
            if not rule.get('type'):
                rule['type'] = rule_db.type
            if not rule.get('value'):
                rule['value'] = rule_db.value
            if not rule.get('compare_type'):
                rule['compare_type'] = rule_db.compare_type

            self._validate_l7rule_data(context, rule)
            rule_db = self._get_resource(context, models.L7Rule, id)
            rule_db.update(rule)
        context.session.refresh(rule_db)
        return data_models.L7Rule.from_sqlalchemy_model(rule_db)

    def delete_l7policy_rule(self, context, id):
        with context.session.begin(subtransactions=True):
            rule_db_entry = self._get_resource(context, models.L7Rule, id)
            context.session.delete(rule_db_entry)

    def get_l7policy_rule(self, context, id, l7policy_id):
        rule_db = self._get_resource(context, models.L7Rule, id)
        if rule_db.l7policy_id != l7policy_id:
            raise l7.RuleNotFoundForL7Policy(
                l7policy_id=l7policy_id, rule_id=id)
        return data_models.L7Rule.from_sqlalchemy_model(rule_db)

    def get_l7policy_rules(self, context, l7policy_id, filters=None):
        if filters:
            filters.update(filters)
        else:
            filters = {'l7policy_id': [l7policy_id]}
        rule_dbs = self._get_resources(context, models.L7Rule,
                                       filters=filters)
        return [data_models.L7Rule.from_sqlalchemy_model(rule_db)
                for rule_db in rule_dbs]


def _prevent_lbaasv2_port_delete_callback(resource, event, trigger, **kwargs):
    context = kwargs['context']
    port_id = kwargs['port_id']
    port_check = kwargs['port_check']
    lbaasv2plugin = manager.NeutronManager.get_service_plugins().get(
                         constants.LOADBALANCERV2)
    if lbaasv2plugin and port_check:
        lbaasv2plugin.db.prevent_lbaasv2_port_deletion(context, port_id)

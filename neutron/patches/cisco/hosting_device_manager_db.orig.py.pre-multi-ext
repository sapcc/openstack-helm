# Copyright 2014 Cisco Systems, Inc.  All rights reserved.
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

import eventlet
import math
import netaddr
import threading

from keystoneclient.auth.identity import v3
from keystoneclient import exceptions as k_exceptions
from keystoneclient import session
from keystoneclient.v2_0 import client as k_client
from keystoneclient.v3 import client
from oslo_config import cfg
from oslo_log import log as logging
from oslo_utils import excutils
from oslo_utils import importutils
from oslo_utils import timeutils
from oslo_utils import uuidutils

from sqlalchemy import func
from sqlalchemy.orm import exc
from sqlalchemy.orm import joinedload
from sqlalchemy.sql import expression as expr

from networking_cisco._i18n import _, _LE, _LI, _LW

from neutron.common import exceptions as n_exc
from neutron.common import utils
from neutron import context as neutron_context
from neutron import manager
from neutron.plugins.common import constants as svc_constants

from networking_cisco.plugins.cisco.common import (cisco_constants as
                                                   c_constants)
from networking_cisco.plugins.cisco.db.device_manager import hd_models
from networking_cisco.plugins.cisco.db.device_manager import hosting_devices_db
from networking_cisco.plugins.cisco.device_manager import config
from networking_cisco.plugins.cisco.device_manager import service_vm_lib
from networking_cisco.plugins.cisco.extensions import ciscohostingdevicemanager

LOG = logging.getLogger(__name__)


HOSTING_DEVICE_MANAGER_OPTS = [
    cfg.StrOpt('l3_admin_tenant', default='L3AdminTenant',
               help=_("Name of the L3 admin tenant")),
    cfg.StrOpt('management_network', default='osn_mgmt_nw',
               help=_("Name of management network for CSR VM configuration. "
                      "Default value is osn_mgmt_nw")),
    cfg.StrOpt('default_security_group', default='mgmt_sec_grp',
               help=_("Default security group applied on management port. "
                      "Default value is mgmt_sec_grp")),
    cfg.BoolOpt('ensure_nova_running', default=True,
                help=_("Ensure that Nova is running before attempting to "
                       "create any CSR1kv VM.")),
    cfg.StrOpt('domain_name_server_1', default='8.8.8.8',
               help=_("IP address of primary domain name server for hosting "
                      "devices")),
    cfg.StrOpt('domain_name_server_2', default='8.8.4.4',
               help=_("IP address of secondary domain name server for hosting "
                      "devices"))
]

cfg.CONF.register_opts(HOSTING_DEVICE_MANAGER_OPTS, "general")


VM_CATEGORY = ciscohostingdevicemanager.VM_CATEGORY


class HostingDeviceManagerMixin(hosting_devices_db.HostingDeviceDBMixin):
    """A class implementing a resource manager for hosting devices.

    The caller should make sure that HostingDeviceManagerMixin is a singleton.
    """

    # The all-mighty tenant owning all hosting devices
    _l3_tenant_uuid = None

    # Keystone session corresponding to admin user and l3_admin_tenant
    _keystone_session = None

    # The management network for hosting devices
    _mgmt_nw_uuid = None
    _mgmt_subnet_uuid = None
    _mgmt_sec_grp_id = None

    # Dictionary with credentials keyed on credential UUID
    _credentials = {}

    # Dictionaries with loaded driver modules for different host types
    _plugging_drivers = {}
    _hosting_device_drivers = {}

    # Dictionary with locks for hosting device pool maintenance
    _hosting_device_locks = {}

    # Service VM manager object that interacts with Nova
    _svc_vm_mgr_obj = None

    # Flag indicating is needed Nova services are reported as up.
    _nova_running = False

    @classmethod
    def _keystone_auth_session(cls):
        if cls._keystone_session:
            return cls._keystone_session
        else:
            auth_url = cfg.CONF.keystone_authtoken.auth_url + "/v3"
            # user = cfg.CONF.keystone_authtoken.admin_user
            # pw = cfg.CONF.keystone_authtoken.admin_password
            # project_name = cfg.CONF.keystone_authtoken.admin_tenant_name
            # project_name = cfg.CONF.keystone_authtoken.project_name
            user = cfg.CONF.keystone_authtoken.username
            pw = cfg.CONF.keystone_authtoken.password
            project_name = cfg.CONF.general.l3_admin_tenant
            user_domain_id = (cfg.CONF.keystone_authtoken.user_domain_id or
                              'default')
            project_domain_id = (cfg.CONF.keystone_authtoken.project_domain_id
                                 or 'default')
            auth = v3.Password(auth_url=auth_url,
                               username=user,
                               password=pw,
                               project_name=project_name,
                               user_domain_id=user_domain_id,
                               project_domain_id=project_domain_id)
            cls._keystone_session = session.Session(auth=auth)
        return cls._keystone_session

    @property
    def svc_vm_mgr(self):
        if self._svc_vm_mgr_obj is None:
            if hasattr(cfg.CONF.keystone_authtoken, 'project_domain_id'):
                self._svc_vm_mgr_obj = service_vm_lib.ServiceVMManager(
                    is_auth_v3=True,
                    keystone_session=self._keystone_auth_session())
            else:
                auth_url = cfg.CONF.keystone_authtoken.identity_uri + "/v2.0"
                u_name = cfg.CONF.keystone_authtoken.admin_user
                pw = cfg.CONF.keystone_authtoken.admin_password
                tenant = cfg.CONF.general.l3_admin_tenant

                self._svc_vm_mgr_obj = service_vm_lib.ServiceVMManager(
                    is_auth_v3=False,
                    user=u_name, passwd=pw, l3_admin_tenant=tenant,
                    auth_url=auth_url)
        return self._svc_vm_mgr_obj

    @classmethod
    def _get_tenant_id_using_keystone_v2(cls):
        auth_url = cfg.CONF.keystone_authtoken.identity_uri + "/v2.0"
        user = cfg.CONF.keystone_authtoken.admin_user
        pw = cfg.CONF.keystone_authtoken.admin_password
        tenant = cfg.CONF.keystone_authtoken.admin_tenant_name
        keystone = k_client.Client(username=user, password=pw,
                                   tenant_name=tenant,
                                   auth_url=auth_url)
        try:
            tenant = keystone.tenants.find(
                name=cfg.CONF.general.l3_admin_tenant)
        except k_exceptions.NotFound:
            LOG.error(_LE('No tenant with a name or ID of %s exists.'),
                      cfg.CONF.general.l3_admin_tenant)
        except k_exceptions.NoUniqueMatch:
            LOG.error(_LE('Multiple tenants matches found for %s'),
                      cfg.CONF.general.l3_admin_tenant)
        return tenant.id

    @classmethod
    def _get_tenant_id_using_keystone_v3(cls):
        keystone = client.Client(session=cls._keystone_auth_session())
        try:
            tenant = keystone.projects.find(
                name=cfg.CONF.general.l3_admin_tenant)
        except k_exceptions.NotFound:
            LOG.error(_LE('No tenant with a name or ID of %s exists.'),
                      cfg.CONF.general.l3_admin_tenant)
        except k_exceptions.NoUniqueMatch:
            LOG.error(_LE('Multiple tenants matches found for %s'),
                      cfg.CONF.general.l3_admin_tenant)
        return tenant.id

    @classmethod
    def l3_tenant_id(cls):
        """Returns id of tenant owning hosting device resources."""
        if cls._l3_tenant_uuid is None:
            if hasattr(cfg.CONF.keystone_authtoken, 'project_domain_id'):
                # TODO(sridar): hack for now to determing if keystone v3
                # API is to be used.
                cls._l3_tenant_uuid = cls._get_tenant_id_using_keystone_v3()
            else:
                cls._l3_tenant_uuid = cls._get_tenant_id_using_keystone_v2()
        return cls._l3_tenant_uuid

    @classmethod
    def mgmt_nw_id(cls):
        """Returns id of the management network."""
        if cls._mgmt_nw_uuid is None:
            tenant_id = cls.l3_tenant_id()
            if not tenant_id:
                return
            net = manager.NeutronManager.get_plugin().get_networks(
                neutron_context.get_admin_context(),
                {'tenant_id': [tenant_id],
                 'name': [cfg.CONF.general.management_network]},
                ['id', 'subnets'])
            if len(net) == 1:
                num_subnets = len(net[0]['subnets'])
                if num_subnets == 0:
                    LOG.error(_LE('The management network has no subnet. '
                                  'Please assign one.'))
                    return
                elif num_subnets > 1:
                    LOG.info(_LI('The management network has %d subnets. The '
                                 'first one will be used.'), num_subnets)
                cls._mgmt_nw_uuid = net[0].get('id')
                cls._mgmt_subnet_uuid = net[0]['subnets'][0]
            elif len(net) > 1:
                # Management network must have a unique name.
                LOG.error(_LE('The management network for does not have '
                              'unique name. Please ensure that it is.'))
            else:
                # Management network has not been created.
                LOG.error(_LE('There is no virtual management network. Please '
                              'create one.'))
        return cls._mgmt_nw_uuid

    @classmethod
    def mgmt_subnet_id(cls):
        if cls._mgmt_subnet_uuid is None:
            cls.mgmt_nw_id()
        return cls._mgmt_subnet_uuid

    @classmethod
    def mgmt_sec_grp_id(cls):
        """Returns id of security group used by the management network."""
        if not utils.is_extension_supported(
                manager.NeutronManager.get_plugin(), "security-group"):
            return
        if cls._mgmt_sec_grp_id is None:
            # Get the id for the _mgmt_security_group_id
            tenant_id = cls.l3_tenant_id()
            res = manager.NeutronManager.get_plugin().get_security_groups(
                neutron_context.get_admin_context(),
                {'tenant_id': [tenant_id],
                 'name': [cfg.CONF.general.default_security_group]},
                ['id'])
            if len(res) == 1:
                sec_grp_id = res[0].get('id', None)
                cls._mgmt_sec_grp_id = sec_grp_id
            elif len(res) > 1:
                # the mgmt sec group must be unique.
                LOG.error(_LE('The security group for the management network '
                              'does not have unique name. Please ensure that '
                              'it is.'))
            else:
                # CSR Mgmt security group is not present.
                LOG.error(_LE('There is no security group for the management '
                              'network. Please create one.'))
        return cls._mgmt_sec_grp_id

    def get_hosting_device_config(self, context, id):
        # ask config agent for the running config of the hosting device
        cfg_notifier = self.agent_notifiers.get(c_constants.AGENT_TYPE_CFG)
        if cfg_notifier:
            return cfg_notifier.get_hosting_device_configuration(context, id)

    def get_hosting_device_driver(self, context, id):
        """Returns device driver for hosting device template with <id>."""
        if id is None:
            return
        try:
            return self._hosting_device_drivers[id]
        except KeyError:
            try:
                template = self._get_hosting_device_template(context, id)
                self._hosting_device_drivers[id] = importutils.import_object(
                    template['device_driver'])
            except (ImportError, TypeError, n_exc.NeutronException):
                LOG.exception(_LE("Error loading hosting device driver for "
                                  "hosting device template %s"), id)
            return self._hosting_device_drivers.get(id)

    def get_hosting_device_plugging_driver(self, context, id):
        """Returns  plugging driver for hosting device template with <id>."""
        if id is None:
            return
        try:
            return self._plugging_drivers[id]
        except KeyError:
            try:
                template = self._get_hosting_device_template(context, id)
                self._plugging_drivers[id] = importutils.import_object(
                    template['plugging_driver'])
            except (ImportError, TypeError, n_exc.NeutronException):
                LOG.exception(_LE("Error loading plugging driver for hosting "
                                  "device template %s"), id)
            return self._plugging_drivers.get(id)

    def report_hosting_device_shortage(self, context, template, requested=0):
        """Used to report shortage of hosting devices based on <template>."""
        self._dispatch_pool_maintenance_job(template)

    def acquire_hosting_device_slots(self, context, hosting_device, resource,
                                     resource_type, resource_service, num,
                                     exclusive=False):
        """Assign <num> slots in <hosting_device> to logical <resource>.

        If exclusive is True the hosting device is bound to the resource's
        tenant. Otherwise it is not bound to any tenant.

        Returns True if allocation was granted, False otherwise.
        """
        bound = hosting_device['tenant_bound']
        if ((bound is not None and bound != resource['tenant_id']) or
            (exclusive and not self._exclusively_used(context, hosting_device,
                                                      resource['tenant_id']))):
            LOG.debug(
                'Rejecting allocation of %(num)d slots in tenant %(bound)s '
                'hosting device %(device)s to logical resource %(r_id)s due '
                'to exclusive use conflict.',
                {'num': num,
                 'bound': 'unbound' if bound is None else bound + ' bound',
                 'device': hosting_device['id'], 'r_id': resource['id']})
            return False
        with context.session.begin(subtransactions=True):
            res_info = {'resource': resource, 'type': resource_type,
                        'service': resource_service}
            slot_info, query = self._get_or_create_slot_allocation(
                context, hosting_device, res_info)
            if slot_info is None:
                LOG.debug('Rejecting allocation of %(num)d slots in hosting '
                          'device %(device)s to logical resource %(r_id)s',
                          {'num': num, 'device': hosting_device['id'],
                           'r_id': resource['id']})
                return False
            new_allocation = num + slot_info.num_allocated
            if hosting_device['template']['slot_capacity'] < new_allocation:
                LOG.debug('Rejecting allocation of %(num)d slots in '
                          'hosting device %(device)s to logical resource '
                          '%(r_id)s due to insufficent slot availability.',
                          {'num': num, 'device': hosting_device['id'],
                           'r_id': resource['id']})
                self._dispatch_pool_maintenance_job(hosting_device['template'])
                return False
            # handle any changes to exclusive usage by tenant
            if exclusive and bound is None:
                self._update_hosting_device_exclusivity(
                    context, hosting_device, resource['tenant_id'])
                bound = resource['tenant_id']
            elif not exclusive and bound is not None:
                self._update_hosting_device_exclusivity(context,
                                                        hosting_device, None)
                bound = None
            slot_info.num_allocated = new_allocation
            context.session.add(slot_info)
        self._dispatch_pool_maintenance_job(hosting_device['template'])
        # report success
        LOG.info(_LI('Allocated %(num)d additional slots in tenant %(bound)s'
                     'bound hosting device %(hd_id)s. In total %(total)d '
                     'slots are now allocated in that hosting device for '
                     'logical resource %(r_id)s.'),
                 {'num': num, 'bound': 'un-' if bound is None else bound + ' ',
                  'total': new_allocation, 'hd_id': hosting_device['id'],
                  'r_id': resource['id']})
        return True

    def release_hosting_device_slots(self, context, hosting_device, resource,
                                     num):
        """Free <num> slots in <hosting_device> from logical resource <id>.

        Returns True if deallocation was successful. False otherwise.
        """
        with context.session.begin(subtransactions=True):
            num_str = str(num) if num >= 0 else "all"
            res_info = {'resource': resource}
            slot_info, query = self._get_or_create_slot_allocation(
                context, hosting_device, res_info, create=False)
            if slot_info is None:
                LOG.debug('Rejecting de-allocation of %(num)s slots in '
                          'hosting device %(device)s for logical resource '
                          '%(id)s', {'num': num_str,
                                     'device': hosting_device['id'],
                                     'id': resource['id']})
                return False
            if num >= 0:
                new_allocation = slot_info.num_allocated - num
            else:
                # if a negative num is specified all slot allocations for
                # the logical resource in the hosting device is removed
                new_allocation = 0
            if new_allocation < 0:
                LOG.debug('Rejecting de-allocation of %(num)s slots in '
                          'hosting device %(device)s for logical resource '
                          '%(id)s since only %(alloc)d slots are allocated.',
                          {'num': num_str, 'device': hosting_device['id'],
                           'id': resource['id'],
                           'alloc': slot_info.num_allocated})
                self._dispatch_pool_maintenance_job(hosting_device['template'])
                return False
            elif new_allocation == 0:
                result = query.delete()
                LOG.info(_LI('De-allocated %(num)s slots from hosting device '
                             '%(hd_id)s. %(total)d slots are now allocated in '
                             'that hosting device.'),
                         {'num': num_str, 'total': new_allocation,
                          'hd_id': hosting_device['id']})
                if (hosting_device['tenant_bound'] is not None and
                    context.session.query(hd_models.SlotAllocation).filter_by(
                        hosting_device_id=hosting_device['id']).first() is
                        None):
                    # make hosting device tenant unbound if no logical
                    # resource use it anymore
                    hosting_device['tenant_bound'] = None
                    context.session.add(hosting_device)
                    LOG.info(_LI('Making hosting device %(hd_id)s with no '
                                 'allocated slots tenant unbound.'),
                             {'hd_id': hosting_device['id']})
                self._dispatch_pool_maintenance_job(hosting_device['template'])
                return result == 1
            LOG.info(_LI('De-allocated %(num)s slots from hosting device '
                         '%(hd_id)s. %(total)d slots are now allocated in '
                         'that hosting device.'),
                     {'num': num_str, 'total': new_allocation,
                      'hd_id': hosting_device['id']})
            slot_info.num_allocated = new_allocation
            context.session.add(slot_info)
        self._dispatch_pool_maintenance_job(hosting_device['template'])
        # report success
        return True

    def _get_or_create_slot_allocation(self, context, hosting_device,
                                       resource_info, create=True):
        resource = resource_info['resource']
        slot_info = None
        query = context.session.query(hd_models.SlotAllocation).filter_by(
            logical_resource_id=resource['id'],
            hosting_device_id=hosting_device['id'])
        with context.session.begin(subtransactions=True):
            try:
                slot_info = query.one()
            except exc.MultipleResultsFound:
                # this should not happen
                LOG.debug('DB inconsistency: Multiple slot allocation entries '
                          'for logical resource %(r_id)s in hosting device '
                          '%(device)s.', {'r_id': resource['id'],
                                          'device': hosting_device['id']})
            except exc.NoResultFound:
                LOG.debug('Logical resource %(res)s does not have allocated '
                          'any slots in hosting device %(dev)s.',
                          {'res': resource['id'], 'dev': hosting_device['id']})
                if create is True:
                    LOG.debug('Creating new slot allocation DB entry for '
                              'logical resource %(res)s in hosting device '
                              '%(dev)s.', {'res': resource['id'],
                                           'dev': hosting_device['id']})
                    slot_info = hd_models.SlotAllocation(
                        template_id=hosting_device['template_id'],
                        hosting_device_id=hosting_device['id'],
                        logical_resource_type=resource_info['type'],
                        logical_resource_service=resource_info['service'],
                        logical_resource_id=resource['id'],
                        logical_resource_owner=resource['tenant_id'],
                        num_allocated=0,
                        tenant_bound=None)
        return slot_info, query

    def get_slot_allocation(self, context, template_id=None,
                            hosting_device_id=None, resource_id=None):
        query = context.session.query(func.sum(
            hd_models.SlotAllocation.num_allocated))
        if template_id is not None:
            query = query.filter_by(template_id=template_id)
        if hosting_device_id is not None:
            query = query.filter_by(hosting_device_id=hosting_device_id)
        if resource_id is not None:
            query = query.filter_by(logical_resource_id=resource_id)
        return query.scalar() or 0

    def get_hosting_devices_qry(self, context, hosting_device_ids,
                                load_agent=True):
        """Returns hosting devices with <hosting_device_ids>."""
        query = context.session.query(hd_models.HostingDevice)
        if load_agent:
            query = query.options(joinedload('cfg_agent'))
        if len(hosting_device_ids) > 1:
            query = query.filter(hd_models.HostingDevice.id.in_(
                hosting_device_ids))
        else:
            query = query.filter(hd_models.HostingDevice.id ==
                                 hosting_device_ids[0])
        return query

    def delete_all_hosting_devices(self, context, force_delete=False):
        """Deletes all hosting devices."""
        for item in self._get_collection_query(
                context, hd_models.HostingDeviceTemplate):
            self.delete_all_hosting_devices_by_template(
                context, template=item, force_delete=force_delete)

    def delete_all_hosting_devices_by_template(self, context, template,
                                               force_delete=False):
        """Deletes all hosting devices based on <template>."""
        plugging_drv = self.get_hosting_device_plugging_driver(
            context, template['id'])
        hosting_device_drv = self.get_hosting_device_driver(context,
                                                            template['id'])
        if plugging_drv is None or hosting_device_drv is None:
            return
        is_vm = template['host_category'] == VM_CATEGORY
        query = context.session.query(hd_models.HostingDevice)
        query = query.filter(hd_models.HostingDevice.template_id ==
                             template['id'])
        for hd in query:
            if not (hd.auto_delete or force_delete):
                # device manager is not responsible for life cycle
                # management of this hosting device.
                continue
            res = plugging_drv.get_hosting_device_resources(
                context, hd.id, hd.complementary_id, self.l3_tenant_id(),
                self.mgmt_nw_id())
            if is_vm:
                self.svc_vm_mgr.delete_service_vm(context, hd.id)
            plugging_drv.delete_hosting_device_resources(
                context, self.l3_tenant_id(), **res)
            with context.session.begin(subtransactions=True):
                # remove all allocations in this hosting device
                context.session.query(hd_models.SlotAllocation).filter_by(
                    hosting_device_id=hd['id']).delete()
                context.session.delete(hd)

    def handle_non_responding_hosting_devices(self, context, cfg_agent,
                                              hosting_device_ids):
        e_context = context.elevated()
        hosting_devices = self.get_hosting_devices_qry(
            e_context, hosting_device_ids).all()
        # 'hosting_info' is dictionary with ids of removed hosting
        # devices and the affected logical resources for each
        # removed hosting device:
        #    {'hd_id1': {'routers': [id1, id2, ...],
        #                'fw': [id1, ...],
        #                 ...},
        #     'hd_id2': {'routers': [id3, id4, ...]},
        #                'fw': [id1, ...],
        #                ...},
        #     ...}
        hosting_info = dict((id, {}) for id in hosting_device_ids)
        #TODO(bobmel): Modify so service plugins register themselves
        try:
            l3plugin = manager.NeutronManager.get_service_plugins().get(
                svc_constants.L3_ROUTER_NAT)
            l3plugin.handle_non_responding_hosting_devices(
                context, hosting_devices, hosting_info)
        except AttributeError:
            pass
        notifier = self.agent_notifiers.get(c_constants.AGENT_TYPE_CFG)
        for hd in hosting_devices:
            if (self._process_non_responsive_hosting_device(e_context, hd) and
                    notifier):
                notifier.hosting_devices_removed(context, hosting_info, False,
                                                 cfg_agent)

    def get_device_info_for_agent(self, context, hosting_device_db):
        """Returns information about <hosting_device> needed by config agent.

           Convenience function that service plugins can use to populate
           their resources with information about the device hosting their
           logical resource.
        """
        template = hosting_device_db.template
        mgmt_port = hosting_device_db.management_port
        mgmt_ip = (mgmt_port['fixed_ips'][0]['ip_address']
                   if mgmt_port else hosting_device_db.management_ip_address)
        return {'id': hosting_device_db.id,
                'name': template.name,
                'template_id': template.id,
                'credentials': self._get_credentials(hosting_device_db),
                'host_category': template.host_category,
                'admin_state_up': hosting_device_db.admin_state_up,
                'service_types': template.service_types,
                'management_ip_address': mgmt_ip,
                'protocol_port': hosting_device_db.protocol_port,
                'timeout': None,
                'created_at': str(hosting_device_db.created_at),
                'status': hosting_device_db.status,
                'booting_time': template.booting_time}

    def _process_non_responsive_hosting_device(self, context, hosting_device):
        """Host type specific processing of non responsive hosting devices.

        :param hosting_device: db object for hosting device
        :return: True if hosting_device has been deleted, otherwise False
        """
        if (hosting_device['template']['host_category'] == VM_CATEGORY and
                hosting_device['auto_delete']):
            self._delete_dead_service_vm_hosting_device(context,
                                                        hosting_device)
            return True
        return False

    def _setup_device_manager(self):
        self._obtain_hosting_device_credentials_from_config()
        self._create_hosting_device_templates_from_config()
        self._create_hosting_devices_from_config()
        self._gt_pool = eventlet.GreenPool()
        # initialize hosting device pools
        adm_ctx = neutron_context.get_admin_context()
        for template in adm_ctx.session.query(hd_models.HostingDeviceTemplate):
            self._dispatch_pool_maintenance_job(template)

    def _dispatch_pool_maintenance_job(self, template):
        # Note(bobmel): Nova does not handle VM dispatching well before all
        # its services have started. This creates problems for the Neutron
        # devstack script that creates a Neutron router, which in turn
        # triggers service VM dispatching.
        # Only perform pool maintenance if needed Nova services have started

        # For now the pool size is only elastic for service VMs.
        if template['host_category'] != VM_CATEGORY:
            return
        if cfg.CONF.general.ensure_nova_running and not self._nova_running:
            if self.svc_vm_mgr.nova_services_up():
                self._nova_running = True
            else:
                LOG.info(_LI('Not all Nova services are up and running. '
                             'Skipping this service vm pool management '
                             'request.'))
                return
        adm_context = neutron_context.get_admin_context()
        adm_context.tenant_id = self.l3_tenant_id()
        self._gt_pool.spawn_n(self._maintain_hosting_device_pool, adm_context,
                              template)

    def _maintain_hosting_device_pool(self, context, template):
        """Maintains the pool of hosting devices that are based on <template>.

        Ensures that the number of standby hosting devices (essentially
        service VMs) is kept at a suitable level so that resource creation is
        not slowed down by booting of the hosting device.

        :param context: context for this operation
        :param template: db object for hosting device template
        """
        #TODO(bobmel): Support HA/load-balanced Neutron servers:
        #TODO(bobmel): Locking across multiple running Neutron server instances
        lock = self._get_template_pool_lock(template['id'])
        acquired = lock.acquire(False)
        if not acquired:
            # pool maintenance for this template already ongoing, so abort
            return
        try:
            # Maintain a pool of approximately 'desired_slots_free' available
            # for allocation. Approximately means that
            # abs(desired_slots_free-capacity) <= available_slots <=
            #                                       desired_slots_free+capacity
            capacity = template['slot_capacity']
            if capacity == 0:
                return
            desired = template['desired_slots_free']
            available = self._get_total_available_slots(
                context, template['id'], capacity)
            grow_threshold = abs(desired - capacity)
            if available <= grow_threshold:
                num_req = int(math.ceil(grow_threshold / (1.0 * capacity)))
                num_created = len(self._create_svc_vm_hosting_devices(
                    context, num_req, template))
                if num_created < num_req:
                    LOG.warning(_LW('Requested %(requested)d instances based '
                                    'on hosting device template %(template)s '
                                    'but could only create %(created)d '
                                    'instances'),
                                {'requested': num_req,
                                 'template': template['id'],
                                 'created': num_created})
            elif available >= desired + capacity:
                num_req = int(
                    math.floor((available - desired) / (1.0 * capacity)))
                num_deleted = self._delete_idle_service_vm_hosting_devices(
                    context, num_req, template)
                if num_deleted < num_req:
                    LOG.warning(_LW('Tried to delete %(requested)d instances '
                                    'based on hosting device template '
                                    '%(template)s but could only delete '
                                    '%(deleted)d instances'),
                             {'requested': num_req, 'template': template['id'],
                              'deleted': num_deleted})
        finally:
            lock.release()

    def _create_svc_vm_hosting_devices(self, context, num, template):
        """Creates <num> or less service VM instances based on <template>.

        These hosting devices can be bound to a certain tenant or for shared
        use. A list with the created hosting device VMs is returned.
        """
        hosting_devices = []
        template_id = template['id']
        credentials_id = template['default_credentials_id']
        plugging_drv = self.get_hosting_device_plugging_driver(context,
                                                               template_id)
        hosting_device_drv = self.get_hosting_device_driver(context,
                                                            template_id)
        if plugging_drv is None or hosting_device_drv is None or num <= 0:
            return hosting_devices
        #TODO(bobmel): Determine value for max_hosted properly
        max_hosted = 1  # template['slot_capacity']
        dev_data, mgmt_context = self._get_resources_properties_for_hd(
            template, credentials_id)
        credentials_info = self._credentials.get(credentials_id)
        if credentials_info is None:
            LOG.error(_LE('Could not find credentials for hosting device'
                          'template %s. Aborting VM hosting device creation.'),
                      template_id)
            return hosting_devices
        connectivity_info = self._get_mgmt_connectivity_info(
            context, self.mgmt_subnet_id())
        for i in range(num):
            complementary_id = uuidutils.generate_uuid()
            res = plugging_drv.create_hosting_device_resources(
                context, complementary_id, self.l3_tenant_id(), mgmt_context,
                max_hosted)
            if res.get('mgmt_port') is None:
                # Required ports could not be created
                return hosting_devices
            connectivity_info['mgmt_port'] = res['mgmt_port']
            vm_instance = self.svc_vm_mgr.dispatch_service_vm(
                context, template['name'] + '_nrouter', template['image'],
                template['flavor'], hosting_device_drv, credentials_info,
                connectivity_info, res.get('ports'))
            if vm_instance is not None:
                dev_data.update(
                    {'id': vm_instance['id'],
                     'complementary_id': complementary_id,
                     'management_ip_address': res['mgmt_port'][
                         'fixed_ips'][0]['ip_address'],
                     'management_port_id': res['mgmt_port']['id']})
                self.create_hosting_device(context,
                                           {'hosting_device': dev_data})
                hosting_devices.append(vm_instance)
            else:
                # Fundamental error like could not contact Nova
                # Cleanup anything we created
                plugging_drv.delete_hosting_device_resources(
                    context, self.l3_tenant_id(), **res)
                break
        LOG.info(_LI('Created %(num)d hosting device VMs based on template '
                     '%(t_id)s'), {'num': len(hosting_devices),
                                   't_id': template_id})
        return hosting_devices

    def _get_mgmt_connectivity_info(self, context, mgmt_subnet_id):
        subnet_data = self._core_plugin.get_subnet(
            context, mgmt_subnet_id,
            ['cidr', 'gateway_ip', 'dns_nameservers'])
        num = len(subnet_data['dns_nameservers'])
        name_server_1 = cfg.CONF.general.domain_name_server_1
        name_server_2 = cfg.CONF.general.domain_name_server_2
        if num == 1:
            name_server_1 = subnet_data['dns_nameservers'][0]['address']
            name_server_2 = cfg.CONF.general.domain_name_server_2
        elif num >= 2:
            name_server_1 = subnet_data['dns_nameservers'][0]['address']
            name_server_2 = subnet_data['dns_nameservers'][1]['address']
        return {'gateway_ip': subnet_data['gateway_ip'],
                'netmask': str(netaddr.IPNetwork(subnet_data['cidr']).netmask),
                'name_server_1': name_server_1,
                'name_server_2': name_server_2}

    def _get_resources_properties_for_hd(self, template, credentials_id):
        # These resources are owned by the L3AdminTenant
        dev_data = {'template_id': template['id'],
                    'tenant_id': template['tenant_id'],
                    'credentials_id': credentials_id,
                    'admin_state_up': True,
                    'protocol_port': template['protocol_port'],
                    'created_at': timeutils.utcnow(),
                    'tenant_bound': template['tenant_bound'] or None,
                    'auto_delete': True}
        mgmt_context = {
            'mgmt_ip_address': None,
            'mgmt_nw_id': self.mgmt_nw_id(),
            'mgmt_sec_grp_id': self.mgmt_sec_grp_id()}
        return dev_data, mgmt_context

    def _delete_idle_service_vm_hosting_devices(self, context, num, template):
        """Deletes <num> or less unused <template>-based service VM instances.

        The number of deleted service vm instances is returned.
        """
        # Delete the "youngest" hosting devices since they are more likely
        # not to have finished booting
        num_deleted = 0
        plugging_drv = self.get_hosting_device_plugging_driver(context,
                                                               template['id'])
        hosting_device_drv = self.get_hosting_device_driver(context,
                                                            template['id'])
        if plugging_drv is None or hosting_device_drv is None or num <= 0:
            return num_deleted
        query = context.session.query(hd_models.HostingDevice)
        query = query.outerjoin(
            hd_models.SlotAllocation,
            hd_models.HostingDevice.id ==
            hd_models.SlotAllocation.hosting_device_id)
        query = query.filter(hd_models.HostingDevice.template_id ==
                             template['id'],
                             hd_models.HostingDevice.admin_state_up ==
                             expr.true(),
                             hd_models.HostingDevice.tenant_bound ==
                             expr.null(),
                             hd_models.HostingDevice.auto_delete ==
                             expr.true())
        query = query.group_by(hd_models.HostingDevice.id).having(
            func.count(hd_models.SlotAllocation.logical_resource_id) == 0)
        query = query.order_by(
            hd_models.HostingDevice.created_at.desc(),
            func.count(hd_models.SlotAllocation.logical_resource_id))
        hd_candidates = query.all()
        num_possible_to_delete = min(len(hd_candidates), num)
        for i in range(num_possible_to_delete):
            res = plugging_drv.get_hosting_device_resources(
                context, hd_candidates[i]['id'],
                hd_candidates[i]['complementary_id'], self.l3_tenant_id(),
                self.mgmt_nw_id())
            if self.svc_vm_mgr.delete_service_vm(context,
                                                 hd_candidates[i]['id']):
                with context.session.begin(subtransactions=True):
                    context.session.delete(hd_candidates[i])
                plugging_drv.delete_hosting_device_resources(
                    context, self.l3_tenant_id(), **res)
                num_deleted += 1
        LOG.info(_LI('Deleted %(num)d hosting devices based on template '
                     '%(t_id)s'), {'num': num_deleted, 't_id': template['id']})
        return num_deleted

    def _delete_dead_service_vm_hosting_device(self, context, hosting_device):
        """Deletes a presumably dead <hosting_device> service VM.

        This will indirectly make all of its hosted resources unscheduled.
        """
        if hosting_device is None:
            return
        plugging_drv = self.get_hosting_device_plugging_driver(
            context, hosting_device['template_id'])
        hosting_device_drv = self.get_hosting_device_driver(
            context, hosting_device['template_id'])
        if plugging_drv is None or hosting_device_drv is None:
            return
        res = plugging_drv.get_hosting_device_resources(
            context, hosting_device['id'], hosting_device['complementary_id'],
            self.l3_tenant_id(), self.mgmt_nw_id())
        if not self.svc_vm_mgr.delete_service_vm(context,
                                                 hosting_device['id']):
            LOG.error(_LE('Failed to delete hosting device %s service VM. '
                          'Will un-register it anyway.'),
                      hosting_device['id'])
        plugging_drv.delete_hosting_device_resources(
            context, self.l3_tenant_id(), **res)
        with context.session.begin(subtransactions=True):
            # remove all allocations in this hosting device
            context.session.query(hd_models.SlotAllocation).filter_by(
                hosting_device_id=hosting_device['id']).delete()
            context.session.delete(hosting_device)

    def _get_total_available_slots(self, context, template_id, capacity):
        """Returns available slots in idle devices based on <template_id>.

        Only slots in tenant unbound hosting devices are counted to ensure
        there is always hosting device slots available regardless of tenant.
        """
        query = context.session.query(hd_models.HostingDevice.id)
        query = query.outerjoin(
            hd_models.SlotAllocation,
            hd_models.HostingDevice.id == hd_models.SlotAllocation
            .hosting_device_id)
        query = query.filter(
            hd_models.HostingDevice.template_id == template_id,
            hd_models.HostingDevice.admin_state_up == expr.true(),
            hd_models.HostingDevice.tenant_bound == expr.null())
        query = query.group_by(hd_models.HostingDevice.id)
        query = query.having(
            func.sum(hd_models.SlotAllocation.num_allocated) == expr.null())
        num_hosting_devices = query.count()
        return num_hosting_devices * capacity

    def _exclusively_used(self, context, hosting_device, tenant_id):
        """Checks if only <tenant_id>'s resources use <hosting_device>."""
        return (context.session.query(hd_models.SlotAllocation).filter(
            hd_models.SlotAllocation.hosting_device_id == hosting_device['id'],
            hd_models.SlotAllocation.logical_resource_owner != tenant_id).
            first() is None)

    def _update_hosting_device_exclusivity(self, context, hosting_device,
                                           tenant_id):
        """Make <hosting device> bound or unbound to <tenant_id>.

        If <tenant_id> is None the device is unbound, otherwise it gets bound
        to that <tenant_id>
        """
        with context.session.begin(subtransactions=True):
            hosting_device['tenant_bound'] = tenant_id
            context.session.add(hosting_device)
            for item in (context.session.query(hd_models.SlotAllocation).
                         filter_by(hosting_device_id=hosting_device['id'])):
                item['tenant_bound'] = tenant_id
                context.session.add(item)

    def _get_template_pool_lock(self, id):
        """Returns lock object for hosting device template with <id>."""
        try:
            return self._hosting_device_locks[id]
        except KeyError:
            self._hosting_device_locks[id] = threading.Lock()
            return self._hosting_device_locks.get(id)

    def _obtain_hosting_device_credentials_from_config(self):
        """Obtains credentials from config file and stores them in memory.
        To be called before hosting device templates defined in the config file
        are created.
        """
        cred_dict = config.get_specific_config(
            'cisco_hosting_device_credential')
        attr_info = {
            'name': {'allow_post': True, 'allow_put': True,
                     'validate': {'type:string': None}, 'is_visible': True,
                     'default': ''},
            'description': {'allow_post': True, 'allow_put': True,
                            'validate': {'type:string': None},
                            'is_visible': True, 'default': ''},
            'user_name': {'allow_post': True, 'allow_put': True,
                          'validate': {'type:string': None},
                          'is_visible': True, 'default': ''},
            'password': {'allow_post': True, 'allow_put': True,
                         'validate': {'type:string': None},
                         'is_visible': True, 'default': ''},
            'type': {'allow_post': True, 'allow_put': True,
                     'validate': {'type:string': None}, 'is_visible': True,
                     'default': ''}}
        self._credentials = {}
        for cred_uuid, kv_dict in cred_dict.items():
            # ensure cred_uuid is properly formatted
            cred_uuid = config.uuidify(cred_uuid)
            config.verify_resource_dict(kv_dict, True, attr_info)
            self._credentials[cred_uuid] = kv_dict

    def _get_credentials(self, hosting_device):
        creds = self._credentials.get(
            hosting_device.credentials_id,
            self._credentials.get(
                hosting_device.template.default_credentials_id))
        return {'user_name': creds['user_name'],
                'password': creds['password']} if creds else None

    def _create_hosting_device_templates_from_config(self):
        """To be called late during plugin initialization so that any hosting
        device templates defined in the config file is properly inserted in
        the DB.
        """
        hdt_dict = config.get_specific_config('cisco_hosting_device_template')
        attr_info = ciscohostingdevicemanager.RESOURCE_ATTRIBUTE_MAP[
            ciscohostingdevicemanager.DEVICE_TEMPLATES]
        adm_context = neutron_context.get_admin_context()

        for hdt_uuid, kv_dict in hdt_dict.items():
            # ensure hdt_uuid is properly formatted
            hdt_uuid = config.uuidify(hdt_uuid)
            try:
                self.get_hosting_device_template(adm_context, hdt_uuid)
                is_create = False
            except ciscohostingdevicemanager.HostingDeviceTemplateNotFound:
                is_create = True
            kv_dict['id'] = hdt_uuid
            kv_dict['tenant_id'] = self.l3_tenant_id()
            config.verify_resource_dict(kv_dict, True, attr_info)
            hdt = {ciscohostingdevicemanager.DEVICE_TEMPLATE: kv_dict}
            try:
                if is_create:
                    self.create_hosting_device_template(adm_context, hdt)
                else:
                    self.update_hosting_device_template(adm_context,
                                                        kv_dict['id'], hdt)
            except n_exc.NeutronException:
                with excutils.save_and_reraise_exception():
                    LOG.error(_LE('Invalid hosting device template definition '
                                  'in configuration file for template = %s'),
                              hdt_uuid)

    def _create_hosting_devices_from_config(self):
        """To be called late during plugin initialization so that any hosting
        device specified in the config file is properly inserted in the DB.
        """
        hd_dict = config.get_specific_config('cisco_hosting_device')
        attr_info = ciscohostingdevicemanager.RESOURCE_ATTRIBUTE_MAP[
            ciscohostingdevicemanager.DEVICES]
        adm_context = neutron_context.get_admin_context()

        for hd_uuid, kv_dict in hd_dict.items():
            # ensure hd_uuid is properly formatted
            hd_uuid = config.uuidify(hd_uuid)
            try:
                old_hd = self.get_hosting_device(adm_context, hd_uuid)
                is_create = False
            except ciscohostingdevicemanager.HostingDeviceNotFound:
                old_hd = {}
                is_create = True
            kv_dict['id'] = hd_uuid
            kv_dict['tenant_id'] = self.l3_tenant_id()
            # make sure we keep using same config agent if it has been assigned
            kv_dict['cfg_agent_id'] = old_hd.get('cfg_agent_id')
            # make sure we keep using management port if it exists
            kv_dict['management_port_id'] = old_hd.get('management_port_id')
            config.verify_resource_dict(kv_dict, True, attr_info)
            hd = {ciscohostingdevicemanager.DEVICE: kv_dict}
            try:
                if is_create:
                    self.create_hosting_device(adm_context, hd)
                else:
                    self.update_hosting_device(adm_context, kv_dict['id'], hd)
            except n_exc.NeutronException:
                with excutils.save_and_reraise_exception():
                    LOG.error(_LE('Invalid hosting device specification in '
                                  'configuration file for device = %s'),
                              hd_uuid)
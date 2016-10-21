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

from oslo_log import log as logging
from oslo_utils import excutils

from networking_cisco._i18n import _LE

from neutron.common import constants as l3_constants
from neutron.extensions import providernet as pr_net
from neutron import manager

from networking_cisco.plugins.cisco.device_manager import config
import networking_cisco.plugins.cisco.device_manager.plugging_drivers as plug

LOG = logging.getLogger(__name__)

DEVICE_OWNER_ROUTER_GW = l3_constants.DEVICE_OWNER_ROUTER_GW


class HwVLANTrunkingPlugDriver(plug.PluginSidePluggingDriver):
    """Driver class for Cisco hardware-based devices.

    The driver works with VLAN segmented Neutron networks.
    """
    # once initialized _device_network_interface_map is dictionary
    _device_network_interface_map = None

    @property
    def _core_plugin(self):
        try:
            return self._plugin
        except AttributeError:
            self._plugin = manager.NeutronManager.get_plugin()
            return self._plugin

    def create_hosting_device_resources(self, context, complementary_id,
                                        tenant_id, mgmt_context, max_hosted):
        return {'mgmt_port': None}

    def get_hosting_device_resources(self, context, id, complementary_id,
                                     tenant_id, mgmt_nw_id):
        return {'mgmt_port': None,
                'ports': [], 'networks': [], 'subnets': []}

    def delete_hosting_device_resources(self, context, tenant_id, mgmt_port,
                                        **kwargs):
        pass

    def setup_logical_port_connectivity(self, context, port_db,
                                        hosting_device_id):
        pass

    def teardown_logical_port_connectivity(self, context, port_db,
                                           hosting_device_id):
        pass

    def extend_hosting_port_info(self, context, port_db, hosting_device,
                                 hosting_info):
        hosting_info['segmentation_id'] = port_db.hosting_info.segmentation_id
        is_external = (port_db.device_owner == DEVICE_OWNER_ROUTER_GW)
        hosting_info['physical_interface'] = self._get_interface_info(
            hosting_device['id'], port_db.network_id, is_external)

    def allocate_hosting_port(self, context, router_id, port_db, network_type,
                              hosting_device_id):
        # For VLAN core plugin provides VLAN tag
        tags = self._core_plugin.get_networks(
            context, {'id': [port_db['network_id']]}, [pr_net.SEGMENTATION_ID])
        allocated_vlan = (None if tags == []
                          else tags[0].get(pr_net.SEGMENTATION_ID))
        if allocated_vlan is None:
            # Database must have been messed up if this happens ...
            LOG.debug('hw_vlan_trunking_driver: Could not allocate VLAN')
            return
        return {'allocated_port_id': port_db.id,
                'allocated_vlan': allocated_vlan}

    @classmethod
    def _get_interface_info(cls, device_id, network_id, external=False):
        if cls._device_network_interface_map is None:
            cls._get_network_interface_map_from_config()
        try:
            dev_info = cls._device_network_interface_map[device_id]
            if external:
                return dev_info['external'].get(network_id,
                                                dev_info['external']['*'])
            else:
                return dev_info['internal'].get(network_id,
                                                dev_info['internal']['*'])
        except (TypeError, KeyError):
            LOG.error(_LE('Failed to lookup interface on device %(dev)s'
                          'for network %(net)s'), {'dev': device_id,
                                                   'net': network_id})
            return

    @classmethod
    def _get_network_interface_map_from_config(cls):
        dni_dict = config.get_specific_config(
            'HwVLANTrunkingPlugDriver'.lower())
        temp = {}
        for hd_uuid, kv_dict in dni_dict.items():
            # ensure hd_uuid is properly formatted
            hd_uuid = config.uuidify(hd_uuid)
            if hd_uuid not in temp:
                temp[hd_uuid] = {'internal': {}, 'external': {}}
            for k, v in kv_dict.items():
                try:
                    entry = k[:k.index('_')]
                    net_spec, interface = v.split(':')
                    for net_id in net_spec.split(','):
                        temp[hd_uuid][entry][net_id] = interface
                except (ValueError, KeyError):
                    with excutils.save_and_reraise_exception() as ctx:
                        ctx.reraise = False
                        LOG.error(_LE('Invalid network to interface mapping '
                                      '%(key)s, %(value)s in configuration '
                                      'file for device = %(dev)s'),
                                  {'key': k, 'value': v, 'dev': hd_uuid})
        cls._device_network_interface_map = temp
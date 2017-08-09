[general]
# Name of the L3 admin tenant
l3_admin_tenant = {{.Values.asr_l3_admin_tenant}}

# Name of management network for hosting device configuration
# management_network = osn_mgmt_nw

# Default security group applied on management port
# default_security_group = mgmt_sec_grp

# Seconds of no status update until a cfg agent is considered down
# cfg_agent_down_time = 60

# Driver to use for scheduling hosting device to a Cisco configuration agent
configuration_agent_scheduler_driver = networking_cisco.plugins.cisco.device_manager.scheduler.hosting_device_cfg_agent_scheduler.HostingDeviceCfgAgentScheduler

# Path to templates for hosting devices
# templates_path = /opt/stack/data/neutron/cisco/templates

# Path to config drive files for service VM instances
# service_vm_config_path = /opt/stack/data/neutron/cisco/config_drive

# Ensure that Nova is running before attempting to create any CSR1kv VM
# ensure_nova_running = True

# IP address of primary domain name server for hosting devices
# domain_name_server_1 = 8.8.8.8

# IP address of secondary domain name server for hosting devices
# domain_name_server_2 = 8.8.4.4

[hosting_device_credentials]
# Cisco hosting device credentials specifications.
# Credentials for hosting devices must be defined here.
# NOTE! All fields must be included (even if left empty).

# Hosting device credential format.
# [cisco_hosting_device_credential:<UUID of hosting device credentail>]  (1)
# name=<name of credentail>                                              (2)
# description=<description of credential>                                (3)
# user_name=<username string>
# password=<password string>
# type=<type of credential>                                              (4)

# (1) The UUID can be specified as an integer.
# (2),(3),(4): currently ignored. Can be left empty.

# Example:
[cisco_hosting_device_credential:1]
name="Universal credential"
description="Credential used for all hosting devices"
user_name={{.Values.asr_credential_1_user_name}}
password={{.Values.asr_credential_1_password}}
type=

[hosting_devices_templates]
# Cisco hosting device template definitions.
# In addition to defining templates using the neutron client,
# templates can be defined here to be immediately available
# when Neutron is started.
# NOTE! All fields must be included (even if left empty).

# Hosting device template format.
# [cisco_hosting_device_template:<UUID of hosting device template>]   (1)
# name=<name given to hosting devices created using this template>
# enabled=<template enabled if True>
# host_category=<can be 'VM', 'Hardware', or 'Network_Node'>          (2)
# service_types=<list of service types this template supports>        (3)
# image=<the image name or UUD in Glance>                             (4)
# flavor=<the VM flavor or UUID in Nova>                              (5)
# default_credentials_id=<UUID of default credentials>                (6)
# configuration_mechanism=<indicates how configurations are made>     (7)
# protocol_port=<udp/tcp port of hosting device>
# booting_time=<Typical booting time (in seconds)>
# slot_capacity=<abstract metric specifying capacity to host logical resources>
# desired_slots_free=<desired number of slots to keep available at all times>
# tenant_bound=<list of tenant UUIDs to which template is available>  (8)
# device_driver=<module to be used as hosting device driver>
# plugging_driver=<module to be used as plugging driver >

# (1) The UUID can be specified as an integer.
# (2) Specify 'VM' for virtual machine appliances, 'Hardware' for hardware
#     appliances, and 'Network_Node' for traditional Neutron network nodes.
# (3) Write as string of ':' separated service type names. Can be left empty
#     for now.
# (4) Leave empty for hardware appliances and network nodes.
# (5) Leave empty for hardware appliances and network nodes.
# (6) UUID of credential. Can be specified as an integer.
# (7) Currently ignored. Can be left empty for now.
# (8) A (possibly empty) string of ':'-separated tenant UUIDs representing the
#     only tenants allowed to own/place resources on hosting devices created
#     using this template. If string is empty all tenants are allowed.

# Example:
[cisco_hosting_device_template:1]
name=NetworkNode
enabled=True
host_category=Network_Node
service_types=router:FW:VPN
image=
flavor=
default_credentials_id={{.Values.asr_hosting_device_template_1_credential}}
configuration_mechanism=
protocol_port=22
booting_time=360
slot_capacity=2000
desired_slots_free=0
tenant_bound=
device_driver=networking_cisco.plugins.cisco.device_manager.hosting_device_drivers.noop_hd_driver.NoopHostingDeviceDriver
plugging_driver=networking_cisco.plugins.cisco.device_manager.plugging_drivers.noop_plugging_driver.NoopPluggingDriver

# [cisco_hosting_device_template:2]
# name="CSR1kv template"
# enabled=True
# host_category=VM
# service_types=router:FW:VPN
# image=csr1kv_openstack_img
# flavor=621
# default_credentials_id=1
# configuration_mechanism=
# protocol_port=22
# booting_time=360
# slot_capacity=2000
# desired_slots_free=0
# tenant_bound=
# device_driver=networking_cisco.plugins.cisco.device_manager.hosting_device_drivers.csr1kv_hd_driver.CSR1kvHostingDeviceDriver
# Use this plugging driver for ML2 N1kv driver with VLAN trunking
# plugging_driver=networking_cisco.plugins.cisco.device_manager.plugging_drivers.n1kv_ml2_trunking_driver.N1kvML2TrunkingPlugDriver
# Use this plugging driver for VIF hot-plug (with plugins like ML2)
# plugging_driver=networking_cisco.plugins.cisco.l3.plugging_drivers.vif_hotplug_plugging_driver.VIFHotPlugPluggingDriver

[cisco_hosting_device_template:3]
name="ASR1kv template"
enabled=True
host_category=Hardware
service_types=router:FW:VPN
image=
flavor=
default_credentials_id={{.Values.asr_hosting_device_template_3_credential}}
configuration_mechanism=
protocol_port=22
booting_time=360
slot_capacity=2000
desired_slots_free=0
tenant_bound=
device_driver=networking_cisco.plugins.cisco.device_manager.hosting_device_drivers.noop_hd_driver.NoopHostingDeviceDriver
plugging_driver=networking_asr.plugins.cisco.device_manager.plugging_drivers.hpb_vlan_trunking_driver.HPBVLANTrunkingPlugDriver
#plugging_driver=networking_cisco.plugins.cisco.device_manager.plugging_drivers.hw_vlan_trunking_driver.HwVLANTrunkingPlugDriver

[hosting_devices]
# Cisco hosting device specifications.
# In addition to specifying hosting devices using the neutron client,
# devices can be specified here to be immediately available when Neutron is
# started.
# NOTE! All fields must be included (even if left empty).

# Hosting device format.
# [cisco_hosting_device:<UUID of hosting device>]                         (1)
# template_id=<UUID of hosting device template for this hosting device>
# credentials_id=<UUID of credentials for this hosting device>
# name=<name of device, e.g., its name in DNS>
# description=<arbitrary description of the device>
# device_id=<manufacturer id of the device, e.g., its serial number>
# admin_state_up=<True if device is active, False otherwise>
# management_ip_address=<IP address of device's management network interface>
# protocol_port=<udp/tcp port of hosting device's management process>
# tenant_bound=<Tenant UUID or empty string>                              (2)
# auto_delete=<True or False>                                             (3)

# (1) The UUID can be specified as an integer.
# (2) UUID of the only tenant allowed to own/place resources on this hosting
#     device. If empty any tenant can place resources on it.
# (3) If True, a VM-based hosting device is subject to deletion as part of
#     hosting device pool management and in case of VM failures. If set to
#     False, the hosting device must be manually unregistered in the device
#     manager and any corresponding VM must be deleted in Nova.


{{ range $i, $hosting_device := .Values.asr_hosting_devices}}
[cisco_hosting_device:{{$hosting_device.id}}]
template_id=3
credentials_id={{$hosting_device.credential}}
name={{$hosting_device.name}}
description=Hosting device {{$hosting_device.name}}
device_id={{$hosting_device.sn}}
admin_state_up=True
management_ip_address={{$hosting_device.ip}}
protocol_port=22
tenant_bound=
auto_delete=True


{{ end }}

[plugging_drivers]
# Cisco plugging driver configurations.
# Plugging driver specific settings are made here.

# For the hw_vlan_trunking_driver.HwVLANTrunkingPlugDriver plugging driver
# it is expected that for each hosting device the network interfaces to be used
# to reach different Neutron networks are specified.

# Specifically the format for this plugging driver is as follows
# [HwVLANTrunkingPlugDriver:<UUID of hosting device>]                      (1)
# internal_net_interface_<int number>=<network_uuid_spec>:<interface_name> (2)
# external_net_interface_<int number>=<network_uuid_spec>:<interface_name> (3)
# [zero or more additional internal or external specifications] ...

# (1) The UUID can be specified as an integer.
# (2),(3) <network_uuid_spec> can be '*' or a UUID, or a comma separated list
#         of UUIDs.


{{range $i, $hosting_device := .Values.asr_hosting_devices}}

[HwVLANTrunkingPlugDriver:{{$hosting_device.id}}]
internal_net_interface_1={{$hosting_device.intf_internal}}
external_net_interface_1={{$hosting_device.intf_external}}
{{ end }}

# [HwVLANTrunkingPlugDriver:4]
# internal_net_interface_1=*:GigabitEthernet1
# external_net_interface_1=d7b2eac2-1ade-444e-edc5-81fd4267f53a:GigabitEthernet2
# external_net_interface_2=a36b533a-fae6-b78c-fe11-34aa82b12e3a,45c624b-ebf5-c67b-df22-43bb73c21f4e:GigabitEthernet3

[csr1kv_hosting_devices]
# Settings for CSR1kv hosting devices
# -----------------------------------
# CSR1kv default template file name
# configdrive_template = csr1kv_cfg_template

[n1kv]
# Settings coupled to N1kv plugin
# -------------------------------
# Name of N1kv port profile for management ports
# management_port_profile = osn_mgmt_pp

# Name of N1kv port profile for T1 ports
# t1_port_profile = osn_t1_pp

# Name of N1kv port profile for T2 ports
# t2_port_profile = osn_t2_pp

# Name of N1kv network profile for T1 networks
# t1_network_profile = osn_t1_np

# Name of N1kv network profile for T2 networks
# t2_network_profile = osn_t2_np

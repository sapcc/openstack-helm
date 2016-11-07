[routing]
# Name of default router type to create. Must be a unique name.
default_router_type = Hardware_Neutron_router

# Name of router type for Linux network namespace-based routers
namespace_router_type_name = Namespace_Neutron_router

# Time in seconds between renewed scheduling attempts of non-scheduled routers
# backlog_processing_interval = 10

# Driver to use for routertype-aware scheduling of router to a default L3 agent
# router_type_aware_scheduler_driver = networking_cisco.plugins.cisco.l3.schedulers.l3_routertype_aware_agent_scheduler.L3RouterTypeAwareScheduler

# Set 'auto_schedule' to True if routers are to be automatically scheduled by default
# auto_schedule = True

# Set 'share_hosting_device' to True if routers can share hosts with routers owned by other tenants by default
# share_hosting_device = True


[router_types]
# Cisco router type definitions.
# In addition to defining router types using the neutron client,
# router types can be defined here to be immediately available
# when Neutron is started.
# NOTE! All fields must be included (even if left empty).

# Cisco router type format.
# [cisco_router_type:<UUID of router type>]
# name=<router type name, should preferably be unique>
# description=<description of router type>
# template_id=<template to use to create hosting devices for this router type>
# ha_enabled_by_default=<True if HA should be enabled by default>
# shared=<True if if routertype is available to all tenants, False otherwise>
# slot_need=<Number of slots this router type consume in hosting device>
# scheduler=<module to be used as scheduler for router of this type>  (1)
# driver=<module to be used by router plugin as router type driver>    (2)
# cfg_agent_service_helper=<module to be used by configuration agent
#                           as service helper driver                  (3)
# cfg_agent_driver=<module to be used by configuration agent for
#                   device configurations>                            (4)

# (1) --(4): Leave empty for routers implemented in network nodes

Example:
[cisco_router_type:1]
name=Namespace_Neutron_router
description="Neutron router implemented in Linux network namespace"
template_id=1
shared=True
slot_need=0
scheduler=
driver=
cfg_agent_service_helper=
cfg_agent_driver=

# [cisco_router_type:2]
# name=CSR1kv_router
# description="Neutron router implemented in Cisco CSR1kv device"
# template_id=2
# ha_enabled_by_default=False
# shared=True
# slot_need=10
# scheduler=networking_cisco.plugins.cisco.l3.schedulers.l3_router_hosting_device_scheduler.L3RouterHostingDeviceLongestRunningScheduler
# driver=networking_cisco.plugins.cisco.l3.drivers.noop_routertype_driver.NoopL3RouterDriver
# cfg_agent_service_helper=networking_cisco.plugins.cisco.cfg_agent.service_helpers.routing_svc_helper.RoutingServiceHelper
# Use this cfg agent driver for N1kv VLAN trunking
# cfg_agent_driver=networking_cisco.plugins.cisco.cfg_agent.device_drivers.csr1kv.csr1kv_routing_driver.CSR1kvRoutingDriver
# Use this cfg agent driver for VIF hot-plug (with plugins like ML2)
# cfg_agent_driver=networking_cisco.plugins.cisco.cfg_agent.device_drivers.csr1kv.csr1kv_hotplug_routing_driver.CSR1kvHotPlugRoutingDriver

[cisco_router_type:3]
name=Hardware_Neutron_router
description="Neutron router implemented in Cisco ASR1k device"
template_id=3
ha_enabled_by_default=True
shared=True
slot_need=1
scheduler=networking_cisco.plugins.cisco.l3.schedulers.l3_router_hosting_device_scheduler.L3RouterHostingDeviceHARandomScheduler
driver=networking_cisco.plugins.cisco.l3.drivers.asr1k.asr1k_routertype_driver.ASR1kL3RouterDriver
cfg_agent_service_helper=networking_cisco.plugins.cisco.cfg_agent.service_helpers.routing_svc_helper.RoutingServiceHelper
cfg_agent_driver=networking_cisco.plugins.cisco.cfg_agent.device_drivers.asr1k.asr1k_routing_driver.ASR1kRoutingDriver

[ha]
# Enables high-availability support for routing service
ha_support_enabled = True

# Default number of routers added for redundancy when high-availability
# by VRRP, HSRP, or GLBP is used (maximum is 4)
# default_ha_redundancy_level = 1

# Default mechanism used to implement high-availability. Can be one of HSRP,
# VRRP, or GLBP
# default_ha_mechanism = HSRP

# List of administratively disabled high-availability mechanisms (one or
# several of VRRP, HSRP, GBLP)
# disabled_ha_mechanisms = []

# Enables connectivity probing for high-availability even if (admin) user does
# not explicitly request it
# connectivity_probing_enabled_by_default = False

# Host that will be probe target for high-availability connectivity probing
# if (admin) user does not specify it
# default_probe_target = None

# Time (in seconds) between probes for high-availability connectivity probing
# if user does not specify it
# default_ping_interval = 5
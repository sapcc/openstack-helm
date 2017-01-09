# neutron.conf
[DEFAULT]
debug = {{.Values.debug}}
verbose=True

log_config_append = /etc/neutron/logging.conf

#lock_path = /var/lock/neutron
api_paste_config = /etc/neutron/api-paste.ini

allow_pagination = true
allow_sorting = true

interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver

allow_overlapping_ips = true
core_plugin = ml2
#service_plugins = router
#service_plugins=networking_cisco.plugins.cisco.service_plugins.cisco_device_manager_plugin.CiscoDeviceManagerPlugin,networking_cisco.plugins.cisco.service_plugins.cisco_router_plugin.CiscoRouterPlugin

#service_plugins=lbaas,networking_cisco.plugins.cisco.service_plugins.cisco_device_manager_plugin.CiscoDeviceManagerPlugin,networking_cisco.plugins.cisco.service_plugins.cisco_router_plugin.CiscoRouterPlugin

service_plugins=neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPluginv2,networking_cisco.plugins.cisco.service_plugins.cisco_device_manager_plugin.CiscoDeviceManagerPlugin,networking_cisco.plugins.cisco.service_plugins.cisco_router_plugin.CiscoRouterPlugin

default_router_type = ASR1k_router

dhcp_agent_notification = true
network_auto_schedule = True
allow_automatic_dhcp_failover = True
dhcp_agents_per_network=2
dhcp_lease_duration = {{.Values.dhcp_lease_duration}}

# Designate configuration
dns_domain =  {{.Values.dns_local_domain}}
external_dns_driver = {{.Values.dns_external_driver}}

global_physnet_mtu = {{.Values.global.default_mtu}}
advertise_mtu = True

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

[nova]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_plugin = v3password
region_name = {{.Values.global.region}}
username = {{ .Values.global.nova_service_user }}
password = {{ .Values.global.nova_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
insecure = True
endpoint_type = internal

[designate]
url =  {{.Values.global.designate_api_endpoint_protocol_admin}}://{{include "designate_api_endpoint_host_admin" .}}:{{ .Values.global.designate_api_port_admin }}/v2
admin_auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v2.0
admin_username = {{ .Values.global.designate_service_user }}
admin_password = {{ .Values.global.designate_service_password }}
admin_tenant_name = {{.Values.global.keystone_service_project}}
insecure=True
allow_reverse_dns_lookup = False
ipv4_ptr_zone_prefix_size = 24


[oslo_concurrency]
lock_path = /var/lib/neutron/tmp

[oslo_messaging_rabbit]
rabbit_userid = {{ .Values.global.rabbitmq_default_user }}
rabbit_password = {{ .Values.global.rabbitmq_default_pass }}
rabbit_host =  {{include "rabbitmq_host" .}}
rabbit_ha_queues = true

[oslo_middleware]
enable_proxy_headers_parsing = true

[agent]
root_helper = sudo neutron-rootwrap /etc/neutron/rootwrap.conf


[database]
connection = postgresql://{{.Values.db_user}}:{{.Values.db_password}}@{{include "neutron_db_host" .}}:{{.Values.global.postgres_port_public}}/{{.Values.db_name}}

[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.neutron_service_user }}
password = {{ .Values.global.neutron_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
insecure = True

[oslo_messaging_notifications]
driver = noop

[quotas]
default_quota = 0
quota_network = 0
quota_subnet = 0
quota_router = 0
quota_rbac_policy = -1

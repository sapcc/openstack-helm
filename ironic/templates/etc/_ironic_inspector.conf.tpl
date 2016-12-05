[DEFAULT]
debug = {{.Values.debug}}
syslog_log_facility=LOG_LOCAL0
use_syslog=yes
#admin_token =
enabled_drivers=pxe_ipmitool,agent_ipmitool
network_provider=neutron_plugin

enabled_network_interfaces=noop,flat,neutron
default_network_interface=neutron

[dhcp]
dhcp_provider=none

[api]
host_ip = 0.0.0.0


[firewall]
manage_firewall=False

[processing]
always_store_ramdisk_logs=true
ramdisk_logs_dir=/var/log/ironic-inspector/
add_ports=all
keep_ports=all
ipmi_address_fields=ilo_address
enable_setting_ipmi_credentials=true
log_bmc_address=true
node_not_found_hook=enroll
default_processing_hooks=ramdisk_error,root_disk_selection,scheduler,validate_interfaces,capabilities,pci_devices,extra_hardware
processing_hooks=$default_processing_hooks, local_link_connection

[discovery]
enroll_node_driver=agent_ipmitool



[database]
connection = postgresql://{{.Values.inspector_db_user}}:{{.Values.inspector_db_password}}@{{include "ironic_db_host" .}}:{{.Values.global.postgres_port_public}}/{{.Values.inspector_db_name}}

[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.ironic_service_user }}
password = {{ .Values.global.ironic_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
insecure = True


[oslo_messaging_rabbit]
rabbit_userid = {{ .Values.global.rabbitmq_default_user }}
rabbit_password = {{ .Values.global.rabbitmq_default_pass }}
rabbit_host =  {{include "rabbitmq_host" .}}
rabbit_ha_queues = true

[oslo_middleware]
enable_proxy_headers_parsing = True

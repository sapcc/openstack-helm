[DEFAULT]
log-config-append = /etc/ironic/logging.conf

enabled_drivers = {{.Values.enabled_drivers | default "pxe_ipmitool,agent_ipmitool"}}
enabled_network_interfaces = noop,flat,neutron
default_network_interface = neutron

[ironic]
os_region = {{.Values.global.region}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.ironic_service_user }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.ironic_service_password | default (tuple . .Values.global.ironic_service_user | include "identity.password_for_user")  | replace "$" "$$" | quote }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}

[api]
host_ip = 0.0.0.0

[firewall]
manage_firewall = False

[processing]
always_store_ramdisk_logs = true
ramdisk_logs_dir = /var/log/kolla/ironic/
add_ports = all
keep_ports = all
ipmi_address_fields = ilo_address
log_bmc_address = true
node_not_found_hook = enroll
default_processing_hooks = ramdisk_error,root_disk_selection,scheduler,validate_interfaces,capabilities,pci_devices,extra_hardware
processing_hooks = $default_processing_hooks,local_link_connection

[discovery]
enroll_node_driver = agent_ipmitool

[database]
connection = {{ tuple . "ironic_inspector" "ironic_inspector" .Values.inspector_db_password | include "db_url" }}
{{- include "ini_sections.database_options" . }}

[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.ironic_service_user }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.ironic_service_password | default (tuple . .Values.global.ironic_service_user | include "identity.password_for_user") }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
region_name = {{.Values.global.region}}
insecure = True

{{include "oslo_messaging_rabbit" .}}

[oslo_middleware]
enable_proxy_headers_parsing = True

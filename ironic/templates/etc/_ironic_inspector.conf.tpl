[DEFAULT]
debug = {{.Values.debug}}
log-config-append = /var/lib/kolla/config_files/logging.conf

enabled_drivers=pxe_ipmitool,agent_ipmitool
enabled_network_interfaces=noop,flat,neutron
default_network_interface=neutron

[ironic]
os_region= {{.Values.global.region}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.ironic_service_user }}
password = {{ .Values.global.ironic_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}

[api]
host_ip = 0.0.0.0

[firewall]
manage_firewall=False

[processing]
always_store_ramdisk_logs=true
ramdisk_logs_dir=/var/log/kolla/ironic/
add_ports=all
keep_ports=all
ipmi_address_fields=ilo_address
log_bmc_address=true
node_not_found_hook=enroll
default_processing_hooks=ramdisk_error,root_disk_selection,scheduler,validate_interfaces,capabilities,pci_devices,extra_hardware
processing_hooks=$default_processing_hooks,local_link_connection

[discovery]
enroll_node_driver=agent_ipmitool
{{- if .Values.inspector.driver_defaults }}
driver_defaults={{ .Values.inspector.driver_defaults | replace "$" "$$" | quote }}
{{- end }}

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
region_name = {{.Values.global.region}}
insecure = True

{{include "oslo_messaging_rabbit" .}}

[oslo_middleware]
enable_proxy_headers_parsing = True

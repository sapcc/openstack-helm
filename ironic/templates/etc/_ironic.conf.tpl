[DEFAULT]
debug = {{.Values.debug}}
log-config-append = /var/lib/kolla/config_files/logging.conf

#admin_token =
enabled_drivers={{.Values.enabled_drivers | default "pxe_ipmitool,agent_ipmitool"}}
network_provider=neutron_plugin

enabled_network_interfaces=noop,flat,neutron
default_network_interface=neutron

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

[dhcp]
dhcp_provider=neutron

[pxe]
tftp_server = {{.Values.global.ironic_tftp_ip}}

[api]
host_ip = 0.0.0.0

[conductor]
api_url = {{.Values.global.ironic_api_endpoint_protocol_public}}://{{include "ironic_api_endpoint_host_public" .}}:{{ .Values.global.ironic_api_port_public }}
clean_nodes = false
automated_clean=false

[database]
connection = postgresql://{{.Values.db_user}}:{{.Values.db_password}}@{{include "ironic_db_host" .}}:{{.Values.global.postgres_port_public}}/{{.Values.db_name}}

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

[glance]
glance_host = {{.Values.global.glance_api_endpoint_protocol_internal}}://{{include "glance_api_endpoint_host_internal" .}}:{{.Values.global.glance_api_port_internal}}
auth_strategy=keystone
swift_temp_url_key={{ .Values.swift_tempurl }}
swift_temp_url_duration=1200
swift_endpoint_url={{.Values.global.swift_endpoint_protocol}}://{{include "swift_endpoint_host" .}}:{{ .Values.global.swift_api_port_public }}
swift_api_version=v1
swift_account={{ .Values.swift_account }}

[neutron]
url = {{.Values.global.neutron_api_endpoint_protocol_internal}}://{{include "neutron_api_endpoint_host_internal" .}}:{{ .Values.global.neutron_api_port_internal }}
cleaning_network_uuid={{ .Values.network_cleaning_uuid }}
provisioning_network_uuid={{ .Values.network_management_uuid }}

{{include "oslo_messaging_rabbit" .}}

[oslo_middleware]
enable_proxy_headers_parsing = True

[DEFAULT]
log-config-append = /etc/ironic/logging.conf

network_provider = neutron_plugin
enabled_network_interfaces = noop,flat,neutron
default_network_interface = neutron

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}


{{- if .Values.image_version_ironic_inspector }}

[inspector]
enabled=True
auth_section = keystone_authtoken
service_url=https://{{include "ironic_inspector_endpoint_host_public" .}}
{{- end }}

[dhcp]
dhcp_provider=neutron

[api]
host_ip = 0.0.0.0

{{- include "ini_sections.database" . }}

[keystone_authtoken]
auth_plugin = v3password
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
username = {{ .Values.global.ironic_service_user }}
password = {{ .Values.global.ironic_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}

[service_catalog]
auth_section = keystone_authtoken
insecure = True

[glance]
auth_section = keystone_authtoken
glance_host = {{.Values.global.glance_api_endpoint_protocol_internal}}://{{include "glance_api_endpoint_host_internal" .}}:{{.Values.global.glance_api_port_internal}}

{{- if .Values.swift_multi_tenant }}
swift_store_multiple_containers_seed=32
{{- end }}
swift_temp_url_key={{ .Values.swift_tempurl }}
swift_temp_url_duration=1200
# No terminal slash, it will break the url signing scheme
swift_endpoint_url={{.Values.global.swift_endpoint_protocol}}://{{include "swift_endpoint_host" .}}:{{ .Values.global.swift_api_port_public }}
swift_api_version=v1
swift_account={{ .Values.swift_account }}

[swift]
auth_section = keystone_authtoken

[neutron]
auth_section = keystone_authtoken
url = {{.Values.global.neutron_api_endpoint_protocol_internal}}://{{include "neutron_api_endpoint_host_internal" .}}:{{ .Values.global.neutron_api_port_internal }}
cleaning_network_uuid={{ .Values.network_cleaning_uuid }}
provisioning_network_uuid={{ .Values.network_management_uuid }}

{{include "oslo_messaging_rabbit" .}}

[oslo_middleware]
enable_proxy_headers_parsing = True

{{- include "osprofiler" . }}

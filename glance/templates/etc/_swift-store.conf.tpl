[swift-global]
auth_version = 3
project_domain_name = {{.Values.swift_domain}}
user_domain_name = {{.Values.global.keystone_service_domain}}
auth_address = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}/v3
key = {{ .Values.global.glance_service_password }}
user =  {{.Values.swift_project}}:{{ .Values.global.glance_service_user }}

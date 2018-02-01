{{- define "ironic_conf" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
[DEFAULT]
compute_driver=nova.virt.ironic.IronicDriver
reserved_host_memory_mb={{$hypervisor.reserved_host_memory_mb | default .reserved_host_memory_mb | default 0 }}

[ironic]
#TODO: this should be V3 also?

admin_username={{.Values.global.ironic_service_user }}{{ .Values.global.user_suffix }}
admin_password={{ .Values.global.ironic_service_password | default (tuple . .Values.global.ironic_service_user | include "identity.password_for_user")  | replace "$" "$$" }}
admin_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v2.0
admin_tenant_name={{.Values.global.keystone_service_project}}
api_endpoint={{.Values.global.ironic_api_endpoint_protocol_internal}}://{{include "ironic_api_endpoint_host_internal" .}}:{{ .Values.global.ironic_api_port_internal }}/v1
{{- end }}
{{- end }}

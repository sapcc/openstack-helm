# Defines configuration options specific for Arista ML2 Mechanism driver

[ml2_arista]
eapi_host ={{.Values.arista_eapi_host}}
eapi_username = {{.Values.arista_eapi_username}}
eapi_password = {{.Values.arista_eapi_password}}

# use_fqdn =
# sync_interval =

switch_info = {{range $i, $switch := .Values.arista_switches}}{{$switch.host}}:{{$switch.user}}:{{$switch.password}}{{ if lt $i (sub (len $.Values.arista_switches) 1) }},{{end}}{{end}}

region_name = {{.Values.global.region}}

auth_host = {{include "keystone_api_endpoint_host_public" .}}
admin_username = {{ .Values.global.neutron_service_user }}{{ .Values.global.user_suffix }}
admin_password = {{ .Values.global.neutron_service_password | default (tuple . .Values.global.neutron_service_user | include "identity.password_for_user") | replace "$" "$$" | quote }}
admin_tenant_name = {{.Values.global.keystone_service_project}}
managed_physnets={{.Values.arista_physnet}}



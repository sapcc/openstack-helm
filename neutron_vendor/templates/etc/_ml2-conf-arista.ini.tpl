# Defines configuration options specific for Arista ML2 Mechanism driver

[ml2_arista]
eapi_host ={{.Values.arista_eapi_host}}
eapi_username = {{.Values.arista_eapi_username}}
eapi_password = {{.Values.arista_eapi_password}}

# use_fqdn =
# sync_interval =

switch_info = {{.Values.arista_switch_host}}:{{.Values.arista_switch_username}}:{{.Values.arista_switch_password}}

region_name = {{.Values.global.region}}

auth_host = {{include "keystone_api_endpoint_host_public" .}}
admin_username = {{ .Values.global.neutron_service_user }}
admin_password = {{ .Values.global.neutron_service_password }}
admin_tenant_name = {{.Values.global.keystone_service_project}}
managed_physnets={{.Values.arista_physnet}}



[DEFAULT]
log_config_append = /etc/neutron/logging.conf

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

[service_providers]
service_provider = LOADBALANCERV2:F5Networks:neutron_lbaas.drivers.f5.driver_v2.F5LBaaSV2Driver:default

[service_auth]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}/v3
admin_project_domain= {{.Values.global.keystone_service_domain}}
admin_user_domain= {{.Values.global.keystone_service_domain}}
admin_tenant_name =  {{.Values.global.keystone_service_project}}
admin_user = {{ .Values.global.neutron_service_user }}
admin_password = {{ .Values.global.neutron_service_password }}
region={{.Values.global.region}}
service_name=lbaas
auth_version = 3
insecure=True

[quotas]
quota_loadbalancer=0
quota_listener=0
quota_pool=0
quota_member=0
quota_healthmonitor=0

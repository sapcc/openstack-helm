# metadata_agent.ini
[DEFAULT]
debug = {{.Values.debug}}

#endpoint_type = internalURL

nova_metadata_ip = {{include "nova_api_endpoint_host_internal" .}}
nova_metadata_protocol = {{.Values.global.nova_api_endpoint_protocol_internal}}
nova_metadata_port = {{ .Values.global.nova_metadata_port_internal }}

metadata_proxy_shared_secret = {{.Values.global.nova_metadata_secret}}
metadata_proxy_socket=/run/metadata_proxy

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}

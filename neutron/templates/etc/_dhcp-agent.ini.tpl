# dhcp_agent.ini
[DEFAULT]

debug = {{.Values.debug}}

dnsmasq_config_file = /etc/neutron/dnsmasq.conf
force_metadata=True
enable_isolated_metadata=True
metadata_proxy_socket=/run/metadata_proxy
dnsmasq_dns_servers = {{.Values.dns_forwarders}}
dhcp_domain = {{.Values.dns_local_domain}}

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}
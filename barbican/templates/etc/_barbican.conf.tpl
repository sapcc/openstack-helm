[DEFAULT]
# Show debugging output in logs (sets DEBUG log level output)
debug = {{.Values.debug}}

log_config_append = /etc/barbican/logging.conf

# Address to bind the API server
bind_host = 0.0.0.0

# Port to bind the API server to
bind_port =  {{.Values.global.barbican_port_internal}}

# Host name, for use in HATEOAS-style references
#  Note: Typically this would be the load balanced endpoint that clients would use
#  communicate back with this service.
# If a deployment wants to derive host from wsgi request instead then make this
# blank. Blank is needed to override default config value which is
# 'http://localhost:9311'.
host_href = {{.Values.global.barbican_api_endpoint_protocol_public}}://{{include "barbican_api_endpoint_host_public" .}}:{{.Values.global.barbican_api_port_public}}

# Log to this file. Make sure you do not set the same log
# file for both the API and registry servers!
#log_file = /var/log/barbican/api.log

# Backlog requests when creating socket
backlog = 4096

# TCP_KEEPIDLE value in seconds when creating socket.
# Not supported on OS X.
#tcp_keepidle = 600

# Maximum allowed http request size against the barbican-api
max_allowed_secret_in_bytes = 10000
max_allowed_request_size_in_bytes = 1000000

sql_connection = {{ include "db_url" . }}

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}
max_pool_size = {{ .Values.max_pool_size | default .Values.global.max_pool_size | default 5 }}
max_overflow = {{ .Values.max_overflow | default .Values.global.max_overflow | default 10 }}

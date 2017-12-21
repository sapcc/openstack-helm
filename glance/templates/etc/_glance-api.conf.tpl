[DEFAULT]

# If set to true, the logging level will be set to DEBUG instead of
# the default INFO level. (boolean value)
debug = {{.Values.debug}}

# Address to find the registry server. (string value)
registry_host = 127.0.0.1

# The name of a logging configuration file. This file is appended to
# any existing logging configuration files. For details about logging
# configuration files, see the Python logging module documentation.
# Note that when logging configuration files are used then all logging
# configuration is set in the configuration file and other logging
# configuration options are ignored (for example,
# logging_context_format_string). (string value)
# Deprecated group/name - [DEFAULT]/log_config
log_config_append = /etc/glance/logging.conf

# Whether to include the backend image storage location in image
# properties. Revealing storage location can be a security risk, so
# use this setting with caution! (boolean value)
show_image_direct_url= True

# Role used to identify an authenticated user as administrator.
# (string value)
#disable default admin rights for role 'admin'
admin_role = ''

# Seconds to wait for a response from a call. (integer value)
rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 300 }}

rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}
{{ include "ini_sections.database_options" . }}

# The value for the socket option TCP_KEEPIDLE.  This is the time in
# seconds that the connection must be idle before TCP starts sending
# keepalive probes. (integer value)
tcp_keepidle = {{ .Values.tcp_keepidle | default .Values.global.tcp_keepidle | default 600 }}

{{- include "ini_sections.database" . }}

[keystone_authtoken]
# Complete public Identity API endpoint. (string value)
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}

# The URL to the keystone service. If "use_user_token" is not in
# effect and using keystone auth, then URL of keystone can be
# specified. (string value)
# This option is deprecated for removal.
# Its value may be silently ignored in the future.
# Reason: This option was considered harmful and has been deprecated
# in M release. It will be removed in O release. For more information
# read OSSN-0060. Related functionality with uploading big images has
# been implemented with Keystone trusts support.
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3

# Authentication type to load (unknown value)
auth_type = v3password

username = {{ .Values.global.glance_service_user }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.glance_service_password | default (tuple . .Values.global.glance_service_user | include "identity.password_for_user") | replace "$" "$$" | quote }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
insecure = True


[paste_deploy]

# Partial name of a pipeline in your paste configuration file with the
# service name removed. For example, if your paste section name is
# [pipeline:glance-api-keystone] use the value "keystone" (string
# value)
flavor = keystone


[oslo_middleware]
enable_proxy_headers_parsing = true

[glance_store]
# List of stores enabled. Valid stores are: cinder, file, http, rbd,
# sheepdog, swift, s3, vsphere (list value)
stores = swift,file

# Default scheme to use to store image data. The scheme must be
# registered by one of the stores defined by the 'stores' config
# option. (string value)
default_store = {{.Values.default_store}}

filesystem_store_datadir = /glance_store

swift_store_region={{.Values.global.region}}
swift_store_auth_insecure = True
swift_store_create_container_on_put = True
swift_store_multi_tenant = {{.Values.swift_multi_tenant}}
{{- if .Values.swift_store_large_object_size }}
swift_store_large_object_size = {{.Values.swift_store_large_object_size}}
{{- end }}

default_swift_reference = swift-global
swift_store_config_file=/etc/glance/swift-store.conf
swift_store_use_trusts=True

[oslo_messaging_notifications]
driver = noop

{{- include "osprofiler" . }}

[DEFAULT]
debug = {{.Values.debug}}

registry_host = 127.0.0.1

log_config_append = /etc/glance/logging.conf

show_image_direct_url= True

#disable default admin rights for role 'admin'
admin_role = ''

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

[database]
connection = postgresql://{{.Values.db_user}}:{{.Values.db_password}}@{{include "glance_db_host" .}}:{{.Values.postgres.port_public}}/{{.Values.db_name}}

[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.glance_service_user }}
password = {{ .Values.global.glance_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
insecure = True


[paste_deploy]
flavor = keystone


[oslo_middleware]
enable_proxy_headers_parsing = true

[glance_store]

stores = swift,file

default_store = {{.Values.default_store}}

filesystem_store_datadir = /glance_store

swift_store_region={{.Values.global.region}}
swift_store_auth_insecure = True
swift_store_create_container_on_put = True
swift_store_multi_tenant = {{.Values.swift_multi_tenant}}

default_swift_reference = swift-global
swift_store_config_file=/etc/glance/swift-store.conf

swift_store_use_trusts=True

[oslo_messaging_notifications]
driver = noop

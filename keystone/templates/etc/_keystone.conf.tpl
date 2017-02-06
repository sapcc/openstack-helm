[DEFAULT]
debug = {{.Values.debug}}
#insecure_debug = true
verbose = true

logging_context_format_string = %(process)d %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s
logging_default_format_string = %(process)d %(levelname)s %(name)s [-] %(instance)s%(message)s
logging_exception_prefix = %(process)d ERROR %(name)s %(instance)s

notification_driver = messaging
rpc_backend = rabbit

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}
max_pool_size = {{ .Values.max_pool_size | default .Values.global.max_pool_size | default 5 }}
max_overflow = {{ .Values.max_overflow | default .Values.global.max_overflow | default 10 }}

[cache]
backend = oslo_cache.memcache_pool
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
enabled = true

[memcache]
servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}

[token]
provider = fernet
# default is 3600, increased to 8 hrs because of endless image upload durations to ap-au-1
expiration = 28800

[fernet_tokens]
key_repository = /fernet-keys
max_active_keys = 3

[database]
connection = postgresql://{{.Values.db_user}}:{{.Values.db_password}}@{{include "keystone_db_host" .}}:{{.Values.global.postgres_port_public}}/{{.Values.db_name}}

[identity]
default_domain_id = default
domain_specific_drivers_enabled = true
domain_configurations_from_database = true

[catalog]
driver = endpoint_override

[trust]
enabled = true
allow_redelegation = true

[resource]
admin_project_domain_name = ccadmin
admin_project_name = cloud_admin

{{include "oslo_messaging_rabbit" .}}

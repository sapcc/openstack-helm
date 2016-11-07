[DEFAULT]
debug = {{.Values.debug}}

log_config_append = /etc/glance/logging.conf

#disable default admin rights for role 'admin'
admin_role = ''


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

[oslo_messaging_notifications]
driver = noop

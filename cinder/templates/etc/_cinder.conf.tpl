[DEFAULT]
debug = {{ .Values.debug}}

log_config_append = /etc/cinder/logging.conf

enable_v1_api=True
volume_name_template = '%s'

glance_api_servers = {{.Values.global.glance_api_endpoint_protocol_internal}}://{{include "glance_api_endpoint_host_internal" .}}:{{.Values.global.glance_api_port_internal}}
glance_api_version = 2

os_region_name = {{.Values.global.region}}

default_availability_zone={{.Values.global.default_availability_zone}}
default_volume_type = vmware


api_paste_config = /etc/cinder/api-paste.ini
#nova_catalog_info = compute:nova:internalURL

auth_strategy = keystone

rpc_response_timeout=300

[database]
connection = postgresql://{{.Values.db_user}}:{{.Values.db_password}}@{{include "cinder_db_host" .}}:{{.Values.postgres.port_public}}/{{.Values.db_name}}


[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.cinder_service_user }}
password = {{ .Values.global.cinder_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
insecure = True


[oslo_concurrency]
lock_path = /var/lib/cinder/tmp

[oslo_messaging_rabbit]
rabbit_userid = {{ .Values.global.rabbitmq_default_user }}
rabbit_password = {{ .Values.global.rabbitmq_default_pass }}
rabbit_host =  {{include "rabbitmq_host" .}}
rabbit_ha_queues = true

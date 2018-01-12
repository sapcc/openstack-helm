[DEFAULT]
debug = {{ .Values.debug}}

log_config_append = /etc/cinder/logging.conf

enable_v1_api=True
enable_v3_api=true
volume_name_template = '%s'

glance_api_servers = {{.Values.global.glance_api_endpoint_protocol_internal}}://{{include "glance_api_endpoint_host_internal" .}}:{{.Values.global.glance_api_port_internal}}
glance_api_version = 2

os_region_name = {{.Values.global.region}}

default_availability_zone={{.Values.global.default_availability_zone}}
default_volume_type = vmware


api_paste_config = /etc/cinder/api-paste.ini
#nova_catalog_info = compute:nova:internalURL

auth_strategy = keystone

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}
{{- include "ini_sections.database_options" . }}

# all default quotas are 0 to enforce usage of the Resource Management tool in Elektra
quota_volumes = 0
quota_snapshots = 0
quota_gigabytes = 0
quota_backups = 0
quota_backup_gigabytes = 0

# don't use quota class
use_default_quota_class=false

{{- include "ini_sections.database" . }}

{{- include "osprofiler" . }}


[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.cinder_service_user }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.cinder_service_password | default (tuple . .Values.global.cinder_service_user | include "identity.password_for_user") | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
insecure = True


[oslo_concurrency]
lock_path = /var/lib/cinder/tmp

{{include "oslo_messaging_rabbit" .}}

{{- include "ini_sections.audit_middleware_notifications" . }}

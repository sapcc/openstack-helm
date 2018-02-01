[DEFAULT]
debug = {{.Values.debug }}

log_config_append = /etc/manila/logging.ini

use_forwarded_for = true

# Following opt is used for definition of share backends that should be enabled.
# Values are conf groupnames that contain per manila-share service opts.
enabled_share_backends = netapp-multi

# Manila requires 'share-type' for share creation.
# So, set here name of some share-type that will be used by default.
default_share_type = default

# rootwrap_config = /etc/manila/rootwrap.conf
api_paste_config = /etc/manila/api-paste.ini

rpc_backend = rabbit

auth_strategy = keystone
os_region_name = {{.Values.global.region}}

osapi_share_listen = 0.0.0.0

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}
{{- include "ini_sections.database_options" . }}

delete_share_server_with_last_share = false
automatic_share_server_cleanup = true
# Unallocated share servers reclamation time interval (minutes).
unused_share_server_cleanup_interval = {{ .Values.share_server_cleanup_interval | default 10 }}

# all default quotas are 0 to enforce usage of the Resource Management tool in Elektra
quota_shares = 0
quota_gigabytes = 0
quota_snapshots = 0
quota_snapshot_gigabytes = 0
quota_share_networks = 0

[cinder]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_plugin = v3password
region_name = {{.Values.global.region}}
username = {{ .Values.global.cinder_service_user }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.cinder_service_password | default (tuple . .Values.global.cinder_service_user | include "identity.password_for_user") | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}


[nova]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_plugin = v3password
region_name = {{.Values.global.region}}
username = {{ .Values.global.nova_service_user }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.nova_service_password | default (tuple . .Values.global.nova_service_user | include "identity.password_for_user") | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
insecure = True

[neutron]
url = {{.Values.global.neutron_api_endpoint_protocol_internal}}://{{include "neutron_api_endpoint_host_internal" .}}:{{ .Values.global.neutron_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_plugin = v3password
username = {{ .Values.global.neutron_service_user }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.neutron_service_password | default (tuple . .Values.global.neutron_service_user | include "identity.password_for_user") | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
insecure = True

{{include "oslo_messaging_rabbit" .}}

[oslo_concurrency]
lock_path = /var/lib/manila/tmp

{{- include "ini_sections.database" . }}

[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.manila_service_user }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.manila_service_password | default (tuple . .Values.global.manila_service_user | include "identity.password_for_user") | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
insecure = True

[DEFAULT]
debug = {{.Values.debug }}

#use_syslog = True
#syslog_log_facility = LOG_LOCAL0
log_dir = /var/log/manila

logging_exception_prefix = %(color)s%(asctime)s.%(msecs)d TRACE %(name)s ^[[01;35m%(instance)s^[[00m
logging_debug_format_suffix = ^[[00;33mfrom (pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d^[[00m
logging_default_format_string = %(asctime)s.%(msecs)d %(color)s%(levelname)s %(name)s [^[[00;36m-%(color)s] ^[[01;35m%(instance)s%(color)s%(message)s^[[00m
logging_context_format_string = %(asctime)s.%(msecs)d %(color)s%(levelname)s %(name)s [^[[01;36m%(request_id)s ^[[00;36m%(user_id)s %(project_id)s%(color)s] ^[[01;35m%(instance)s%(color)s%(message)s^[[00m



use_forwarded_for = true



# Following opt is used for definition of share backends that should be enabled.
# Values are conf groupnames that contain per manila-share service opts.
enabled_share_backends = netapp-multi

# Manila requires 'share-type' for share creation.
# So, set here name of some share-type that will be used by default.
default_share_type = default

rootwrap_config = /etc/manila/rootwrap.conf
api_paste_config = /etc/manila/api-paste.ini

rpc_backend = rabbit

auth_strategy = keystone

os_region_name = {{.Values.global.region}}
osapi_share_listen = 0.0.0.0


[cinder]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_plugin = v3password
region_name = {{.Values.global.region}}
username = {{ .Values.global.cinder_service_user }}
password = {{ .Values.global.cinder_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}


[nova]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_plugin = v3password
region_name = {{.Values.global.region}}
username = {{ .Values.global.nova_service_user }}
password = {{ .Values.global.nova_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
insecure = True

[neutron]
url = {{.Values.global.neutron_api_endpoint_protocol_internal}}://{{include "neutron_api_endpoint_host_internal" .}}:{{ .Values.global.neutron_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_plugin = v3password
username = {{ .Values.global.neutron_service_user }}
password = {{ .Values.global.neutron_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
insecure = True



[oslo_messaging_rabbit]
rabbit_userid = {{ .Values.global.rabbitmq_default_user }}
rabbit_password = {{ .Values.global.rabbitmq_default_pass }}
rabbit_host =  {{include "rabbitmq_host" .}}
rabbit_ha_queues = true

[oslo_concurrency]
lock_path = /var/lib/manila/tmp

[database]
connection = postgresql://{{.Values.db_user}}:{{.Values.db_password}}@{{include "manila_db_host" .}}:{{.Values.global.postgres_port_public}}/{{.Values.db_name}}

[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin }}/v3
auth_type = v3password
username = {{ .Values.global.manila_service_user }}
password = {{ .Values.global.manila_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain}}
project_name = {{.Values.global.keystone_service_project}}
project_domain_name = {{.Values.global.keystone_service_domain}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public}}
insecure = True

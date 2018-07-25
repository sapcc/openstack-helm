#############
# OpenStack #
#############

[composite:osapi_volume]
use = call:cinder.api:root_app_factory
/: apiversions
/v1: openstack_volume_api_v1
/v2: openstack_volume_api_v2
/v3: openstack_volume_api_v3

{{- define "audit_pipe" -}}
{{- if .Values.audit.enabled }} audit{{- end -}}
{{- end }}

{{- define "watcher_pipe" -}}
{{- if .Values.watcher.enabled }} watcher{{- end -}}
{{- end }}

[composite:openstack_volume_api_v1]
use = call:cinder.api.middleware.auth:pipeline_factory
noauth = cors http_proxy_to_wsgi request_id faultwrap sizelimit {{- include "osprofiler_pipe" . }} noauth apiv1
keystone = cors http_proxy_to_wsgi request_id statsd faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv1
keystone_nolimit = cors http_proxy_to_wsgi request_id statsd faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv1

[composite:openstack_volume_api_v2]
use = call:cinder.api.middleware.auth:pipeline_factory
noauth = cors http_proxy_to_wsgi request_id {{- include "watcher_pipe" . }} statsd faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} noauth apiv2
keystone = cors http_proxy_to_wsgi request_id statsd faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv2
keystone_nolimit = cors http_proxy_to_wsgi request_id statsd faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv2

[composite:openstack_volume_api_v3]
use = call:cinder.api.middleware.auth:pipeline_factory
noauth = cors http_proxy_to_wsgi request_id {{- include "watcher_pipe" . }} statsd faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} noauth apiv3
keystone = cors http_proxy_to_wsgi request_id statsd faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv3
keystone_nolimit = cors http_proxy_to_wsgi request_id statsd faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv3

[filter:request_id]
paste.filter_factory = oslo_middleware.request_id:RequestId.factory

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware.http_proxy_to_wsgi:HTTPProxyToWSGI.factory

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = cinder

[filter:faultwrap]
paste.filter_factory = cinder.api.middleware.fault:FaultWrapper.factory

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

[filter:noauth]
paste.filter_factory = cinder.api.middleware.auth:NoAuthMiddleware.factory

[filter:sizelimit]
paste.filter_factory = cinder.api.middleware.sizelimit:RequestBodySizeLimiter.factory

[filter:healthcheck]
paste.filter_factory = oslo_middleware:Healthcheck.factory
backends = disable_by_file
disable_by_file_path = /etc/cinder/healthcheck_disable

[app:apiv1]
paste.app_factory = cinder.api.v1.router:APIRouter.factory

[app:apiv2]
paste.app_factory = cinder.api.v2.router:APIRouter.factory

[app:apiv3]
paste.app_factory = cinder.api.v3.router:APIRouter.factory

[pipeline:apiversions]
pipeline = cors healthcheck http_proxy_to_wsgi faultwrap osvolumeversionapp

[app:osvolumeversionapp]
paste.app_factory = cinder.api.versions:Versions.factory

##########
# Shared #
##########

[filter:keystonecontext]
paste.filter_factory = cinder.api.middleware.auth:CinderKeystoneContext.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

# Converged Cloud statsd & sentry middleware
[filter:statsd]
use = egg:ops-middleware#statsd

[filter:sentry]
use = egg:ops-middleware#sentry
level = ERROR

{{ if .Values.audit.enabled }}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/cinder/cinder_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{- if .Values.watcher.enabled }}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = volume
config_file = /etc/cinder/watcher.yaml
{{- end }}

############
# Metadata #
############
[composite:metadata]
use = egg:Paste#urlmap
/: meta

[pipeline:meta]
pipeline = cors metaapp

[app:metaapp]
paste.app_factory = nova.api.metadata.handler:MetadataRequestHandler.factory

#############
# OpenStack #
#############

[composite:osapi_compute]
use = call:nova.api.openstack.urlmap:urlmap_factory
/: oscomputeversions
# starting in Liberty the v21 implementation replaces the v2
# implementation and is suggested that you use it as the default. If
# this causes issues with your clients you can rollback to the
# *frozen* v2 api by commenting out the above stanza and using the
# following instead::
# /v2: openstack_compute_api_legacy_v2
# if rolling back to v2 fixes your issue please file a critical bug
# at - https://bugs.launchpad.net/nova/+bugs
#
# v21 is an exactly feature match for v2, except it has more stringent
# input validation on the wsgi surface (prevents fuzzing early on the
# API). It also provides new features via API microversions which are
# opt into for clients. Unaware clients will receive the same frozen
# v2 API feature set, but with some relaxed validation
/v2: openstack_compute_api_v21_legacy_v2_compatible
/v2.1: openstack_compute_api_v21

{{- define "audit_pipe" -}}
{{- if .Values.audit.enabled }} audit{{- end -}}
{{- end }}

{{- define "watcher_pipe" -}}
{{- if .Values.watcher.enabled }} watcher{{- end -}}
{{- end }}

# NOTE: this is deprecated in favor of openstack_compute_api_v21_legacy_v2_compatible
[composite:openstack_compute_api_legacy_v2]
use = call:nova.api.auth:pipeline_factory
noauth2 = cors compute_req_id {{- include "osprofiler_pipe" . }} statsd faultwrap sizelimit noauth2 {{- include "watcher_pipe" . }} legacy_ratelimit sentry osapi_compute_app_legacy_v2
keystone = cors compute_req_id {{- include "osprofiler_pipe" . }} statsd faultwrap sizelimit authtoken keystonecontext {{- include "watcher_pipe" . }} legacy_ratelimit sentry {{- include "audit_pipe" . }} osapi_compute_app_legacy_v2
keystone_nolimit = cors compute_req_id {{- include "osprofiler_pipe" . }} statsd faultwrap sizelimit authtoken keystonecontext {{- include "watcher_pipe" . }} sentry {{- include "audit_pipe" . }} osapi_compute_app_legacy_v2

[composite:openstack_compute_api_v21]
use = call:nova.api.auth:pipeline_factory_v21
noauth2 = cors healthcheck http_proxy_to_wsgi compute_req_id {{- include "osprofiler_pipe" . }} statsd faultwrap sizelimit noauth2 {{- include "watcher_pipe" . }} sentry {{- include "audit_pipe" . }} osapi_compute_app_v21
keystone = cors compute_req_id {{- include "osprofiler_pipe" . }} statsd faultwrap sizelimit authtoken keystonecontext {{- include "watcher_pipe" . }} sentry {{- include "audit_pipe" . }} osapi_compute_app_v21

[composite:openstack_compute_api_v21_legacy_v2_compatible]
use = call:nova.api.auth:pipeline_factory_v21
noauth2 = cors healthcheck http_proxy_to_wsgi compute_req_id {{- include "osprofiler_pipe" . }} statsd faultwrap sizelimit noauth2 legacy_v2_compatible {{- include "watcher_pipe" . }} sentry {{- include "audit_pipe" . }} osapi_compute_app_v21
keystone = cors healthcheck http_proxy_to_wsgi compute_req_id {{- include "osprofiler_pipe" . }} statsd faultwrap sizelimit authtoken keystonecontext legacy_v2_compatible {{- include "watcher_pipe" . }} sentry {{- include "audit_pipe" . }} osapi_compute_app_v21

[filter:request_id]
paste.filter_factory = oslo_middleware:RequestId.factory

[filter:compute_req_id]
paste.filter_factory = nova.api.compute_req_id:ComputeReqIdMiddleware.factory

[filter:faultwrap]
paste.filter_factory = nova.api.openstack:FaultWrapper.factory

[filter:healthcheck]
paste.filter_factory = oslo_middleware:Healthcheck.factory
backends = disable_by_file
disable_by_file_path = /etc/nova/healthcheck_disable

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware:HTTPProxyToWSGI.factory

[filter:noauth2]
paste.filter_factory = nova.api.openstack.auth:NoAuthMiddleware.factory

[filter:legacy_ratelimit]
paste.filter_factory = nova.api.openstack.compute.limits:RateLimitingMiddleware.factory

[filter:sizelimit]
paste.filter_factory = oslo_middleware:RequestBodySizeLimiter.factory

[filter:legacy_v2_compatible]
paste.filter_factory = nova.api.openstack:LegacyV2CompatibleWrapper.factory

[app:osapi_compute_app_legacy_v2]
paste.app_factory = nova.api.openstack.compute:APIRouter.factory

[app:osapi_compute_app_v21]
paste.app_factory = nova.api.openstack.compute:APIRouterV21.factory

[pipeline:oscomputeversions]
pipeline = faultwrap healthcheck http_proxy_to_wsgi oscomputeversionapp

[app:oscomputeversionapp]
paste.app_factory = nova.api.openstack.compute.versions:Versions.factory

##########
# Shared #
##########

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = nova

[filter:keystonecontext]
paste.filter_factory = nova.api.auth:NovaKeystoneContext.factory

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
audit_map_file = /etc/nova/nova_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{- if .Values.watcher.enabled }}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = compute
config_file = /etc/nova/watcher.yaml
{{- end }}

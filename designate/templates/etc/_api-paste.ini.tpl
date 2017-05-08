[composite:osapi_dns]
use = egg:Paste#urlmap
/: osapi_dns_versions
/v1: osapi_dns_v1
/v2: osapi_dns_v2
/admin: osapi_dns_admin

[composite:osapi_dns_versions]
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors maintenance faultwrapper sentry osapi_dns_app_versions
keystone = http_proxy_to_wsgi cors maintenance faultwrapper sentry osapi_dns_app_versions

[app:osapi_dns_app_versions]
paste.app_factory = designate.api.versions:factory

[composite:osapi_dns_v1]
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors request_id noauthcontext statsd maintenance validation_API_v1 faultwrapper_v1 sentry normalizeuri osapi_dns_app_v1
keystone = http_proxy_to_wsgi cors request_id authtoken statsd keystonecontext maintenance validation_API_v1 faultwrapper_v1 sentry normalizeuri osapi_dns_app_v1


[app:osapi_dns_app_v1]
paste.app_factory = designate.api.v1:factory

[composite:osapi_dns_v2]
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors request_id statsd faultwrapper sentry validation_API_v2 noauthcontext maintenance normalizeuri osapi_dns_app_v2
keystone = http_proxy_to_wsgi cors request_id statsd faultwrapper sentry validation_API_v2 authtoken keystonecontext maintenance normalizeuri osapi_dns_app_v2

[app:osapi_dns_app_v2]
paste.app_factory = designate.api.v2:factory

[composite:osapi_dns_admin]
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors request_id statsd faultwrapper sentry noauthcontext maintenance normalizeuri osapi_dns_app_admin
keystone = http_proxy_to_wsgi cors request_id statsd faultwrapper sentry authtoken keystonecontext maintenance normalizeuri osapi_dns_app_admin

[app:osapi_dns_app_admin]
paste.app_factory = designate.api.admin:factory

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = designate

[filter:request_id]
paste.filter_factory = oslo_middleware:RequestId.factory

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware:HTTPProxyToWSGI.factory

[filter:noauthcontext]
paste.filter_factory = designate.api.middleware:NoAuthContextMiddleware.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:keystonecontext]
paste.filter_factory = designate.api.middleware:KeystoneContextMiddleware.factory

[filter:maintenance]
paste.filter_factory = designate.api.middleware:MaintenanceMiddleware.factory

[filter:normalizeuri]
paste.filter_factory = designate.api.middleware:NormalizeURIMiddleware.factory

[filter:faultwrapper]
paste.filter_factory = designate.api.middleware:FaultWrapperMiddleware.factory

[filter:faultwrapper_v1]
paste.filter_factory = designate.api.middleware:FaultWrapperMiddlewareV1.factory

[filter:validation_API_v1]
paste.filter_factory = designate.api.middleware:APIv1ValidationErrorMiddleware.factory

[filter:validation_API_v2]
paste.filter_factory = designate.api.middleware:APIv2ValidationErrorMiddleware.factory

# Converged Cloud statsd & sentry middleware
[filter:statsd]
use = egg:ops-middleware#statsd

[filter:sentry]
use = egg:ops-middleware#sentry
level = ERROR
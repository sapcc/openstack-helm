[composite:neutron]
use = egg:Paste#urlmap
/: neutronversions
/v2.0: neutronapi_v2_0

[composite:neutronapi_v2_0]
use = call:neutron.auth:pipeline_factory
noauth = cors healthcheck http_proxy_to_wsgi request_id statsd catch_errors sentry extensions neutronapiapp_v2_0
keystone = cors healthcheck http_proxy_to_wsgi request_id statsd catch_errors sentry authtoken keystonecontext extensions neutronapiapp_v2_0

[filter:healthcheck]
paste.filter_factory = oslo_middleware:Healthcheck.factory
backends = disable_by_file
disable_by_file_path = /etc/neutron/healthcheck_disable

[filter:request_id]
paste.filter_factory = oslo_middleware:RequestId.factory

[filter:catch_errors]
paste.filter_factory = oslo_middleware:CatchErrors.factory

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = neutron

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware:HTTPProxyToWSGI.factory

[filter:keystonecontext]
paste.filter_factory = neutron.auth:NeutronKeystoneContext.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:extensions]
paste.filter_factory = neutron.api.extensions:plugin_aware_extension_middleware_factory

[app:neutronversionsapp]
paste.app_factory = neutron.api.versions:Versions.factory

[app:neutronapiapp_v2_0]
paste.app_factory = neutron.api.v2.router:APIRouter.factory

[pipeline:neutronversions]
pipeline = http_proxy_to_wsgi healthcheck neutronversionsapp

# Converged Cloud statsd & sentry middleware
[filter:statsd]
use = egg:ops-middleware#statsd

[filter:sentry]
use = egg:ops-middleware#sentry
level = ERROR

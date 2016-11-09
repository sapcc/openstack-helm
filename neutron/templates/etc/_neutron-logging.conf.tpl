[loggers]
#keys = root, neutron,neutron_lbaas, networkingaci,networkingdvs,networkingcisco,networkingarista,networking_f5_ml2,f5lbaasdriver,f5_openstack_agent

keys = {{.Values.loggers_keys}}

[handlers]
keys = stderr, stdout, null, sentry

[formatters]
keys = context, default

[logger_root]
level = DEBUG
handlers = null

[logger_neutron]
level = DEBUG
handlers = stdout, sentry
qualname = neutron

[logger_neutron_lbaas]
level = DEBUG
handlers = stdout, sentry
qualname = neutron_lbaas


[logger_amqp]
level = WARNING
handlers = stdout, sentry
qualname = amqp

[logger_amqplib]
level = WARNING
handlers = stdout, sentry
qualname = amqplib

[logger_sqlalchemy]
level = WARNING
handlers = stdout, sentry
qualname = sqlalchemy
# "level = INFO" logs SQL queries.
# "level = DEBUG" logs SQL queries and results.
# "level = WARNING" logs neither.  (Recommended for production systems.)

[logger_boto]
level = WARNING
handlers = stdout, sentry
qualname = boto

# NOTE(mikal): suds is used by the vmware driver, removing this will
# cause many extraneous log lines for their tempest runs. Refer to
# https://review.openstack.org/#/c/219225/ for details.
[logger_suds]
level = INFO
handlers = stdout, sentry
qualname = suds

[logger_eventletwsgi]
level = INFO
handlers = stdout, sentry
qualname = eventlet.wsgi.server

[logger_networkingaci]
level = DEBUG
handlers = stdout, sentry
qualname = networking_aci

[logger_networkingcisco]
level = DEBUG
handlers = stdout, sentry
qualname = networking_cisco

[logger_networkingarista]
level = DEBUG
handlers = stdout, sentry
qualname = networking_arista

[logger_networkingdvs]
level = DEBUG
handlers = stdout, sentry
qualname = networking_dvs

[logger_f5lbaasdriver]
level = DEBUG
handlers = stdout, sentry
qualname = f5lbaasdriver

[logger_f5_openstack_agent]
level = DEBUG
handlers = stdout, sentry
qualname = f5_openstack_agent


[logger_networking_f5_ml2]
level = DEBUG
handlers = stdout, sentry
qualname = networking_f5_ml2




[handler_stderr]
class = StreamHandler
args = (sys.stderr,)
formatter = context

[handler_stdout]
class = StreamHandler
args = (sys.stdout,)
formatter = context

[handler_null]
class = logging.NullHandler
formatter = default
args = ()

[handler_sentry]
class=raven.handlers.logging.SentryHandler
level=ERROR
args=()

[formatter_context]
class = oslo_log.formatters.ContextFormatter

[formatter_default]
format = %(message)s

[loggers]
keys = root, nova, oslo_vmware

[handlers]
keys = stderr, stdout, null, sentry

[formatters]
keys = context, default

[logger_root]
level = WARNING
handlers = null

[logger_nova]
level = DEBUG
handlers = stdout, sentry
qualname = nova

[logger_oslo_vmware]
level = DEBUG
handlers = stdout, sentry
qualname = oslo_vmware


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

[handler_stderr]
class = StreamHandler
args = (sys.stderr,)
formatter = context

[handler_stdout]
class = StreamHandler
args = (sys.stdout,)
formatter = context

#[handler_watchedfile]
#class = handlers.WatchedFileHandler
#args = ('nova.log',)
#formatter = context

#[handler_syslog]
#class = handlers.SysLogHandler
#args = ('/dev/log', handlers.SysLogHandler.LOG_USER)
#formatter = context

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

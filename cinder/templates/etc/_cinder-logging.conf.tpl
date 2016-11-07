[loggers]
keys = root, cinder, taskflow, cinder_flow_utils, oslo_vmware

[handlers]
keys = stderr, stdout, null, sentry

[formatters]
keys = context, default

[logger_root]
level = WARNING
handlers = null

[logger_cinder]
level = INFO
handlers = stdout, sentry
qualname = cinder

# Both of these are used for tracking what cinder and taskflow is doing with
# regard to flows and tasks (and the activity there-in).
[logger_cinder_flow_utils]
level = INFO
handlers = stdout, sentry
qualname = cinder.flow_utils

[logger_oslo_vmware]
level = DEBUG
handlers = stdout, sentry
qualname = oslo_vmware


[logger_taskflow]
level = INFO
handlers = stdout, sentry
qualname = taskflow

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

[logger_suds]
level = INFO
handlers = stdout, sentry
qualname = suds

[logger_eventletwsgi]
level = INFO
handlers = stdout, sentry
qualname = eventlet.wsgi.server

[handler_sentry]
class=raven.handlers.logging.SentryHandler
level=ERROR
args=()

[handler_stderr]
class = StreamHandler
args = (sys.stderr,)
formatter = context

[handler_stdout]
class = StreamHandler
args = (sys.stdout,)
formatter = context

#[handler_syslog]
#class = handlers.SysLogHandler
#args = ('/dev/log', handlers.SysLogHandler.LOG_USER)
#formatter = context

[handler_null]
class = logging.NullHandler
formatter = default
args = ()

[formatter_context]
class = oslo_log.formatters.ContextFormatter

[formatter_default]
format = %(message)s

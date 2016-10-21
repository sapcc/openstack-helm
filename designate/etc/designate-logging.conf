[loggers]
keys = root, designate

[handlers]
keys = stderr, stdout, null, sentry

[formatters]
keys = context, default

[logger_root]
level = WARNING
handlers = null

[logger_designate]
level = DEBUG
handlers = stdout, sentry
qualname = designate

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


#!/usr/bin/env bash
{{- $envAll := . }}
set -e

function upsert_user {
    rabbitmqctl add_user "$1" "$2" || rabbitmqctl change_password "$1" "$2"
    rabbitmqctl set_permissions "$1" ".*" ".*" ".*"
    [ -z "$3" ] || rabbitmqctl set_user_tags "$1" "$3"
}

function bootstrap {
   #Not especially proud of this, but it works (unlike the environment variable approach in the docs)
   chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

   /etc/init.d/rabbitmq-server start

{{- if .Values.debug }}
   rabbitmq-plugins enable rabbitmq_tracing
   rabbitmqctl trace_on
{{- end }}
{{ range $user, $values := .Values.users }}
   upsert_user {{ print $values.user $envAll.Values.global.user_suffix | squote }} {{ default ( tuple $envAll $values.user (include "fullname" $envAll) | include "svc.password_for_user_and_service" ) $values.password | squote }}
{{- end }}
{{- if .Values.metrics.enabled }}
   upsert_user {{ .Values.metrics.user | squote }} {{ default ( tuple . .Values.metrics.user (include "fullname" . ) | include "svc.password_for_fixed_user_and_service" ) .Values.metrics.password | squote }} monitoring
{{- end }}

   rabbitmqctl change_password guest {{ .Values.users.default.password | squote }} || true
   rabbitmqctl set_user_tags guest monitoring || true
   /etc/init.d/rabbitmq-server stop
}


function start_application {
  echo "Starting RabbitMQ with lock /var/lib/rabbitmq/rabbitmq-server.lock"
  LOCKFILE=/var/lib/rabbitmq/rabbitmq-server.lock
  exec 9>${LOCKFILE}
  /usr/bin/flock -n 9
  exec gosu rabbitmq rabbitmq-server
}

bootstrap
start_application



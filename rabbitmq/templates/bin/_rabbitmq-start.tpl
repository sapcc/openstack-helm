#!/usr/bin/env bash
{{- $envAll := . }}
set -e

LOCKFILE=/var/lib/rabbitmq/rabbitmq-server.lock
echo "Acquiring RabbitMQ lock ${LOCKFILE}"
exec 9>${LOCKFILE}
/usr/bin/flock -n 9

function upsert_user {
    rabbitmqctl add_user "$1" "$2" || rabbitmqctl change_password "$1" "$2"
    rabbitmqctl set_permissions "$1" ".*" ".*" ".*"
    [ -z "$3" ] || rabbitmqctl set_user_tags "$1" "$3"
}

function bootstrap {
    #Not especially proud of this, but it works (unlike the environment variable approach in the docs)
    chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

    /etc/init.d/rabbitmq-server start || ( cat /var/log/rabbitmq/startup_* && exit 1 )

{{- if .Values.debug }}
    rabbitmq-plugins enable rabbitmq_tracing
    rabbitmqctl trace_on
{{- end }}
    upsert_user {{ print .Values.global.rabbitmq_default_user .Values.global.user_suffix | replace "$" "\\$" | quote }} {{ .Values.global.rabbitmq_default_pass | default ( tuple . .Values.global.rabbitmq_default_user "rabbitmq" | include "svc.password_for_user_and_service" ) | replace "$" "\\$" | quote }}
    upsert_user {{ print .Values.global.rabbitmq_admin_user .Values.global.user_suffix | replace "$" "\\$" | quote }} {{ .Values.global.rabbitmq_admin_pass | default ( tuple . .Values.global.rabbitmq_admin_user "rabbitmq" | include "svc.password_for_user_and_service" ) | replace "$" "\\$" | quote }} administrator
    upsert_user {{ .Values.global.rabbitmq_metrics_user | replace "$" "\\$" | quote }} {{ .Values.global.rabbitmq_metrics_pass | default ( tuple . .Values.global.rabbitmq_metrics_user "rabbitmq" | include "svc.password_for_user_and_service" ) | replace "$" "\\$" | quote }} monitoring

    rabbitmqctl change_password guest {{ .Values.global.rabbitmq_default_pass | default ( tuple . "guest" "rabbitmq" | include "svc.password_for_user_and_service" ) | replace "$" "\\$" | quote }} || true
    rabbitmqctl set_user_tags guest monitoring || true
    /etc/init.d/rabbitmq-server stop
}


function start_application {
    exec gosu rabbitmq rabbitmq-server
}

bootstrap
start_application

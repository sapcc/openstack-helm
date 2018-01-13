#!/usr/bin/env bash
set -e

. /container.init/common.sh

function upsert_user {
    rabbitmqctl add_user "$1" "$2" || rabbitmqctl change_password "$1" "$2"
    rabbitmqctl set_permissions "$1" ".*" ".*" ".*"
    [ -z "$3" ] || rabbitmqctl set_user_tags "$1" "$3"
}

function bootstrap {
   #Not especially proud of this, but it works (unlike the environment variable approach in the docs)
   chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

   /etc/init.d/rabbitmq-server start

   rabbitmq-plugins enable rabbitmq_tracing
   rabbitmqctl trace_on

   upsert_user {{ print .Values.global.rabbitmq_default_user .Values.global.user_suffix  | squote }} {{ .Values.global.rabbitmq_default_pass | default ( tuple . .Values.global.rabbitmq_default_user "rabbitmq" | include "svc.password_for_user_and_service" ) | squote }}
   upsert_user {{ print .Values.global.rabbitmq_admin_user .Values.global.user_suffix | squote }} {{ .Values.global.rabbitmq_admin_pass | default ( tuple . .Values.global.rabbitmq_admin_user "rabbitmq" | include "svc.password_for_user_and_service" ) | squote }} administrator
   upsert_user {{ .Values.global.rabbitmq_metrics_user | squote }} {{ .Values.global.rabbitmq_metrics_pass | default ( tuple . .Values.global.rabbitmq_metrics_user "rabbitmq" | include "svc.password_for_user_and_service" ) | squote }} monitoring

   rabbitmqctl change_password guest {{ .Values.global.rabbitmq_default_pass | default ( tuple . "guest" "rabbitmq" | include "svc.password_for_user_and_service" ) | squote }} || true
   rabbitmqctl set_user_tags guest monitoring || true
   /etc/init.d/rabbitmq-server stop
}


function start_application {
   exec rabbitmq-server
}

bootstrap
start_application



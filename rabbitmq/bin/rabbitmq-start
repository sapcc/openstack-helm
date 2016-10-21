#!/usr/bin/env bash
set -e

. /container.init/common.sh

function bootstrap {
   #Not especially proud of this, but it works (unlike the environment variable approach in the docs)
   chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

   /etc/init.d/rabbitmq-server start

   rabbitmq-plugins enable rabbitmq_tracing
   rabbitmqctl trace_on

   rabbitmqctl add_user {{ .Values.global.rabbitmq_default_user }} {{ .Values.global.rabbitmq_default_pass }} || true
   rabbitmqctl set_permissions {{ .Values.global.rabbitmq_default_user }} ".*" ".*" ".*" || true

   rabbitmqctl add_user {{ .Values.global.rabbitmq_admin_user }} {{ .Values.global.rabbitmq_admin_pass }}|| true
   rabbitmqctl set_permissions {{ .Values.global.rabbitmq_admin_user }} ".*" ".*" ".*" || true
   rabbitmqctl set_user_tags {{ .Values.global.rabbitmq_admin_user }} administrator || true

   rabbitmqctl add_user {{ .Values.global.rabbitmq_metrics_user }} {{ .Values.global.rabbitmq_metrics_pass }} || true
   rabbitmqctl set_permissions {{ .Values.global.rabbitmq_metrics_user }} ".*" ".*" ".*" || true
   rabbitmqctl set_user_tags {{ .Values.global.rabbitmq_metrics_user }} monitoring || true

   rabbitmqctl change_password guest  {{ .Values.global.rabbitmq_default_pass }} || true
   rabbitmqctl set_user_tags guest monitoring || true
   /etc/init.d/rabbitmq-server stop
}


function start_application {
   exec rabbitmq-server
}

bootstrap
start_application



{{define "oslo_messaging_rabbit"}}
[oslo_messaging_rabbit]
rabbit_userid = {{ .Values.rabbitmq_user | default .Values.global.rabbitmq_default_user }}
rabbit_password = {{ .Values.rabbitmq_pass | default .Values.global.rabbitmq_default_pass }}
rabbit_hosts =  {{include "rabbitmq_host" .}}
rabbit_ha_queues = {{ .Values.rabbitmq_ha_queues | .Values.global.rabbitmq_ha_queues | default "true" }}
rabbit_transient_queues_ttl={{ .Values.rabbit_transient_queues_ttl | .Values.global.rabbit_transient_queues_ttl | default 1800 }}
{{end}}

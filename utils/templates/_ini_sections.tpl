{{- define "oslo_messaging_rabbit" }}
[oslo_messaging_rabbit]
rabbit_userid = {{ .Values.rabbitmq_user | default .Values.global.rabbitmq_default_user }}
rabbit_password = {{ .Values.rabbitmq_pass | default .Values.global.rabbitmq_default_pass }}
rabbit_hosts =  {{include "rabbitmq_host" .}}
rabbit_ha_queues = {{ .Values.rabbitmq_ha_queues | .Values.global.rabbitmq_ha_queues | default "true" }}
rabbit_transient_queues_ttl={{ .Values.rabbit_transient_queues_ttl | .Values.global.rabbit_transient_queues_ttl | default 1800 }}
{{- end }}

{{- define "ini_sections.database_options" }}
max_pool_size = {{ .Values.max_pool_size | default .Values.global.max_pool_size | default 5 }}
max_overflow = {{ .Values.max_overflow | default .Values.global.max_overflow | default 10 }}
{{- end }}

{{- define "ini_sections.database" }}
[database]
connection = {{ include "db_url" . }}
{{- include "ini_sections.database_options" . }}
{{- end }}

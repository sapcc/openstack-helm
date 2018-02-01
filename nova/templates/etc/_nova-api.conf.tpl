[DEFAULT]
api_paste_config = /etc/nova/api-paste.ini
enabled_apis=osapi_compute,metadata

[api_database]
connection = {{ tuple . .Values.api_db_name .Values.api_db_user .Values.api_db_password | include "db_url" }}
{{- include "ini_sections.database_options" . }}

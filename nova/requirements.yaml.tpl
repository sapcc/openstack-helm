dependencies:
  - name: postgres
    repository: http://localhost:8879/charts
    version: 0.1.0
  - name: utils
    repository: http://localhost:8879/charts
    version: 0.1.1
  - name: pg_metrics
    repository: http://localhost:8879/charts
    version: 0.1.0
{{ if .Values.audit.enabled }}
  - name: rabbitmq-notifications
    repository: http://localhost:8879/charts
    version: 0.0.1
{{ end }}

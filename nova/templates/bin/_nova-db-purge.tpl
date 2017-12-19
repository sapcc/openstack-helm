{{- if .Values.db_purge.enabled }}
#!/bin/bash

{{- if .Values.db_purge.dry_run }}
echo -n "INFO: dry run mode only - "
{{- else }}
echo -n "INFO: "
{{- end }}
echo -n "purging at max {{ .Values.db_purge.max_number }} deleted instances older than {{ .Values.db_purge.older_than }} days from the nova db - "
echo -n `date`
echo -n " - "
{{- if .Values.db_purge.dry_run }}
/var/lib/kolla/venv/bin/nova-manage db purge_deleted_instances --dry-run --older-than {{ .Values.db_purge.older_than }} --max-number {{ .Values.db_purge.max_number }}
{{- else }}
/var/lib/kolla/venv/bin/nova-manage db purge_deleted_instances --older-than {{ .Values.db_purge.older_than }} --max-number {{ .Values.db_purge.max_number }}
{{- end }}
{{- end }}

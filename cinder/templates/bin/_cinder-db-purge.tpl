{{- if .Values.db_purge.enabled }}
#!/bin/bash

echo -n "INFO: purging deleted cinder entities older than {{ .Values.db_purge.older_than }} days from the cinder db - "
date
/var/lib/kolla/venv/bin/cinder-manage db purge {{ .Values.db_purge.older_than }}
{{- end }}

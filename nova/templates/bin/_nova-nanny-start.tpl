{{- if .Values.nanny.enabled }}
#!/bin/bash

function start_application {

  set -e

  unset http_proxy https_proxy all_proxy no_proxy

  echo "INFO: copying nova config files to /etc/nova"
  cp -v /nova-etc/* /etc/nova
  
  # we run an endless loop to run the script periodically
  echo "INFO: starting a loop to periodically run the nany jobs for the nova db"
  while true; do
{{- if .Values.quota_sync.enabled }}
    echo "INFO: sync nova quotas"
    python /nova-db-purge-bin/nova-quota-sync --all --auto_sync
{{- end }}
{{- if .Values.db_purge.enabled }}
    echo "INFO: purge old deleted instances from the nova db"
    . /nova-db-purge-bin/nova-db-purge
    echo "INFO: waiting {{ .Values.nanny.interval }} minutes before starting the next loop run"
{{- end }}
    sleep $(( 60 * {{ .Values.nanny.interval }} ))
  done

}

start_application
{{- end }}

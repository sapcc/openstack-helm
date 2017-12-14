{{- if .Values.nanny.enabled }}
#!/bin/bash

function start_application {

  set -e

  unset http_proxy https_proxy all_proxy no_proxy

  echo "INFO: copying cinder config files to /etc/cinder"
  cp -v /cinder-etc/* /etc/cinder
  
  # we run an endless loop to run the script periodically
  echo "INFO: starting a loop to periodically run the nany jobs for the cinder db"
  while true; do
{{- if .Values.quota_sync.enabled }}
    echo "INFO: sync cinder quotas"
    for i in `python /cinder-db-purge-bin/cinder-quota-sync --config /etc/cinder/cinder.conf --list_projects`; do
      echo project: $i
      python /cinder-db-purge-bin/cinder-quota-sync --config /etc/cinder/cinder.conf --sync --project_id $i
    done
{{- end }}
{{- if .Values.db_purge.enabled }}
    echo "INFO: purge old deleted entities from the cinder db"
    . /cinder-db-purge-bin/cinder-db-purge
{{- end }}
    echo "INFO: waiting {{ .Values.nanny.interval }} minutes before starting the next loop run"
    sleep $(( 60 * {{ .Values.nanny.interval }} ))
  done

}

start_application
{{- end }}

{{- define "volume_configmap" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: volume-{{$volume.name}}
  labels:
    system: openstack
    type: configuration
    component: cinder
data:
  config.json: |
    {"command": "kubernetes-entrypoint",
       "config_files":[
           {"source": "/cinder-etc/cinder.conf", "dest": "/etc/cinder/cinder.conf", "owner": "cinder", "perm": "0400"},
           {"source": "/cinder-etc/policy.json", "dest": "/etc/cinder/policy.json", "owner": "cinder", "perm": "0400"},
           {"source": "/cinder-etc/logging.conf", "dest": "/etc/cinder/logging.conf", "owner": "cinder", "perm": "0400"},
           {"source": "/var/lib/kolla/config_files/volume.conf", "dest": "/etc/cinder/volume.conf", "owner": "cinder", "perm": "0400"}
       ]
    }
  volume.conf: |
{{ tuple . $volume | include "volume_conf" | indent 4 }}
{{- end -}}
{{- end -}}

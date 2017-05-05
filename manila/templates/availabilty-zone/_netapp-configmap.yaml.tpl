{{- define "share_netapp_configmap" -}}
{{- $context := index . 0 -}}
{{- $share := index . 1 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: share-netapp-{{$share.name}}
  labels:
    system: openstack
    type: configuration
    component: manila
data:
  backend.conf: |
{{ tuple $context $share | include "share_netapp_conf" | indent 4 }}
  config.json: |
    {"command": "kubernetes-entrypoint",
       "config_files":[
           {"source": "/var/lib/kolla/config_files/backend.conf", "dest": "/etc/manila/backend.conf", "owner": "manila", "perm": "0400"},
           {"source": "/manila-etc/manila.conf", "dest": "/etc/manila/manila.conf", "owner": "manila", "perm": "0400"},
           {"source": "/manila-etc/policy.json", "dest": "/etc/manila/policy.json", "owner": "manila", "perm": "0400"},
           {"source": "/manila-etc/logging.conf", "dest": "/etc/manila/logging.conf", "owner": "manila", "perm": "0400"}
       ]
    }
{{- end -}}
{{- define "volume_netapp_configmap" -}}
{{- $context := index . 0 -}}
{{- $volume := index . 1 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: volume-netapp-{{$volume.name}}
  labels:
    system: openstack
    type: configuration
    component: cinder


data:
  volume.conf: |
{{ tuple $context $volume | include "volume_netapp_conf" | indent 4 }}

{{- end -}}
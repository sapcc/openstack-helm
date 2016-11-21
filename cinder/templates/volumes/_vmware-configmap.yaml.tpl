{{- define "volume_vmware_configmap" -}}
{{- $context := index . 0 -}}
{{- $volume := index . 1 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: volume-vmware-{{$volume.name}}
  labels:
    system: openstack
    type: configuration
    component: cinder
data:
  volume.conf: |
{{ tuple $context $volume | include "volume_vmware_conf" | indent 4 }}
{{- end -}}
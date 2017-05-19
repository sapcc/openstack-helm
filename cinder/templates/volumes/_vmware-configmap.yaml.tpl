{{- define "volume_vmware_configmap" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}
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
{{ tuple . $volume | include "volume_vmware_conf" | indent 4 }}
{{- end -}}
{{- end -}}

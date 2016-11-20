{{- define "kvm_configmap" -}}
{{- $context := index . 0 -}}
{{- $hypervisor := index . 1 -}}

apiVersion: v1
kind: ConfigMap
metadata:
  name: hypervisor-{{$hypervisor.name}}
  labels:
    system: openstack
    type: configuration
    component: nova


data:
  hypervisor.conf: |
{{ tuple $context $hypervisor | include "kvm_conf" | indent 4 }}
{{- end -}}


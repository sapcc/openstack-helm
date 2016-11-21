{{- define "ml2_vmware_configmap" -}}
{{- $context := index . 0 -}}
{{- $hypervisor := index . 1 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: ml2-vmware-{{$hypervisor.name}}-ini
  labels:
    system: openstack
    type: configuration
    component: neutron
data:
  ml2-vmware.ini: |
{{ tuple $context $hypervisor | include "ml2_vmware_ini" | indent 4 }}
{{- end -}}

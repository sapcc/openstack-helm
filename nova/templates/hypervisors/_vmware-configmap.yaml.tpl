{{- define "vmware_configmap" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
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
{{ tuple . $hypervisor | include "vmware_conf" | indent 4 }}
{{- end }}
{{- end }}

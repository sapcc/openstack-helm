{{- define "kvm_configmap" -}}
{{- $hypervisor := index . 1 -}}
{{- with index . 0 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: hypervisor-{{$hypervisor.name}}
  labels:
    system: openstack
    type: configuration
    component: nova
data:
  nova-compute.conf: |
{{ tuple . $hypervisor | include "kvm_conf" | indent 4 }}
  libvirtd.conf: |
{{ include (print .Template.BasePath "/etc/_libvirtd.conf.tpl") . | indent 4 }}
{{- end -}}
{{- end -}}

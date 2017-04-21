{{- define "f5_configmap" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: neutron-f5-etc-{{$loadbalancer.name}}
  labels:
    system: openstack
    type: configuration
    component: neutron

data:
  f5-oslbaasv2-agent.ini: |
{{ tuple $context $loadbalancer | include "f5_oslbaasv2_agent_ini" | indent 4 }}
  esd.json: |
{{ tuple $context $loadbalancer | include "f5_esd_json" | indent 4 }}

{{- end -}}

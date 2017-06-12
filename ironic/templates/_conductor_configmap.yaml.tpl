{{- define "ironic_conductor_configmap" }}
    {{- $conductor := index . 1 }}
    {{- with index . 0 }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: ironic-conductor-{{$conductor.name}}-etc
  labels:
    system: openstack
    type: configuration
    component: ironic
data:
  ironic-conductor.conf: |
{{ list . $conductor | include "ironic_conductor_conf" | indent 4 }}
  pxe_config.template: |
{{ list . $conductor | include "pxe_config_template" | indent 4 }}
    {{- end }}
{{- end }}

{{- define "ironic_conductor_console_service" }}
    {{- $conductor := index . 1 }}
    {{- with index . 0 }}
kind: Service
apiVersion: v1

metadata:
  name: ironic-conductor-{{$conductor.name}}-console
  labels:
    system: openstack
    type: api
    component: ironic-conductor
spec:
  selector:
    name: ironic-conductor-{{$conductor.name}}
  ports:
    - name: ironic-console
      port: 80
    {{- end }}
{{- end }}

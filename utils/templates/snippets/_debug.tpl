{{ define "debuggable_port" }}
    {{- $override := index . 0 }}
    {{- if $override }}dbg{{ end }}
{{- end }}

{{ define "debug_port_container" }}
    {{- $envAll := index . 0 }}
    {{- $override := index . 1 }}
    {{- $portName := index . 2 }}
    {{- with $envAll }}
        {{- if $override }}
- name: reverse-proxy
  image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/fernet-router:{{.Values.global.fernet_router.image_version}}
  imagePullPolicy: IfNotPresent
  ports:
  - name: {{ $portName }}
    containerPort: 80
  volumeMounts:
  - mountPath: /etc/fernet-router
    name: {{ $portName }}-fernet-router
    readOnly: true
  - mountPath: /fernet-keys
    name: fernet
    readOnly: true
        {{- end }}
    {{- end }}
{{- end }}

{{ define "debug_port_volumes" }}
    {{- $envAll := index . 0 }}
    {{- $override := index . 1 }}
    {{- $portName := index . 2 }}
    {{- with $envAll }}
        {{- if $override }}
- name: {{ $portName }}-fernet-router
  configMap:
    name: {{ $portName }}-fernet-router
    defaultMode: 0444
- name: fernet
  secret:
    secretName: keystone-fernet
    defaultMode: 0444
        {{- end }}
    {{- end }}
{{- end }}


{{ define "debug_port_configmap" }}
    {{- $envAll := index . 0 }}
    {{- $override := index . 1 }}
    {{- $portName := index . 2 }}
    {{- $port := index . 3 }}
    {{- with $envAll }}
        {{- if $override }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $portName }}-fernet-router
  labels:
    system: openstack
    type: config
    component: fernet-router
data:
  local_init.lua: |
    user_overrides = { {{ range $k, $v := $override }}["{{$k}}"] = "{{$v}}",{{ end }} }
    function project_override(project) return user_overrides[project] end
    function default_upstream() return 'http://127.0.0.1:{{$port}}' end
        {{ end }}
    {{- end }}
{{- end }}

{{ define "debug_port_volumes_and_configmap" }}
    {{- $override := index . 1 }}
    {{- if $override }}
{{- . | include "debug_port_volumes" | indent 8 }}
---
{{- . | include "debug_port_configmap" }}
    {{- end }}
{{- end }}


{{ define "utils.snippets.eventlet_backdoor_ini" }}
backdoor_socket=/var/lib/{{.}}/eventlet_backdoor.socket
{{ end }}

{{- define "volume_conf" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}

[DEFAULT]
enabled_backends={{$volume.name}}
storage_availability_zone={{$volume.availability_zone}}

[{{$volume.name}}]
{{range $key, $value := $volume -}}
{{- if and (ne $key "availability_zone") (ne $key "name")}}
{{$key}}={{$value | quote}}
{{- end}}
{{- end -}}
{{- end -}}
{{- end -}}

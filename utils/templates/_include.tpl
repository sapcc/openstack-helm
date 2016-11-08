{{- define "template" -}}
{{- $template := index . 0 -}}
{{- $context := index . 1 -}}
{{- $v := $context.Template.Name | split "/" -}}
{{- $last := sub (len $v) 1 | printf "_%d" | index $v -}}
{{- $wtf := printf "%s%s" ($context.Template.Name | trimSuffix $last) $template -}}
{{ include $wtf $context }}
{{- end -}}

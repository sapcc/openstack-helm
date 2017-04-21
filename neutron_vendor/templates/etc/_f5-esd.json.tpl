{{- define "f5_esd_json" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}

{
  "esd_demo_1": {
    "lbaas_irule": ["_sys_https_redirect"]
  }
}
}

{{- end -}}
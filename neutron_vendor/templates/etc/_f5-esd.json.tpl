{{- define "f5_esd_json" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
{
  "proxy_protocal_2edF_v1_0": {
    "lbaas_irule": ["proxy_protocal_2edF_v1_0"]
  }
}
{{- end -}}
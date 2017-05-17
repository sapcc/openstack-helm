{{- define "f5_esd_json" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
{
  "proxy_protocol_2edF_v1_0": {
    "lbaas_irule": ["proxy_protocol_2edF_v1_0"]
  },
  "standard_tcp_a3de_v1_0": {
    "lbaas_ctcp": "tcp"
  }
}
{{- end -}}
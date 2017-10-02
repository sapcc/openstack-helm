{{- define "f5_esd_json" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
{
  "proxy_protocol_2edF_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "tcp",
    "lbaas_irule": ["proxy_protocol_2edF_v1_0"]
  },
  "standard_tcp_a3de_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "tcp"
  },
  "x_forward_5b6e_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "tcp",
    "lbaas_http": "http_xforward"
  },
  "dev_x": {
    "lbaas_http": "http_xforward"
  },
  "dev_one": {
    "lbaas_one_connect": "cc_oneconnect"
  },
  "dev_compress": {
    "lbaas_http_compression": "cc_httpcompression"
  },
  "dev_nofastl4": {
    "lbaas_fastl4": ""
  }

}
{{- end -}}
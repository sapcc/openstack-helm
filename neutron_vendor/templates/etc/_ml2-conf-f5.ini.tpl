[ml2_f5]
physical_networks = {{- range $i, $loadbalancer := .Values.global.loadbalancers_f5 -}}{{$loadbalancer.physical_network}}{{if lt $i (sub (len $.Values.global.loadbalancers_f5) 1) }},{{ end }} {{- end -}}

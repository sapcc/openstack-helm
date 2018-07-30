{{- range $pool := .Values.bind_pools }}
- name: {{ $pool.name }}
  description: Bind9 Pool
  {{- if $pool.attributes}}
  attributes:
   {{- range $attr := $pool.attributes}}
    {{ $attr.tag }}
   {{- end }}
  {{- end }}
  ns_records:
    {{- range $idx, $srv := $pool.ns_records}}
    - hostname: {{ $srv.hostname }}
      priority: {{ add1 $idx }}
    {{- end}}
  nameservers:
    {{- range $prio, $srv := $pool.nameservers}}
    - host: {{ $srv.ip }}
      port: 53
    {{- end}}
  targets:
    {{- range $idx, $srv := $pool.nameservers}}
    - type: bind9
      description: BIND9 Server {{ add1 $idx }}

      # List out the designate-mdns servers from which BIND servers should
      # request zone transfers (AXFRs) from.
      masters:
        - host: {{ $.Values.global.designate_mdns_external_ip }}
          port: 5354

      # BIND Configuration options
      options:
        host: {{$srv.ip}}
        port: 53
        rndc_host: {{ $srv.ip }}
        rndc_port: {{ $pool.rndc_port }}
        rndc_key_file: {{ $pool.rndc_key_file }}
        clean_zonefile: {{ $pool.clean_zonefile | default "False" }}
    {{- end}}
{{- end }}
{{- range $pool := .Values.akamai_pools }}
- name: {{ $pool.name }}
  description: Akamai Pool
  attributes:
   {{- range $attr := $pool.attributes}}
    {{ $attr.tag }}
   {{- end }}
  ns_records:
    {{- range $idx, $srv := $pool.nameservers}}
    - hostname: {{ $srv.hostname }}
      priority: {{ add1 $idx }}
    {{- end}}
  nameservers:
    {{- range $prio, $srv := $pool.nameservers}}
    - host: {{ $srv.ip }}
      port: 53
    {{- end}}
  {{- if $pool.also_notifies}}
  also_notifies:
    {{- range $i, $notify := $pool.also_notifies}}
    - host: {{ $notify.host }}
      port: {{ $notify.port }}
    {{- end}}
  {{- end}}
  targets:
    - type: akamai
      description: Akamai API

      # List out the designate-mdns servers from which Akamai servers should
      # request zone transfers (AXFRs) from.
      masters:
        - host: {{ $.Values.global.designate_mdns_akamai_ip }}
          port: 53

      # Akamai Configuration options
      options:
        host: {{$pool.options.host}}
        port: {{$pool.options.port}}
        username: {{$pool.options.username}}
        password: {{$pool.options.password}}
        tsig_key_name: "{{$pool.options.tsig_key_name}}"
        tsig_key_secret: "{{$pool.options.tsig_key_secret}}"
        tsig_key_algorithm: "{{$pool.options.tsig_key_algorithm}}"
{{- end }}

log-facility=/var/log/neutron/dnsmasq.log

{{- if .Values.global.ironic_tftp_ip }}
address=/tftpboot/{{.Values.global.ironic_tftp_ip}}
dhcp-boot=pxelinux.0,tftpboot,{{.Values.global.ironic_tftp_ip}}
dhcp-match=set:ipxe,192
{{- end }}

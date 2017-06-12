{{- define "ironic_conductor_conf" -}}
{{- $conductor := index . 1 -}}
{{- with index . 0 -}}
{{- $tftp_ip := $conductor.tftp_ip | default .Values.tftp_ip | default .Values.global.ironic_tftp_ip  }}
[DEFAULT]
enabled_drivers={{ $conductor.enabled_drivers | default "pxe_ipmitool,agent_ipmitool" }}

[conductor]
api_url={{ .Values.global.ironic_api_endpoint_protocol_public}}://{{include "ironic_api_endpoint_host_public" .}}:{{ .Values.global.ironic_api_port_public }}
clean_nodes={{ $conductor.clean_nodes | default "False" }}
automated_clean={{ $conductor.automated_clean | default "False" }}

[deploy]
# We expose this directory over http and tftp
http_root=/tftpboot
http_url=http://{{ $tftp_ip }}:8080

[pxe]
tftp_server={{ $tftp_ip }}
tftp_root=/tftpboot

ipxe_enabled={{ $conductor.ipxe_enabled | default .Values.conductor.ipxe_enabled | default "False" }}

pxe_append_params={{ $conductor.pxe_append_params | default .Values.conductor.pxe_append_params }}
pxe_bootfile_name={{ $conductor.pxe_bootfile_name | default .Values.conductor.pxe_bootfile_name | default "pxelinux.0" }}
pxe_config_template=/etc/ironic/pxe_config.template

uefi_pxe_bootfile_name=ipxe.efi
uefi_pxe_config_template=$pybasedir/drivers/modules/ipxe_config.template
{{- end }}
{{- end -}}

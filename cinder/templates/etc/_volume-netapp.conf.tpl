{{- define "volume_netapp_conf" -}}
{{- $context := index . 0 -}}
{{- $volume := index . 1 -}}

[DEFAULT]
enabled_backends=netapp
storage_availability_zone={{$volume.availability_zone}}

[netapp]
volume_backend_name=netapp
volume_driver=cinder.volume.drivers.netapp.common.NetAppDriver
netapp_transport_type=https
netapp_storage_family = ontap_cluster
netapp_storage_protocol = iscsi
netapp_vserver={{$volume.vserver}}
netapp_server_hostname={{$volume.host}}
netapp_server_port=443
netapp_login={{$volume.username | replace "$" "$$"}}
netapp_password={{$volume.password | replace "$" "$$"}}

{{- end -}}
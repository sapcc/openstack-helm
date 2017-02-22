{{- define "volume_vmware_conf" -}}
{{- $context := index . 0 -}}
{{- $volume := index . 1 -}}

[DEFAULT]
enabled_backends = vmware
storage_availability_zone={{$volume.availability_zone}}

[vmware]
volume_backend_name = vmware
volume_driver=cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver
vmware_host_ip = {{$volume.host}}
vmware_host_username = {{$volume.username | replace "$" "$$"}}
vmware_host_password = {{$volume.password | replace "$" "$$"}}
vmware_insecure=True
{{- end -}}
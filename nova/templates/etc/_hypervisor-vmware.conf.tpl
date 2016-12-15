{{- define "vmware_conf" -}}
{{- $context := index . 0 -}}
{{- $hypervisor := index . 1 -}}
[DEFAULT]
compute_driver=nova.virt.vmwareapi.VMwareVCDriver

[vmware]
insecure = True
integration_bridge = {{$hypervisor.bridge | default "br-int" }}
cache_prefix= {{$hypervisor.name}}-images
host_ip={{$hypervisor.host}}
host_username={{$hypervisor.username}}
host_password={{$hypervisor.password}}
cluster_name={{$hypervisor.cluster_name}}
datastore_regex={{$hypervisor.datastore_regex}}
{{- end -}}

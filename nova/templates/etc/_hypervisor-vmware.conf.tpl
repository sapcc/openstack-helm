{{- define "vmware_conf" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
[DEFAULT]
compute_driver=nova.virt.vmwareapi.VMwareVCDriver
max_concurrent_builds={{$hypervisor.max_concurrent_builds | default .max_concurrent_builds | default 10 }}

[vmware]
insecure = True
integration_bridge = {{$hypervisor.bridge | default "br-int" }}
cache_prefix= "{{$hypervisor.name}}-images"
host_ip= {{$hypervisor.host }}
host_username = {{$hypervisor.username | replace "$" "$$" }}
host_password = {{$hypervisor.password | replace "$" "$$" }}
cluster_name = {{$hypervisor.cluster_name | quote }}
datastore_regex = {{$hypervisor.datastore_regex | quote }}
{{- end }}
{{- end }}

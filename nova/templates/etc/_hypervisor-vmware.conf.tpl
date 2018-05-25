{{- define "vmware_conf" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
[DEFAULT]
compute_driver=nova.virt.vmwareapi.VMwareVCDriver
max_concurrent_builds={{$hypervisor.max_concurrent_builds | default .max_concurrent_builds | default 10 }}
disk_allocation_ratio={{$hypervisor.disk_allocation_ratio | default .disk_allocation_ratio | default 1.0 }}
reserved_host_disk_mb={{$hypervisor.reserved_host_disk_mb | default .reserved_host_disk_mb | default 0 }}
reserved_host_memory_mb={{$hypervisor.reserved_host_memory_mb | default .reserved_host_memory_mb | default 512 }}

# Needs to be same on hypervisor and scheduler
scheduler_tracks_instance_changes = {{ .Values.scheduler.scheduler_tracks_instance_changes }}
scheduler_instance_sync_interval = {{ .Values.scheduler.scheduler_instance_sync_interval }}

[vmware]
insecure = True
integration_bridge = {{$hypervisor.bridge | default "br-int" }}
cache_prefix = "{{$hypervisor.name}}-images"
host_ip = {{$hypervisor.host }}
host_username = {{$hypervisor.username | replace "$" "$$" }}
host_password = {{$hypervisor.password | replace "$" "$$" }}
cluster_name = {{$hypervisor.cluster_name | quote }}
{{- if $hypervisor.pbm_default_policy }}
pbm_enabled = True
pbm_default_policy = $hypervisor.pbm_default_policy
{{- else }}
datastore_regex = {{$hypervisor.datastore_regex | quote }}
{{- end }}
use_linked_clone = {{$hypervisor.use_linked_clone | default "false" }}

{{- end }}
{{- end }}

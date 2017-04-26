{{- define "kvm_conf" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
[DEFAULT]
compute_driver = libvirt.LibvirtDriver
resume_guests_state_on_host_boot=True
max_concurrent_builds={{$hypervisor.max_concurrent_builds | default .max_concurrent_builds | default 10 }}
disk_allocation_ratio={{$hypervisor.disk_allocation_ratio | default .disk_allocation_ratio | default 1.0 }}
reserved_host_disk_mb={{$hypervisor.reserved_host_disk_mb | default .reserved_host_disk_mb | default 0 }}
reserved_host_memory_mb={{$hypervisor.reserved_host_memory_mb | default .reserved_host_memory_mb | default 512 }}

{{- end }}
{{- end }}

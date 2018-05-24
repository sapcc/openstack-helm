{{- define "kvm_conf" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
[DEFAULT]
compute_driver = libvirt.LibvirtDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
resume_guests_state_on_host_boot=True
max_concurrent_builds={{$hypervisor.max_concurrent_builds | default .max_concurrent_builds | default 10 }}
disk_allocation_ratio={{$hypervisor.disk_allocation_ratio | default .disk_allocation_ratio | default 1.0 }}
reserved_host_disk_mb={{$hypervisor.reserved_host_disk_mb | default .reserved_host_disk_mb | default 0 }}
reserved_host_memory_mb={{$hypervisor.reserved_host_memory_mb | default .reserved_host_memory_mb | default 512 }}

[libvirt]
connection_uri = "qemu+tcp://127.0.0.1/system"
iscsi_use_multipath=True
#inject_key=True
#inject_password = True
#live_migration_downtime = 500
#live_migration_downtime_steps = 10
#live_migration_downtime_delay = 75
#live_migration_flag = VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER, VIR_MIGRATE_LIVE, VIR_MIGRATE_TUNNELLED

{{- end }}
{{- end }}

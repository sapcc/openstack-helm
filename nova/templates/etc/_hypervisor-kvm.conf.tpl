{{- define "kvm_conf" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
[DEFAULT]
compute_driver = libvirt.LibvirtDriver
resume_guests_state_on_host_boot=True
max_concurrent_builds={{$hypervisor.max_concurrent_builds | default .max_concurrent_builds | default 10 }}
{{- end }}
{{- end }}

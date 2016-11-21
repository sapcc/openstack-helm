{{- define "kvm_conf" -}}
{{- $context := index . 0 -}}
{{- $hypervisor := index . 1 -}}
[DEFAULT]
compute_driver = libvirt.LibvirtDriver
resume_guests_state_on_host_boot=True
{{- end -}}

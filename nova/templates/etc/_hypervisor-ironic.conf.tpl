{{- define "ironic_conf" -}}
{{- $context := index . 0 -}}
{{- $hypervisor := index . 1 -}}

[DEFAULT]
compute_driver=nova.virt.ironic.IronicDriver

#compute_manager=ironic.nova.compute.manager.ClusteredComputeManager

scheduler_use_baremetal_filters=True
scheduler_tracks_instance_changes=False
{{- end -}}

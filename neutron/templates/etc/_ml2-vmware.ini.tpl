{{- define "ml2_vmware_ini" -}}
{{- $context := index . 0 -}}
{{- $hypervisor := index . 1 -}}
# Defines configuration options specific for VMWare DVS ML2 Mechanism driver

[securitygroup]
firewall_driver = {{$hypervisor.firewall}}

[ml2_vmware]
# Hostname or ip address of vmware vcenter server
vsphere_hostname={{$hypervisor.host}}
cluster_name={{$hypervisor.cluster_name}}

# Login username and password of vcenter server
vsphere_login={{$hypervisor.username}}
vsphere_password={{$hypervisor.password}}

# sleep time in seconds for polling an on-going async task as part of the
# API cal
# task_poll_interval=5.0

# number of times an API must be retried upon session/connection related errors
# api_retry_count=10

# The mappings between local physical network device and distributed vswitch
network_maps = {{$hypervisor.network_maps | default "default:openstack" }}
{{- end -}}

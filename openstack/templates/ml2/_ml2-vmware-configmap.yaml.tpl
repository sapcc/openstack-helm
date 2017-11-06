{{- define "ml2_vmware_configmap" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: ml2-vmware-{{.name}}-ini
  labels:
    system: openstack
    type: configuration
    component: neutron
data:
  ml2-vmware.ini: |
    # Defines configuration options specific for VMWare DVS ML2 Mechanism driver

    [securitygroup]
    firewall_driver = {{.firewall}}

    [ml2_vmware]
    # Hostname or ip address of vmware vcenter server
    vsphere_hostname={{.host}}
    cluster_name={{.cluster_name}}

    # Login username and password of vcenter server
    vsphere_login={{.username | replace "$" "$$"}}
    vsphere_password={{.password | replace "$" "$$"}}

    # sleep time in seconds for polling an on-going async task as part of the
    # API cal
    # task_poll_interval=5.0

    # number of times an API must be retried upon session/connection related errors
    # api_retry_count=10

    # The mappings between local physical network device and distributed vswitch
    network_maps = {{.network_maps | default "default:openstack" }}
{{- end }}

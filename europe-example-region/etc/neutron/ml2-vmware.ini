# Defines configuration options specific for VMWare DVS ML2 Mechanism driver

[securitygroup]
firewall_driver = networking_dvs.plugins.ml2.drivers.mech_dvs.agent.dvs_firewall.DvsSecurityGroupsDriver


[ml2_vmware]
# Hostname or ip address of vmware vcenter server
host_ip={{.Values.openstack.nova.vmware_host}}
vsphere_hostname={{.Values.openstack.nova.vmware_host}}


# Login username and password of vcenter server
host_username={{.Values.openstack.nova.vmware_username}}
vsphere_login={{.Values.openstack.nova.vmware_username}}

host_password={{.Values.openstack.nova.vmware_password}}
vsphere_password={{.Values.openstack.nova.vmware_password}}

# The wsdl file directory to create vSphere SDK Session
# wsdl_location=<url of vSphere SDK wsdl file>
wsdl_location=https://{{.Values.openstack.nova.vmware_host}}/sdk/vimService.wsdl
# Example: wsdl_location=file:///opt/vmware/vim.wsdl

# sleep time in seconds for polling an on-going async task as part of the
# API cal
# task_poll_interval=5.0

# number of times an API must be retried upon session/connection related errors
# api_retry_count=10

# The mappings between local physical network device and distributed vswitch
network_maps = default:openstack

dv_switch = openstack
dv_portgroup = br-int

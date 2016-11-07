[DEFAULT]
compute_driver=nova.virt.vmwareapi.VMwareVCDriver

[vmware]
insecure = True
integration_bridge = br-int
cache_prefix= vmware-images
host_ip={{.Values.openstack.nova.vmware_host}}
host_username={{.Values.openstack.nova.vmware_username}}
host_password={{.Values.openstack.nova.vmware_password}}
cluster_name={{.Values.openstack.nova.vmware_cluster_name}}
datastore_regex={{.Values.openstack.nova.vmware_datastore_regex}}

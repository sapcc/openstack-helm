[DEFAULT]

f5_device_type = external

f5_ha_type = standalone

f5_sync_mode = autosync

#f5_bigip_lbaas_device_driver=f5.oslbaasv1agent.drivers.bigip.icontrol_driver.iControlDriver

f5_bigip_lbaas_device_driver= f5_openstack_agent.lbaasv2.drivers.bigip.icontrol_driver.iControlDriver

f5_global_routed_mode= False

icontrol_hostname = {{.Values.f5_icontrol_hostname}}
icontrol_username = {{.Values.f5_icontrol_username}}
icontrol_password = {{ .Values.f5_icontrol_password}}
icontrol_config_mode = objects

###############################################################################
# Certificate Manager
###############################################################################
cert_manager = f5_openstack_agent.lbaasv2.drivers.bigip.barbican_cert.BarbicanCertManager
#
# Two authentication modes are supported for BarbicanCertManager:
#   keystone_v2, and keystone_v3
#
#
# Keystone v2 authentication:
#
# auth_version = v2
# os_auth_url = http://localhost:5000/v2.0
# os_username = admin
# os_password = changeme
# os_tenant_name = admin
#
#
# Keystone v3 authentication:
#

auth_version = v3
os_auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal }}/v3
os_username = {{ .Values.global.neutron_service_user }}
os_password = {{ .Values.global.neutron_service_password }}
os_user_domain_name = {{.Values.global.keystone_service_domain}}
os_project_name = {{.Values.global.keystone_service_project}}
os_project_domain_name = {{.Values.global.keystone_service_domain}}
insecure = True



[ml2_f5]

physical_networks = {{.Values.f5_physnet}}

[ml2]

# Changing type_drivers after bootstrap can lead to database inconsistencies
type_drivers = vlan,vxlan
tenant_network_types = vxlan,vlan


#mechanism_drivers = aci,dvs,openvswitch,arista,asr,manila,f5ml2

mechanism_drivers = {{.Values.ml2_mechanismdrivers}}

# Designate configuration
extension_drivers = {{.Values.dns_ml2_extension}}

path_mtu = {{.Values.global.default_mtu}}

[ml2_type_vlan]
network_vlan_ranges = lab-cfm:2980:2999

[ml2_type_vxlan]
vni_ranges = 10000:20000


[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_security_group=True
enable_ipset=True

[agent]
polling_interval=5
prevent_arp_spoofing = False


[ovs]
bridge_mappings = {{.Values.cp_physical_network}}:br-{{.Values.cp_network_interface}}
enable_tunneling=False





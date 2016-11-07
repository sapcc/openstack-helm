dhcp-option-force=26,1450
log-facility=/var/log/neutron/dnsmasq.log


address=/{{.Values.global.ironic_pxe_endpoint_host_public}}/{{.Values.global.ironic_pxe_endpoint_ip_public}}

dhcp-boot=pxelinux.0,{{.Values.global.ironic_pxe_endpoint_host_public}},{{.Values.global.ironic_pxe_endpoint_ip_public}}
dhcp-match=set:ipxe,192


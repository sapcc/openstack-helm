w#!/usr/bin/env bash

set -e

. /container.init/common.sh



function process_config {
    #TODO Fix or understand upstream
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/networking_cisco/db/migration/alembic_migrations/versions/liberty/contract/53f08de0523f_neutron_routers_in_cisco_devices.py /cisco-patches/53f08de0523f-neutron-routers-in-cisco-devices.diff
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/networking_cisco/plugins/cisco/l3/schedulers/l3_router_hosting_device_scheduler.py /cisco-patches/l3-router-hosting-device-scheduler.diff
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/networking_cisco/plugins/cisco/device_manager/plugging_drivers/hw_vlan_trunking_driver.py /cisco-patches/hw-vlan-trunking-driver.diff
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/networking_cisco/plugins/cisco/db/device_manager/hosting_device_manager_db.py /cisco-patches/hosting-device-manager-db.diff

    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/f5lbaasdriver/v2/bigip/service_builder.py /f5-patches/service-builder.diff
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/neutron/plugins/ml2/extensions/dns_integration.py /neutron-patches/dns-integration.diff
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/neutron/db/ipam_backend_mixin.py /neutron-patches/ipam-backend-mixin.diff
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/neutron_lbaas/db/loadbalancer/loadbalancer_dbv2.py /neutron-patches/loadbalancer-dbv2.diff


    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/neutron-lbaas.conf /etc/neutron/neutron_lbaas.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini

    cp /neutron-etc-region/ml2-conf-aci.ini  /etc/neutron/plugins/ml2/ml2-conf-aci.ini

    cp /neutron-etc-vendor/ml2-conf-arista.ini  /etc/neutron/plugins/ml2/ml2_conf_arista.ini
    cp /neutron-etc-vendor/ml2-conf-manila.ini  /etc/neutron/plugins/ml2/ml2_conf_manila.ini
    cp /neutron-etc-vendor/ml2-conf-asr.ini  /etc/neutron/plugins/ml2/ml2_conf_asr.ini
    cp /neutron-etc-vendor/ml2-conf-f5.ini  /etc/neutron/plugins/ml2/ml2_conf_f5.ini

    cp /neutron-etc/neutron-policy.json  /etc/neutron/policy.json

    mkdir /etc/neutron/plugins/cisco

    cp /neutron-etc-vendor/cisco-device-manager-plugin.ini   /etc/neutron/plugins/cisco/cisco_device_manager_plugin.ini
    cp /neutron-etc-vendor/cisco-router-plugin.ini   /etc/neutron/plugins/cisco/cisco_router_plugin.ini
}

function _start_application {
    /var/lib/kolla/venv/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/neutron_lbaas.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini  --config-file /etc/neutron/plugins/ml2/ml2_conf_f5.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-aci.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_asr.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_manila.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_arista.ini --config-file /etc/neutron/plugins/cisco/cisco_device_manager_plugin.ini --config-file /etc/neutron/plugins/cisco/cisco_router_plugin.ini
}

process_config
start_application

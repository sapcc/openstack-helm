#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    #TODO Fix or understand upstream

    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/networking_cisco/plugins/cisco/cfg_agent/device_status.py /cisco-patches/device-status.diff
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/networking_cisco/plugins/cisco/l3/schedulers/l3_router_hosting_device_scheduler.py /cisco-patches/l3-router-hosting-device-scheduler.diff
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/networking_cisco/plugins/cisco/device_manager/plugging_drivers/hw_vlan_trunking_driver.py /cisco-patches/hw-vlan-trunking-driver.diff
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/networking_cisco/plugins/cisco/db/device_manager/hosting_device_manager_db.py /cisco-patches/hosting-device-manager-db.diff

    cp /neutron-etc/neutron.conf /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf /etc/neutron/logging.conf

    mkdir /etc/neutron/plugins/cisco
    cp /neutron-etc/cisco-cfg-agent.ini /etc/neutron/plugins/cisco/cisco_cfg_agent.ini
}



function _start_application {
    mkdir /var/log/neutron

    exec /var/lib/kolla/venv/bin/neutron-cisco-cfg-agent --config-file /etc/neutron/plugins/cisco/cisco_cfg_agent.ini --config-file /etc/neutron/neutron.conf --log-file /var/log/neutron/cisco-cfg-agent.log

}


process_config
start_application



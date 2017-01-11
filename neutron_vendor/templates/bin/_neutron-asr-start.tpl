#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    cp /neutron-etc/neutron.conf /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf /etc/neutron/logging.conf

    mkdir /etc/neutron/plugins/cisco
    cp /neutron-etc-vendor/cisco-cfg-agent.ini /etc/neutron/plugins/cisco/cisco_cfg_agent.ini
}



function _start_application {
    mkdir /var/log/neutron

    exec /var/lib/kolla/venv/bin/neutron-cisco-cfg-agent --config-file /etc/neutron/plugins/cisco/cisco_cfg_agent.ini --config-file /etc/neutron/neutron.conf --log-file /var/log/neutron/cisco-cfg-agent.log
}


process_config
start_application



#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini
    cp /neutron-etc/metadata-agent.ini  /etc/neutron/metadata_agent.ini
}


function start_application {
    mkdir /var/log/neutron
    exec  neutron-metadata-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/metadata_agent.ini
}


process_config

start_application



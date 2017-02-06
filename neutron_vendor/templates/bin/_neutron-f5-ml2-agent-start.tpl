#!/usr/bin/env bash

set -e

. /container.init/common.sh


function process_config {
    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini
    cp /neutron-etc-vendor/ml2-conf-f5.ini  /etc/neutron/plugins/ml2/ml2_conf_f5.ini
}



function _start_application {
    exec /var/lib/kolla/venv/bin/neutron-f5-ml2-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_f5.ini
}



process_config

start_application



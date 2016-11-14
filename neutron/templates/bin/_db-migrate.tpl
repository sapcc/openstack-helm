#!/usr/bin/env bash

set -e

. /container.init/common.sh



function process_config {
    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/neutron-lbaas.conf /etc/neutron/neutron_lbaas.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini


}

process_config
neutron-db-manage upgrade head
neutron-db-manage --subproject neutron-lbaas upgrade head
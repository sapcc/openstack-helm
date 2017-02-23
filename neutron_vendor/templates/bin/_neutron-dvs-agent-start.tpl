#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini
    cp /ml2-conf-vmware/ml2-vmware.ini  /etc/neutron/plugins/ml2/ml2-vmware.ini

    apply_patches # Apply hot-fixes, which need to be either upstreamed or moved to the container build
}

function _start_application {
    exec /var/lib/kolla/venv/bin/neutron-dvs-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini --config-file /etc/neutron/plugins/ml2/ml2-vmware.ini
}

export PYTHONWARNINGS="ignore:Unverified HTTPS request"

process_config
start_application

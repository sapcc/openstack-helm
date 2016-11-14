#!/usr/bin/env bash

set -e

. /container.init/common.sh



function process_config {
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/networking_cisco/db/migration/alembic_migrations/versions/liberty/contract/53f08de0523f_neutron_routers_in_cisco_devices.py /cisco-patches/53f08de0523f-neutron-routers-in-cisco-devices.diff

    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/neutron-lbaas.conf /etc/neutron/neutron_lbaas.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini


}

process_config
neutron-db-manage upgrade head
neutron-db-manage --subproject neutron-lbaas upgrade head
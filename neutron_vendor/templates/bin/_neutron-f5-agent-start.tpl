#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    patch /var/lib/kolla/venv/local/lib/python2.7/site-packages/f5/bigip/__init__.py /f5-patches/bigip-init.diff
    patch /usr/local/lib/python2.7/dist-packages/requests/sessions.py /f5-patches/sessions.diff

    mkdir /etc/neutron/esd

    cp /neutron-etc/neutron.conf /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/neutron-lbaas.conf /etc/neutron/neutron_lbaas.conf
    cp /f5-etc/f5-oslbaasv2-agent.ini /etc/neutron/f5-oslbaasv2-agent.ini
    cp /f5-etc/esd.json /etc/neutron/esd/esd.json
}



function _start_application {
    mkdir /var/log/neutron


    exec  python /var/lib/kolla/venv/bin/f5-oslbaasv2-agent --config-file /etc/neutron/f5-oslbaasv2-agent.ini --config-file /etc/neutron/neutron.conf --log-file /var/log/neutron/f5-agent.log

}

process_config

start_application



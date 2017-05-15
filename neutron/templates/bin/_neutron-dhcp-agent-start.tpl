#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini
    cp /neutron-etc/dhcp-agent.ini  /etc/neutron/dhcp_agent.ini
    cp /neutron-etc/dnsmasq.conf  /etc/neutron/dnsmasq.conf
}


function start_application {
    mkdir /var/log/neutron

    echo "$MY_IP $(hostname)" >> etc/hosts

    echo "Existing NETNS"
    ip netns

    # Ensure netns is clean
    for x in `ip netns | grep qdhcp`; do ip netns del $x; done

    # fifteen second check for br-int to come up
    timeout=$(($(date +%s) + 15))

    until ovs-vsctl br-exists br-int || [[ $(date +%s) -gt $timeout ]]; do
      echo "Waiting for br-int"
      sleep 1
    done

    # br-int interface isn't there, lets crash and try again - we have situation where this intermittently can happen
    # We can't start DHCP without it otherwise we lose teh DHCP ports. Kill all the ovs processes on the host to get a full
    # OVS restart which should make things better....

    ip a | grep br-int; rc=$?

    if [[ $rc != 0 ]]; then
        pkill -f ovs
        exit 1
    fi


    exec neutron-dhcp-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/dhcp_agent.ini
}


process_config

start_application

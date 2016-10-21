#!/usr/bin/env bash

. /container.init/common.sh



function prepare_ovs {


    ovs_version=$(ovs-vsctl -V | grep ovs-vsctl | awk '{print $4}')
    ovs_db_version=$(ovsdb-tool schema-version /usr/share/openvswitch/vswitch.ovsschema)

    # begin configuring

    ovs-vsctl --no-wait -- init
    ovs-vsctl --no-wait -- set Open_vSwitch . db-version="${ovs_db_version}"
    ovs-vsctl --no-wait -- set Open_vSwitch . ovs-version="${ovs_version}"
    ovs-vsctl --no-wait -- set Open_vSwitch . system-type="docker-ovs"
    ovs-vsctl --no-wait -- set Open_vSwitch . system-version="0.1"
    ovs-vsctl --no-wait -- set Open_vSwitch . external-ids:system-id=`cat /proc/sys/kernel/random/uuid`
    ovs-vsctl --no-wait -- set-manager ptcp:6640
    ovs-appctl -t ovsdb-server ovsdb-server/add-remote db:Open_vSwitch,Open_vSwitch,manager_options



}


function _start_application {
    if command -v dumb-init >/dev/null 2>&1; then
        exec  dumb-init /usr/sbin/ovs-vswitchd unix:/var/run/openvswitch/db.sock -vconsole:emer -vsyslog:info -vfile:info --mlockall
    else
        exec  /usr/sbin/ovs-vswitchd unix:/var/run/openvswitch/db.sock -vconsole:emer -vsyslog:info -vfile:info --mlockall
    fi
}

prepare_ovs

start_application




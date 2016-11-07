#!/usr/bin/env bash


. /container.init/common.sh



function prepare_system {

    modprobe -r openvswitch

    modprobe openvswitch

    mkdir -p "/var/run/openvswitch"

    rm -rf /etc/openvswitch/conf.db
    ovsdb-tool create "/etc/openvswitch/conf.db"
}





function _start_application {

    if command -v dumb-init >/dev/null 2>&1; then
        exec dumb-init /usr/sbin/ovsdb-server /etc/openvswitch/conf.db -vconsole:emer -vsyslog:err -vfile:info --remote=punix:/var/run/openvswitch/db.sock --pidfile=/var/run/openvswitch/ovsdb-server.pid
    else
        exec /usr/sbin/ovsdb-server /etc/openvswitch/conf.db -vconsole:emer -vsyslog:err -vfile:info --remote=punix:/var/run/openvswitch/db.sock --pidfile=/var/run/openvswitch/ovsdb-server.pid
    fi

}

prepare_system

start_application


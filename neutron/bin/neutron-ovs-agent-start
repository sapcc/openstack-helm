#!/usr/bin/env bash


. /container.init/common.sh

function process_config {
    cp /neutron-etc/neutron.conf  /etc/neutron/neutron.conf
    cp /neutron-etc/logging.conf  /etc/neutron/logging.conf
    cp /neutron-etc/ml2-conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini
}


function configure_bridge {

    interfaces=( {{.Values.cp_network_interface}} )

    for interface in "${interfaces[@]}"
    do

        # Create the bridge and port on OVS, delete first and create ports for non internal bridges

        ovs-vsctl br-exists br-${interface}; rc=$?

        if [[ $rc == 0 ]]; then
            ovs-vsctl --no-wait del-br br-${interface}
        fi

        ovs-vsctl --no-wait add-br br-${interface}; rc=$?

        if [[ $rc != 0 ]]; then
          echo "Failed to create OVS bridge br-${interface} - exiting"
          exit $rc
        fi

        if [[ ! $interface == 'int' ]]
        then
            if [[ ! $(ovs-vsctl list-ports br-${interface}) =~ $(echo "\<${interface}\>") ]]; then
                ovs-vsctl --no-wait add-port br-${interface} ${interface}; rc=$?

                if [[ $rc != 0 ]]; then
                  echo "Failed to create OVS port ${interface} on bridge br-${interface} - exiting"
                  exit $rc
                fi
            fi
        fi

        ovs-vsctl br-exists br-${interface}; rc=$?

        if [[ $rc != 0 ]]; then
            echo "Failed to create bridge configuration"
            exit 1
        fi


    done


}



function _start_application {

    exec  neutron-openvswitch-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini
}


process_config

configure_bridge

start_application



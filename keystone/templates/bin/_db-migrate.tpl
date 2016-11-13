#!/usr/bin/env bash

set -e

. /container.init/common.sh



function process_config {
    cp /keystone-etc/keystone.conf  /etc/keystone/keystone.conf
    cp /keystone-etc/policyv3.json  /etc/keystone/policy.json

}

process_config
keystone-manage db_sync

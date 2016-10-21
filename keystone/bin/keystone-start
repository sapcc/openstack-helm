#!/usr/bin/env bash

set -e

. /container.init/common.sh

function process_config {
    cp /keystone-etc/keystone.conf  /etc/keystone/keystone.conf
    cp /keystone-etc/wsgi-keystone.conf /etc/apache2/conf-enabled/wsgi-keystone.conf
    cp /keystone-etc/policyv3.json  /etc/keystone/policy.json
    cp /container.init/keystone-bootstrap /kube.init
    chmod +x /kube.init/keystone-bootstrap
}

function _start_application {
    source /etc/apache2/envvars
    exec /usr/sbin/apache2 -DFOREGROUND
}

process_config
start_application



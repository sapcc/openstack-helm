#!/usr/bin/env bash

. /container.init/common.sh

URL_BASE=http://localhost:{{.Values.global.keystone_api_port_admin}}

echo "Waiting for keystone application.."

n=1
m=12
until [ $n -ge $m ]
do
    curl $URL_BASE > /dev/null 2>&1  && break
    echo "Attempt $n of $m waiting 10 seconds to retry"
    n=$[$n+1]
    sleep 10
done

if [ $n -eq $m ]
then
    echo "Keystone not available within 120 seconds"
    exit 1
fi

# seed just enough to have a functional v3 api
export OS_BOOTSTRAP_USER={{.Values.bootstrap_user}}
export OS_BOOTSTRAP_PASSWORD={{.Values.bootstrap_password}}
export OS_BOOTSTRAP_REGION_ID={{.Values.global.region}}
export OS_BOOTSTRAP_ADMIN_URL={{.Values.global.keystone_api_endpoint_protocol_admin_ext}}://{{include "keystone_api_endpoint_host_admin_ext" .}}:{{.Values.global.keystone_api_port_admin_ext}}/v3
export OS_BOOTSTRAP_PUBLIC_URL={{.Values.global.keystone_api_endpoint_protocol_public}}://{{include "keystone_api_endpoint_host_public" .}}:{{.Values.global.keystone_api_port_public}}/v3
export OS_BOOTSTRAP_INTERNAL_URL={{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{.Values.global.keystone_api_port_internal}}/v3
keystone-manage-extension --config-file /etc/keystone/keystone.conf bootstrap


#!/usr/bin/env bash

. /container.init/common.sh

cp /keystone-etc/keystone.conf  /etc/keystone/keystone.conf

# seed just enough to have a functional v3 api
export OS_BOOTSTRAP_USER={{.Values.bootstrap_user}}
export OS_BOOTSTRAP_PASSWORD={{.Values.bootstrap_password}}
export OS_BOOTSTRAP_REGION_ID={{.Values.global.region}}
export OS_BOOTSTRAP_ADMIN_URL={{.Values.global.keystone_api_endpoint_protocol_admin_ext}}://{{include "keystone_api_endpoint_host_admin_ext" .}}:{{.Values.global.keystone_api_port_admin_ext}}/v3
export OS_BOOTSTRAP_PUBLIC_URL={{.Values.global.keystone_api_endpoint_protocol_public}}://{{include "keystone_api_endpoint_host_public" .}}:{{.Values.global.keystone_api_port_public}}/v3
export OS_BOOTSTRAP_INTERNAL_URL={{.Values.global.keystone_api_endpoint_protocol_internal}}://{{include "keystone_api_endpoint_host_internal" .}}:{{.Values.global.keystone_api_port_internal}}/v3
keystone-manage-extension --config-file /etc/keystone/keystone.conf bootstrap


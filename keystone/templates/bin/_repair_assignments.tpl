#!/usr/bin/env bash

. /container.init/common.sh

cp /keystone-etc/keystone.conf  /etc/keystone/keystone.conf

set -ex

date

# repair any role-assignments that point to orphaned objects (usually users that have been deactivated in CAM)
keystone-manage-extension --config-file=/etc/keystone/keystone.conf repair_assignments

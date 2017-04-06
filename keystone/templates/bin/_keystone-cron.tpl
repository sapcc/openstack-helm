#!/usr/bin/env bash

set -ex

export STDOUT=${STDOUT:-/proc/1/fd/1}
export STDERR=${STDERR:-/proc/1/fd/2}

cat <(crontab -l) <(echo "{{ default "0 * * * *"  .Values.cron_schedule }} . /container.init/repair_assignments > ${STDOUT} 2> ${STDERR}") | crontab -

exec cron -f



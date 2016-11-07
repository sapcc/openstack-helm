{{define "common.sh"}}
#!/usr/bin/env bash


function start_application {

if [ "$DEBUG_CONTAINER" = "true" ]
then
    tail -f /dev/null
else
    _start_application
fi

}


export MY_IP=$(ip route get 1 | awk '{print $NF;exit}')


{{end}}
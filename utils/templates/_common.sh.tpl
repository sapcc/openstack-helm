{{define "common.sh"}}
#!/usr/bin/env bash

function apply_patches {
    cwd=`pwd`
    cd /var/lib/kolla/venv/local/lib/python2.7/site-packages
    for d in /*-patches; do
        [ ! -d "$d" ] && continue
        for p in "$d"/*.patch; do
            [ ! -f "$p" ] && continue
            f=$(grep -o -m1 '^--- [A-Za-z0-9\-_/.]*'  "$p" | cut -c7- )
            [ ! -f "$f" ] && continue
            patch -p1 < $p
        done
    done
    cd $cwd
}

function start_application {

if [ "$DEBUG_CONTAINER" = "true" ]
then
    exec tail -f /dev/null
else
    _start_application
fi

}


export MY_IP=$(ip route get 1 | awk '{print $NF;exit}')


{{end}}

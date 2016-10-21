Listen {{ .Values.global.keystone_api_port_internal }}
Listen {{ .Values.global.keystone_api_port_admin }}

<VirtualHost *:{{ .Values.global.keystone_api_port_internal }}>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP} python-path=/usr/lib/python2.7/site-packages
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /var/www/cgi-bin/keystone/main
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M \"%{X-Openstack-Request-Id}i\" \"%{X-Auth-Token}i\" \"%{X-Subject-Token}i\""
    </IfVersion>
    ErrorLog /proc/self/fd/1
    CustomLog /proc/self/fd/1 "%h %t \"%r\" %>s %O %D %X \"%{Referer}i\" \"%{User-Agent}i\" \"%{X-Openstack-Request-Id}i\" \"%{X-Auth-Token}i\" \"%{X-Subject-Token}i\""
</VirtualHost>

<VirtualHost *:{{ .Values.global.keystone_api_port_admin }}>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP} python-path=/usr/lib/python2.7/site-packages
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /var/www/cgi-bin/keystone/admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M \"%{X-Openstack-Request-Id}i\" \"%{X-Auth-Token}i\" \"%{X-Subject-Token}i\""
    </IfVersion>
    ErrorLog /proc/self/fd/1
    CustomLog /proc/self/fd/1 "%h %t \"%r\" %>s %O %D %X \"%{Referer}i\" \"%{User-Agent}i\" \"%{X-Openstack-Request-Id}i\" \"%{X-Auth-Token}i\" \"%{X-Subject-Token}i\""
</VirtualHost>

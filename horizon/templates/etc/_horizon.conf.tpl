Listen *:{{.Values.global.horizon_endpoint_port}}

<VirtualHost *:{{.Values.global.horizon_endpoint_port}}>
    LogLevel warn
    ErrorLog /proc/self/fd/1
    CustomLog /proc/self/fd/1 combined

    WSGIScriptReloading On
    WSGIDaemonProcess horizon-http processes=5 threads=10 deadlock-timeout=60 maximum-requests=1000 user=horizon group=horizon display-name=%{GROUP} python-path=/var/lib/kolla/venv/lib/python2.7/site-packages
    WSGIProcessGroup horizon-http
    WSGIScriptAlias / /var/lib/kolla/venv/lib/python2.7/site-packages/openstack_dashboard/wsgi/django.wsgi
    WSGIPassAuthorization On

    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^http:\//\/?(.*) https://%{HTTP_HOST}/$1 [R,L]

    <Location "/">
        Require all granted
    </Location>

    Alias /static /var/lib/kolla/venv/lib/python2.7/site-packages/static
    <Location "/static">
        SetHandler None
    </Location>
</Virtualhost>

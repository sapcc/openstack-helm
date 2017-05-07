{{- define "ironic_configmap" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: hypervisor-{{$hypervisor.name}}
  labels:
    system: openstack
    type: configuration
    component: nova
data:
  hypervisor.conf: |
{{ tuple . $hypervisor | include "ironic_conf" | indent 4 }}
  config.json: |
    {"command": "kubernetes-entrypoint",
       "config_files":[
           {"source": "/var/lib/kolla/config_files/hypervisor.conf", "dest": "/etc/nova/hypervisor.conf", "owner": "nova", "perm": "0400"},
           {"source": "/nova-etc/nova.conf", "dest": "/etc/nova/nova.conf", "owner": "nova", "perm": "0400"},
           {"source": "/nova-etc/policy.json", "dest": "/etc/nova/policy.json", "owner": "nova", "perm": "0400"},
           {"source": "/nova-etc/logging.conf", "dest": "/etc/nova/logging.conf", "owner": "nova", "perm": "0400"}
       ]
    }

{{- end }}
{{- end }}

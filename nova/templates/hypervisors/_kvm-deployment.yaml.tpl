{{- define "kvm_hypervisor" -}}
{{- $context := index . 0 -}}
{{- $hypervisor := index . 1 -}}

kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: nova-compute-{{$hypervisor.name}}
  labels:
    system: openstack
    type: backend
    component: nova
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      name: nova-compute-{{$hypervisor.name}}
  template:
    metadata:
      labels:
        name: nova-compute-{{$hypervisor.name}}
      annotations:
        scheduler.alpha.kubernetes.io/tolerations: '[{"key":"species","value":"hypervisor"}]'
    spec:
      hostNetwork: true
      hostPID: true
      hostIPC: true
      nodeSelector:
        kubernetes.io/hostname: {{$hypervisor.node_name}}
      containers:
        - name: nova-compute-minion1
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-nova-compute-m3:{{$context.Values.image_version_nova_compute_m3}}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/nova-compute-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
            - name: SENTRY_DSN
              value: {{include "sentry_dsn_nova" $context}}
          volumeMounts:
            - mountPath: /var/lib/nova/instances
              name: instances
            - mountPath: /var/lib/libvirt
              name: libvirt
            - mountPath: /lib/modules
              name: modules
              readOnly: true
            - mountPath: /var/run
              name: run
            - mountPath: /hypervisor-config
              name: hypervisor-config
            - mountPath: /nova-etc
              name: nova-etc
            - mountPath: /nova-patches
              name: nova-patches

            - mountPath: /container.init
              name: nova-container-init
        - name: nova-libvirt
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-nova-libvirt:{{$context.Values.image_version_nova_libvirt}}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/nova-libvirt-start
          volumeMounts:
            - mountPath: /var/lib/nova/instances
              name: instances
            - mountPath: /var/lib/libvirt
              name: libvirt
            - mountPath: /var/run
              name: run
            - mountPath: /lib/modules
              name: modules
              readOnly: true
            - mountPath: /nova-etc
              name: nova-etc
            - mountPath: /container.init
              name: nova-container-init
        - name: nova-virtlog
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-nova-libvirt:{{$context.Values.image_version_nova_libvirt}}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/nova-virtlog-start
          volumeMounts:
            - mountPath: /var/lib/nova/instances
              name: instances
            - mountPath: /var/lib/libvirt
              name: libvirt
            - mountPath: /var/run
              name: run
            - mountPath: /lib/modules
              name: modules
              readOnly: true
            - mountPath: /nova-etc
              name: nova-etc
            - mountPath: /container.init
              name: nova-container-init

        - name: neutron-ovs-agent
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-neutron-openvswitch-agent:{{$context.Values.image_version_neutron_openvswitch_agent}}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-ovs-agent-start
          volumeMounts:
            - mountPath: /var/run/
              name: run
            - mountPath: /lib/modules
              name: modules
              readOnly: true
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /container.init
              name: neutron-container-init
        - name: ovs
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-openvswitch-vswitchd:{{$context.Values.image_version_neutron_vswitchd}}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-ovs-start
          volumeMounts:
            - mountPath: /var/run/
              name: run
            - mountPath: /lib/modules
              name: modules
              readOnly: true
            - mountPath: /container.init
              name: neutron-container-init
        - name: ovs-db
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-openvswitch-db-server:{{$context.Values.image_version_neutron_vswitchdb}}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-ovs-db-start
          volumeMounts:
            - mountPath: /var/run/
              name: run
            - mountPath: /lib/modules
              name: modules
            - mountPath: /container.init
              name: neutron-container-init
      volumes:
        - name : instances
          persistentVolumeClaim:
            claimName: kvm-shared1-pvclaim
        - name : libvirt
          emptyDir:
            medium: Memory
        - name : run
          emptyDir:
            medium: Memory
        - name : modules
          hostPath:
            path: /lib/modules
        - name : cgroup
          hostPath:
            path: /sys/fs/cgroup
        - name: hypervisor-config
          configMap:
            name: hypervisor-kvm
        - name: nova-etc
          configMap:
            name: nova-etc
        - name: nova-patches
          configMap:
            name: nova-patches
        - name: neutron-etc
          configMap:
            name: neutron-etc
        - name: nova-container-init
          configMap:
            name: nova-bin
        - name: neutron-container-init
          configMap:
            name: neutron-bin
{{- end -}}
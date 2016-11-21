{{- define "vmware_hypervisor" -}}
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
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 3
  selector:
    matchLabels:
        name: nova-compute-{{$hypervisor.name}}
  template:
    metadata:
      labels:
        name: nova-compute-{{$hypervisor.name}}
      annotations:
        pod.beta.kubernetes.io/hostname:  nova-compute-{{$hypervisor.name}}
    spec:
      containers:
        - name: nova-compute-{{$hypervisor.name}}
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
            - mountPath: /hypervisor-config
              name: hypervisor-config
            - mountPath: /nova-etc
              name: nova-etc
            - mountPath: /nova-patches
              name: nova-patches
            - mountPath: /container.init
              name: nova-container-init
        - name: neutron-dvs-agent
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-neutron-server-m3:{{$context.Values.image_version_neutron_server_m3}}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-dvs-agent-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
          volumeMounts:
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /ml2-conf-vmware
              name: ml2-conf-vmware
            - mountPath: /container.init
              name: neutron-container-init
      volumes:
        - name: nova-etc
          configMap:
            name: nova-etc
        - name: nova-patches
          configMap:
            name: nova-patches
        - name: hypervisor-config
          configMap:
            name: hypervisor-{{$hypervisor.name}}
        - name: ml2-conf-vmware
          configMap:
            name: ml2-vmware-{{$hypervisor.name}}-ini
        - name: neutron-etc
          configMap:
            name: neutron-etc
        - name: neutron-etc-vendor
          configMap:
            name: neutron-etc-vendor
        - name: nova-container-init
          configMap:
            name: nova-bin
        - name: neutron-container-init
          configMap:
            name: neutron-bin-vendor
{{- end -}}
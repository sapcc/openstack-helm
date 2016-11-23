{{- define "f5_deployment" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
kind: Deployment
apiVersion: extensions/v1beta1

metadata:
  name: neutron-f5agent-{{ $loadbalancer.name }}
  labels:
    system: openstack
    type: backend
    component: neutron
spec:
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 3
  selector:
    matchLabels:
      name: neutron-f5agent-{{ $loadbalancer.name }}
  template:
    metadata:
      labels:
        name: neutron-f5agent-{{ $loadbalancer.name }}
      annotations:
        pod.beta.kubernetes.io/hostname:  f5-{{ $loadbalancer.name }}
    spec:
      containers:
        - name: neutron-f5agent-{{ $loadbalancer.name }}
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-neutron-server-m3:{{$context.Values.image_version_neutron_server_m3}}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-f5-agent-start

          env:
            - name: DEBUG_CONTAINER
              value: "false"
            - name: SENTRY_DSN
              value: "{{ include "sentry_dsn_neutron" $context }}"
          volumeMounts:
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /f5-etc
              name: f5-etc
            - mountPath: /neutron-etc-vendor
              name: neutron-etc-vendor
            - mountPath: /f5-patches
              name: f5-patches
            - mountPath: /container.init
              name: container-init
      volumes:
        - name: neutron-etc
          configMap:
            name: neutron-etc
        - name: neutron-etc-vendor
          configMap:
            name: neutron-etc-vendor
        - name: f5-etc
          configMap:
            name: neutron-f5-etc-{{$loadbalancer.name}}
        - name: f5-patches
          configMap:
            name: f5-patches
        - name: development
          persistentVolumeClaim:
            claimName: development-pvclaim
        - name: container-init
          configMap:
            name: neutron-bin-vendor
{{- end -}}
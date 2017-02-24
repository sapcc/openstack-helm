{{- define "ml2_vmware_agent_deployment" -}}
{{- $context := index . 0 -}}
{{- $hypervisor := index . 1 -}}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: neutron-dvs-{{$hypervisor.name}}
  labels:
    system: openstack
    type: backend
    component: neutron
spec:
  replicas: 1
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 3
  selector:
    matchLabels:
        name: neutron-dvs-{{$hypervisor.name}}
  template:
    metadata:
      labels:
        name: neutron-dvs-{{$hypervisor.name}}
      annotations:
        pod.beta.kubernetes.io/hostname:  nova-compute-{{$hypervisor.name}}
    spec:
      containers:
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
        - name: neutron-etc
          configMap:
            name: neutron-etc
        - name: ml2-conf-vmware
          configMap:
            name: ml2-vmware-{{$hypervisor.name}}-ini
        - name: neutron-container-init
          configMap:
            name: neutron-bin-vendor
{{- end -}}

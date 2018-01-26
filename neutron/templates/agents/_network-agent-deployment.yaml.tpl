{{- define "network_agent" }}
{{- $agent := index . 1 }}
{{- with $context := index . 0 }}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: neutron-agents-{{$agent.name}}
  labels:
    system: openstack
    type: backend
    component: neutron
spec:
  replicas: 1
  revisionHistoryLimit: 5
  strategy:
    type: Recreate
  template:

    metadata:
      labels:
        name: neutron-agents-{{$agent.name}}
      annotations:
        scheduler.alpha.kubernetes.io/tolerations: '[{"key":"species","value":"network"}]'
    spec:
      hostNetwork: true
      hostPID: true
      hostIPC: true
      nodeSelector:
        kubernetes.io/hostname: {{$agent.node}}
      containers:
        - name: neutron-dhcp-agent
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-neutron-dhcp-agent:{{.Values.image_version_neutron_dhcp_agent | default .Values.neutron.image_version | required "Please set neutron.image_version or similar" }}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-dhcp-agent-start
          env:
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
            - name: DEBUG_CONTAINER
              value: "false"
          volumeMounts:
            - mountPath: /var/run
              name: run
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /container.init
              name: container-init
        - name: neutron-metadata-agent
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-neutron-metadata-agent:{{.Values.image_version_neutron_metadata_agent | default .Values.neutron.image_version | required "Please set neutron.image_version or similar" }}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-metadata-agent-start
          env:
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - mountPath: /var/run
              name: run
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /container.init
              name: container-init
        - name: neutron-l3-agent
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-neutron-l3-agent:{{.Values.image_version_neutron_l3_agent | default .Values.neutron.image_version | required "Please set neutron.image_version or similar" }}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-l3-agent-start
          env:
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - mountPath: /var/run
              name: run
            - mountPath: /lib/modules
              name: modules
              readOnly: true
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /container.init
              name: container-init
        - name: neutron-ovs-agent
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-neutron-openvswitch-agent:{{.Values.image_version_neutron_openvswitch_agent | default .Values.neutron.image_version | required "Please set neutron.image_version or similar" }}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-ovs-agent-start
          env:
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - mountPath: /var/run
              name: run
            - mountPath: /lib/modules
              name: modules
              readOnly: true
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /container.init
              name: container-init

        - name: ovs
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-openvswitch-vswitchd:{{.Values.image_version_neutron_vswitchd | default .Values.neutron.image_version | required "Please set neutron.image_version or similar" }}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-ovs-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - mountPath: /var/run
              name: run
            - mountPath: /lib/modules
              name: modules
              readOnly: true
            - mountPath: /container.init
              name: container-init
        - name: ovs-db
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-openvswitch-db-server:{{.Values.image_version_neutron_vswitchdb | default .Values.neutron.image_version | required "Please set neutron.image_version or similar" }}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - bash
          args:
            - /container.init/neutron-ovs-db-start
          volumeMounts:
            - mountPath: /lib/modules
              name: modules
            - mountPath: /var/run
              name: run
            - mountPath: /container.init
              name: container-init
      volumes:
        - name : run
          emptyDir:
            medium: Memory
        - name : modules
          hostPath:
            path: /lib/modules
        - name: neutron-etc
          configMap:
            name: neutron-etc
        - name: container-init
          configMap:
            name: neutron-bin
{{- end }}
{{- end }}

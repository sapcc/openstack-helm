{{- define "asr_deployment" }}
{{- $config_agent := index . 1 }}
{{- with $context := index . 0 }}
kind: Deployment

apiVersion: extensions/v1beta1

metadata:
  name: neutron-cisco-asr-{{ $config_agent.name }}
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
      name: neutron-cisco-asr-{{ $config_agent.name }}
  template:
    metadata:
      labels:
        name: neutron-cisco-asr-{{ $config_agent.name }}
      annotations:
        pod.beta.kubernetes.io/hostname: {{ $config_agent.hostname }}
        prometheus.io/scrape: "true"
        prometheus.io/port: "{{.Values.port_metrics}}"
    spec:
      hostname: {{ $config_agent.hostname }}
      containers:
        - name: neutron-cisco-asr
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-neutron-server-m3:{{.Values.image_version_neutron_server_m3 | default .Values.image_version | required "Please set neutron_vendor.image_version or similar"}}
          imagePullPolicy: IfNotPresent
          command:
            - /container.init/neutron-asr-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
            - name: METRICS_PORT
              value: "{{.Values.port_metrics}}"
          volumeMounts:
            - mountPath: /development
              name: development
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /neutron-etc-vendor
              name: neutron-etc-vendor
            - mountPath: /container.init
              name: container-init
          ports:
            - containerPort: {{.Values.port_metrics}}
              name: metrics
              protocol: TCP
      volumes:
        - name: neutron-etc
          configMap:
            name: neutron-etc
        - name: neutron-etc-vendor
          configMap:
            name: neutron-etc-vendor
        - name: container-init
          configMap:
            name: neutron-bin-vendor
            defaultMode: 0755
        - name: development
          persistentVolumeClaim:
            claimName: development-pvclaim
{{- end }}
{{- end }}

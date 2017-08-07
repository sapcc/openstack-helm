{{- define "asr_deployment" -}}
{{- $context := index . 0 -}}
{{- $config_agent := index . 1 -}}
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
        pod.beta.kubernetes.io/hostname:  {{ $config_agent.hostname }}
        prometheus.io/scrape: "true"
        prometheus.io/port: "{{$context.Values.port_metrics}}"
    spec:
      containers:
        - name: neutron-cisco-asr
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-neutron-server-m3:{{$context.Values.image_version_neutron_server_m3}}
          imagePullPolicy: IfNotPresent
          command:
            - /container.init/neutron-asr-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
            - name: SENTRY_DSN
              value: {{$context.Values.sentry_dsn | quote}}
            - name: METRICS_PORT
              value: "{{$context.Values.port_metrics}}"
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
            - containerPort: {{$context.Values.port_metrics}}
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
{{- end -}}

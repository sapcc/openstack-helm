{{define "scheduler"}}
{{$az := index . 1}}
{{with index . 0}}
kind: Deployment
apiVersion: extensions/v1beta1

metadata:
  name: manila-scheduler-{{$az}}
  labels:
    system: openstack
    type: backend
    component: manila
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
      name: manila-scheduler-{{$az}}
  template:
    metadata:
      labels:
        name: manila-scheduler-{{$az}}
    spec:
      containers:
        - name: manila-scheduler
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-manila-scheduler-m3:{{.Values.image_version_manila_scheduler_m3}}
          imagePullPolicy: IfNotPresent
          command:
            - /usr/local/bin/kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "bash /container.init/manila-scheduler-start"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: DEPENDENCY_SERVICE
              value: "manila-api,rabbitmq"
            - name: DEBUG_CONTAINER
              value: "false
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - mountPath: /manila-etc
              name: manila-etc
            - mountPath: /manila-scheduler-etc
              name: manila-scheduler-etc
            - mountPath: /container.init
              name: container-init
      volumes:
        - name: manila-etc
          configMap:
            name: manila-etc
        - name: manila-scheduler-etc
          configMap:
            name: manila-storage-availability-zone-{{$az}}
        - name: container-init
          configMap:
            name: manila-bin
            defaultMode: 0755
{{ end }}
{{ end }}

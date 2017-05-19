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
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-manila-scheduler:{{.Values.image_version_manila_scheduler}}
          imagePullPolicy: IfNotPresent
          command:
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "manila-scheduler --config-file /etc/manila/manila.conf --config-file /etc/manila/storage-availability-zone.conf"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: DEPENDENCY_SERVICE
              value: "manila-api,rabbitmq"
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - name: etcmanila
              mountPath: /etc/manila
            - name: manila-etc
              mountPath: /etc/manila/manila.conf
              subPath: manila.conf
              readOnly: true
            - name: manila-etc
              mountPath: /etc/manila/policy.json
              subPath: policy.json
              readOnly: true
            - name: manila-etc
              mountPath: /etc/manila/logging.conf
              subPath: logging.conf
              readOnly: true
            - name: manila-scheduler-etc
              mountPath: /etc/manila/storage-availability-zone.conf
              subPath: storage-availability-zone.conf
              readOnly: true
      volumes:
        - name: etcmanila
          emptyDir: {}
        - name: manila-etc
          configMap:
            name: manila-etc
        - name: manila-scheduler-etc
          configMap:
            name: manila-storage-availability-zone-{{$az}}
{{ end }}
{{ end }}

{{- define "share_netapp" -}}
{{$share := index . 1 -}}
{{with index . 0}}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: manila-share-netapp-{{$share.name}}
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
        name: manila-share-netapp-{{$share.name}}
  template:
    metadata:
      labels:
        name: manila-share-netapp-{{$share.name}}
      annotations:
        pod.beta.kubernetes.io/hostname: manila-share-netapp-{{$share.name}}
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-netapp-hash: {{ tuple . $share | include "share_netapp_configmap" | sha256sum }}
    spec:
      hostname: manila-share-netapp-{{$share.name}}
      containers:
        - name: manila-share-netapp-{{$share.name}}
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-manila-share:{{.Values.image_version_manila_share | default .Values.image_version | required "Please set manila.image_version or similar" }}
          imagePullPolicy: IfNotPresent
          command:
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "manila-share --config-file /etc/manila/manila.conf --config-file /etc/manila/backend.conf"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: DEPENDENCY_SERVICE
              value: "postgres-manila,rabbitmq"
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
            - name: backend-config
              mountPath: /etc/manila/backend.conf
              subPath: backend.conf
              readOnly: true
      volumes:
        - name: etcmanila
          emptyDir: {}
        - name: manila-etc
          configMap:
            name: manila-etc
        - name: backend-config
          configMap:
            name: share-netapp-{{$share.name}}
{{ end }}
{{- end -}}

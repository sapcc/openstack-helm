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
    spec:
      containers:
        - name: manila-share-netapp-{{$share.name}}
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-manila-share:{{.Values.image_version_manila_share}}
          imagePullPolicy: IfNotPresent
          env:
            - name: COMMAND
              value: "manila-share --config-file /etc/manila/manila.conf --config-file /etc/manila/backend.conf"
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - mountPath: /manila-etc
              name: manila-etc
            - mountPath: /var/lib/kolla/config_files
              name: backend-config
      volumes:
        - name: manila-etc
          configMap:
            name: manila-etc
        - name: backend-config
          configMap:
            name: share-netapp-{{$share.name}}
{{ end }}
{{- end -}}

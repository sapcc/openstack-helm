{{- define "volume_netapp" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: cinder-volume-netapp-{{$volume.name}}
  labels:
    system: openstack
    type: backend
    component: cinder
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
        name: cinder-volume-netapp-{{$volume.name}}
  template:
    metadata:
      labels:
        name: cinder-volume-netapp-{{$volume.name}}
      annotations:
        pod.beta.kubernetes.io/hostname: cinder-volume-netapp-{{$volume.name}}
        checksum/cinder-etc: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        checksum/volume-config: {{ tuple $ $volume | include "volume_netapp_configmap" | sha256sum }}
    spec:
      containers:
        - name: cinder-volume-netapp-{{$volume.name}}
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-cinder-volume:{{.Values.image_version_cinder_volume}}
          imagePullPolicy: IfNotPresent
          env:
            - name: KOLLA_CONFIG_STRATEGY
              value: "COPY_ALWAYS"
            - name: COMMAND
              value: "sleep inf" # "cinder-volume --config-file /etc/cinder/cinder.conf --config-file /etc/cinder/volume.conf"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - mountPath: /cinder-etc
              name: cinder-etc
            - mountPath: /var/lib/kolla/config_files
              name: volume-config
      volumes:
        - name: cinder-etc
          configMap:
            name: cinder-etc
        - name: volume-config
          configMap:
            name:  volume-netapp-{{$volume.name}}
{{- end -}}
{{- end -}}
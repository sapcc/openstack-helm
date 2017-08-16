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
  revisionHistoryLimit: {{ .Values.pod.lifecycle.upgrades.deployments.revision_history }}
  strategy:
    type: {{ .Values.pod.lifecycle.upgrades.deployments.pod_replacement_strategy }}
    {{ if eq .Values.pod.lifecycle.upgrades.deployments.pod_replacement_strategy "RollingUpdate" }}
    rollingUpdate:
      maxUnavailable: {{ .Values.pod.lifecycle.upgrades.deployments.rolling_update.max_unavailable }}
      maxSurge: {{ .Values.pod.lifecycle.upgrades.deployments.rolling_update.max_surge }}
    {{ end }}
  selector:
    matchLabels:
        name: cinder-volume-netapp-{{$volume.name}}
  template:
    metadata:
      labels:
        name: cinder-volume-netapp-{{$volume.name}}
{{ tuple . "cinder" (print "volume-netapp-" $volume.name) | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        pod.beta.kubernetes.io/hostname: cinder-volume-netapp-{{$volume.name}}
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-volume-hash: {{ tuple . $volume | include "volume_netapp_configmap" | sha256sum }}
    spec:
      containers:
        - name: cinder-volume-netapp-{{$volume.name}}
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-cinder-volume:{{.Values.image_version_cinder_volume}}
          imagePullPolicy: IfNotPresent
          command:
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "cinder-volume --config-file /etc/cinder/cinder.conf --config-file /etc/cinder/volume.conf"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
{{- if or $volume.python_warnings .Values.python_warnings }}
            - name: PYTHONWARNINGS
              value: {{ or $volume.python_warnings .Values.python_warnings }}
{{- end }}
          volumeMounts:
            - name: etccinder
              mountPath: /etc/cinder
            - name: cinder-etc
              mountPath: /etc/cinder/cinder.conf
              subPath: cinder.conf
              readOnly: true
            - name: cinder-etc
              mountPath: /etc/cinder/policy.json
              subPath: policy.json
              readOnly: true
            - name: cinder-etc
              mountPath: /etc/cinder/logging.conf
              subPath: logging.conf
              readOnly: true
            - name: volume-config
              mountPath: /etc/cinder/volume.conf
              subPath: volume.conf
              readOnly: true
      volumes:
        - name: etccinder
          emptyDir: {}
        - name: cinder-etc
          configMap:
            name: cinder-etc
        - name: volume-config
          configMap:
            name:  volume-netapp-{{$volume.name}}
{{- end -}}
{{- end -}}

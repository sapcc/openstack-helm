{{- define "ironic_hypervisor" -}}
{{- $hypervisor := index . 1 -}}
{{- with index . 0 -}}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: nova-compute-ironic
  labels:
    system: openstack
    type: backend
    component: nova
spec:
  replicas: 1
  revisionHistoryLimit: {{ .Values.pod.lifecycle.upgrades.deployments.revision_history }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 3
  selector:
    matchLabels:
      name: nova-compute-ironic
  template:
    metadata:
      labels:
        name: nova-compute-ironic
{{ tuple . "nova" "compute-ironic" | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        pod.beta.kubernetes.io/hostname: nova-compute-ironic
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-ironic-etc-hash: {{ tuple . $hypervisor | include "ironic_configmap" | sha256sum }}
    spec:
      containers:
        - name: nova-compute-ironic
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-nova-compute:{{.Values.image_version_nova_compute}}
          imagePullPolicy: IfNotPresent
          command:
            - kubernetes-entrypoint
          env:
            - name: COMMAND
              value: "nova-compute --config-file /etc/nova/nova.conf --config-file /etc/nova/hypervisor.conf"
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
{{- if or $hypervisor.python_warnings .Values.python_warnings }}
            - name: PYTHONWARNINGS
              value: {{ or $hypervisor.python_warnings .Values.python_warnings | quote }}
{{- end }}
          volumeMounts:
            - mountPath: /etc/nova
              name: etcnova
            - mountPath: /etc/nova/nova.conf
              name: nova-etc
              subPath: nova.conf
              readOnly: true
            - mountPath: /etc/nova/policy.json
              name: nova-etc
              subPath: policy.json
              readOnly: true
            - mountPath: /etc/nova/logging.conf
              name: nova-etc
              subPath: logging.conf
              readOnly: true
            - mountPath: /etc/nova/hypervisor.conf
              name: hypervisor-config
              subPath: hypervisor.conf
              readOnly: true
            - mountPath: /nova-patches
              name: nova-patches
      volumes:
        - name: etcnova
          emptyDir: {}
        - name: nova-etc
          configMap:
            name: nova-etc
        - name: nova-patches
          configMap:
            name: nova-patches
        - name: hypervisor-config
          configMap:
            name:  hypervisor-{{$hypervisor.name}}
{{- end -}}
{{- end -}}

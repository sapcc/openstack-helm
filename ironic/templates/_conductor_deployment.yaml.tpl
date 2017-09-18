{{- define "ironic_conductor_deployment" }}
    {{- $conductor := index . 1 }}
    {{- with index . 0 }}
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ironic-conductor-{{$conductor.name}}
  labels:
    system: openstack
    type: backend
    component: ironic
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
      name: ironic-conductor-{{$conductor.name}}
  template:
    metadata:
      labels:
        name: ironic-conductor-{{$conductor.name}}
{{ tuple . "ironic" "conductor" | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
      annotations:
        pod.beta.kubernetes.io/hostname: ironic-conductor-{{$conductor.name}}
        configmap-etc-hash: {{ include (print .Template.BasePath "/etc-configmap.yaml") . | sha256sum }}
        configmap-etc-conductor-hash: {{ tuple . $conductor | include "ironic_conductor_configmap" | sha256sum }}
    spec:
      containers:
        - name: ironic-conductor
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-ironic-conductor:{{.Values.image_version_ironic_conductor}}
          imagePullPolicy: IfNotPresent
        {{- if $conductor.debug }}
          securityContext:
            runAsUser: 0
        {{- end }}
          command:
            - kubernetes-entrypoint
          env:
            - name: COMMAND
        {{- if not $conductor.debug }}
              value: "ironic-conductor --config-file /etc/ironic/ironic.conf --config-file /etc/ironic/ironic-conductor.conf"
        {{- else }}
              value: "sleep inf"
        {{- end }}
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: DEPENDENCY_SERVICE
              value: "ironic-api,rabbitmq"
          volumeMounts:
            - mountPath: /etc/ironic
              name: etcironic
            - mountPath: /etc/ironic/ironic.conf
              name: ironic-etc
              subPath: ironic.conf
              readOnly: {{ not $conductor.debug }}
            - mountPath: /etc/ironic/policy.json
              name: ironic-etc
              subPath: policy.json
              readOnly: {{ not $conductor.debug }}
            - mountPath: /etc/ironic/rootwrap.conf
              name: ironic-etc
              subPath: rootwrap.conf
              readOnly: {{ not $conductor.debug }}
            - mountPath: /etc/ironic/logging.conf
              name: ironic-etc
              subPath: logging.conf
              readOnly: {{ not $conductor.debug }}
            - mountPath: /etc/ironic/ironic-conductor.conf
              name: ironic-conductor-etc
              subPath: ironic-conductor.conf
              readOnly: {{ not $conductor.debug }}
            - mountPath: /etc/ironic/pxe_config.template
              name: ironic-conductor-etc
              subPath: pxe_config.template
              readOnly: {{ not $conductor.debug }}
            - mountPath: /tftpboot
              name: ironic-tftp
        {{- if $conductor.debug }}
            - mountPath: /development
              name: development
        {{- end }}
      volumes:
        - name: etcironic
          emptyDir: {}
        - name: ironic-etc
          configMap:
            name: ironic-etc
        - name: ironic-conductor-etc
          configMap:
            name: ironic-conductor-{{$conductor.name}}-etc
        - name: ironic-tftp
          persistentVolumeClaim:
            claimName: ironic-tftp-pvclaim
        {{- if $conductor.debug }}
        - name: development
          persistentVolumeClaim:
            claimName: development-pvclaim
        {{- end }}
    {{- end }}
{{- end }}

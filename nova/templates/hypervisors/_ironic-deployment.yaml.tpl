{{- define "ironic_hypervisor" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
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
  revisionHistoryLimit: 5
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
      annotations:
        pod.beta.kubernetes.io/hostname: nova-compute-ironic
    spec:
      containers:
        - name: nova-compute-ironic
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-nova-compute:{{.Values.image_version_nova_compute}}
          imagePullPolicy: IfNotPresent
          env:
            - name: COMMAND
              value: nova-compute --config-file /etc/nova/nova.conf --config-file /etc/nova/hypervisor.conf
            - name: NAMESPACE
              value: {{ .Release.Namespace }}
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - mountPath: /var/lib/kolla/config_files
              name: hypervisor-config
            - mountPath: /nova-etc
              name: nova-etc
            - mountPath: /nova-patches
              name: nova-patches
      volumes:
        - name: nova-etc
          configMap:
            name: nova-etc
        - name: nova-patches
          configMap:
            name: nova-patches
        - name: hypervisor-config
          configMap:
            name:  hypervisor-{{$hypervisor.name}}
{{- end }}
{{- end }}
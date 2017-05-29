{{- define "vmware_hypervisor" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: nova-compute-{{$hypervisor.name}}
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
        name: nova-compute-{{$hypervisor.name}}
  template:
    metadata:
      labels:
        name: nova-compute-{{$hypervisor.name}}
      annotations:
        pod.beta.kubernetes.io/hostname: nova-compute-{{$hypervisor.name}}
        prometheus.io/scrape: "true"
        prometheus.io/port: "9102"
    spec:
      containers:
        - name: nova-compute-{{$hypervisor.name}}
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
          volumeMounts:
            - mountPath: /etc/nova
              name: etcnova
            - mountPath: /etc/nova/nova.conf
              name: nova-etc
              subPath: nova.conf
              readOnly: true
            - mountPath: /etc/nova/api-paste.ini
              name: nova-etc
              subPath: api-paste.ini
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
        - name: neutron-dvs-agent
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-neutron-server-m3:{{.Values.image_version_neutron_server_m3}}
          imagePullPolicy: IfNotPresent
          command:
            - /container.init/neutron-dvs-agent-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
            - name: STATSD_HOST
              value: "localhost"
            - name: STATSD_PORT
              value: "9125"
          volumeMounts:
            - mountPath: /neutron-etc
              name: neutron-etc
            - mountPath: /ml2-conf-vmware
              name: ml2-conf-vmware
            - mountPath: /container.init
              name: neutron-container-init
        - name: statsd
          image: prom/statsd-exporter
          imagePullPolicy: IfNotPresent
          ports:
            - name: statsd
              containerPort: 9125
              protocol: UDP
            - name: metrics
              containerPort: 9102
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
            name: hypervisor-{{$hypervisor.name}}
        - name: nova-container-init
          configMap:
            name: nova-bin
            defaultMode: 0755
        - name: neutron-etc
          configMap:
            name: neutron-etc
        - name: ml2-conf-vmware
          configMap:
            name: ml2-vmware-{{$hypervisor.name}}-ini
        - name: neutron-container-init
          configMap:
            name: neutron-bin-vendor
            defaultMode: 0755
{{- end }}
{{- end }}

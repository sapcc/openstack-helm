{{- define "volume_deployment" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: cinder-volume-{{$volume.name}}
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
        name: cinder-{{$volume.name}}
  template:
    metadata:
      labels:
        name: cinder-{{$volume.name}}
      annotations:
        pod.beta.kubernetes.io/hostname: cinder-volume-{{$volume.name}}
        checksum/cinder-etc: {{ include "cinder/templates/etc-configmap.yaml" . | sha256sum }}
        checksum/volume-config: {{ tuple $ $volume | include "volume_configmap" | sha256sum }}
    spec:
      containers:
        - name: cinder-volume-{{$volume.name}}
          image: {{.Values.global.image_repository}}/{{.Values.global.image_namespace}}/ubuntu-source-cinder-volume:{{.Values.image_version_cinder_volume}}
          imagePullPolicy: IfNotPresent
          command:
            - /container.init/cinder-volume-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
            - name: SENTRY_DSN
              value: {{.Values.sentry_dsn | quote}}
          volumeMounts:
            - mountPath: /cinder-etc
              name: cinder-etc
            - mountPath: /volume-config
              name: volume-config
            - mountPath: /container.init
              name: container-init
      volumes:
        - name: cinder-etc
          configMap:
            name: cinder-etc
        - name: volume-config
          configMap:
            name:  volume-{{$volume.name}}
        - name: container-init
          configMap:
            name: cinder-bin
            defaultMode: 0755
{{- end -}}
{{- end -}}

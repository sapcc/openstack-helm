{{- define "volume_vmware" -}}
{{- $context := index . 0 -}}
{{- $volume := index . 1 -}}
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: cinder-volume-vmware-{{$volume.name}}
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
        name: cinder-volume-vmware-{{$volume.name}}
  template:
    metadata:
      labels:
        name: cinder-volume-vmware-{{$volume.name}}
      annotations:
        pod.beta.kubernetes.io/hostname: cinder-volume-vmware-{{$volume.name}}
    spec:
      containers:
        - name: cinder-volume-vmware-{{$volume.name}}
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-cinder-volume:{{$context.Values.image_version_cinder_volume}}
          imagePullPolicy: IfNotPresent
          command:
            - bash
          args:
            - /container.init/cinder-volume-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
            - name: SENTRY_DSN
              value: {{$context.Values.sentry_dsn | quote}}
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
            name:  volume-vmware-{{$volume.name}}
        - name: container-init
          configMap:
            name: cinder-bin
{{- end -}}
{{- define "share_netapp" -}}
{{- $context := index . 0 -}}
{{- $share := index . 1 -}}
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
          image: {{$context.Values.global.image_repository}}/{{$context.Values.global.image_namespace}}/ubuntu-source-manila-share-m3:{{$context.Values.image_version_manila_share_m3}}
          imagePullPolicy: IfNotPresent
          command:
            - bash
          args:
            - /container.init/manila-share-start
          env:
            - name: DEBUG_CONTAINER
              value: "false"
          volumeMounts:
            - mountPath: /manila-etc
              name: manila-etc
            - mountPath: /backend-config
              name: backend-config
            - mountPath: /container.init
              name: container-init
      volumes:
        - name: manila-etc
          configMap:
            name: manila-etc
        - name: backend-config
          configMap:
            name: share-netapp-{{$share.name}}
        - name: container-init
          configMap:
            name: manila-bin
{{- end -}}
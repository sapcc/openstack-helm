# openstack-helm

A collection of Helm charts to install and maintain a core Openstack IAAS platform on Kubernetes.

Includes charts for Openstack

- Barbican
- Cinder
- Desgnate
- Glance
- Horizon
- Ironic
- Keystone
- Manila
- Neutron
- Nova

And infrastructure components
- Postgres
- Mariadb
- RabbitMQ
- Memached

The charts themselves will not install and run directly. They are included in the "openstack" chart as requirements,
the openstack chart is effectively an abstract region and is intended to be required by a concrete region chart. There is an example
region included 'europe-example-region' and this chart is used to provide region specific values/templates such as passwords,
certificates, region hardware pods and configuration.

In general the following approach is used to determine where values are set/overridden :

1. Only used in chart and not sensitive data > set as chart value
2. Shared by two or more charts and not sensitive data > set in openstack chart as global value
3. Only used in chart and sensitive data > stored in region values and overridden as a chart value
4. Shared by two or more charts and sensistive data > stored in region values and overridden as a global value

The region charts then contain all sensitive data and can be secured separately to the generic charts.

We use images based on a Kolla build, but we've dropped their Ansible approach to orchestration/config management in
favour of Helm and native Kubernetes specs. We also have a number of vendor and self developed extensions, especially
for Neutron, which are build into our images (you can see reference to many of these in the configuration files/values).



To install, from the repository root

    make
    helm install [region release name] --name [region chart name] --namespace [kube namespace]

This is likely to fail due to this [issue](https://github.com/kubernetes/helm/issues/1413). You will need a tiller version
with this [commit](https://github.com/kubernetes/helm/commit/2eed3f0464ff88d1c8358388ce5472e835c35feb) or later.

The 'build' process is a little cumbersome, we wanted to keep config, patches and custom start scripts in plain text,
rather than directly in a template. We hope this (https://github.com/kubernetes/helm/issues/950) feature request
will simplify our processing.

## Node Affinity

We have two use cases for exclusive nodes:

  * Hypervisor
  * Network

Only specific pods should be scheduled to these nodes. We will achieve this by
tainting the nodes:

```
kubectl taint network0 species=network:NoSchedule
kubectl taint network1 species=network:NoSchedule
kubectl taint minion1  species=hypervisor:NoSchedule
```

Now nothing can be scheduled there. Pods that should be able to go to this need to
have a toleration added.

```
annotations:
  scheduler.alpha.kubernetes.io/tolerations: '[{"key":"species","value":"hypervisor"}]'
```

These pods could still go to any node though. We need to confine KVM pods to
the hyperivsors and neutron agents to their dedicated network nodes. We do this
by labeling the nodes:

```
kubectl label network0 species=network
kubectl label minion1  species=hypervisor
```

Then add selectors to the pods:

```
spec:
  nodeSelector:
    species: hypervisor
    kubernetes.io/hostname: minion1
```

To lock pods onto a particular node we do:

```
spec:
  nodeSelector:
    kubernetes.io/hostname: minion1
```

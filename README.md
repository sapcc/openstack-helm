# openstack-helm

A collection of Helm charts to install and maintain a core Openstack IAAS platform on Kubernetes.

Includes charts for Openstack

- Barbican
- Cinder
- Designate
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
- Memcached

The charts themselves will not install and run directly. They are included in the "openstack" chart as requirements,
the openstack chart is effectively an abstract region and is intended to be required by a concrete region chart. There is an example
region included 'europe-example-region' and this chart is used to provide region specific values/templates such as passwords,
certificates, region hardware pods and configuration.

In general the following approach is used to determine where values are set/overridden :

1. Only used in chart and not sensitive data > set as chart value
2. Shared by two or more charts and not sensitive data > set in openstack chart as global value
3. Only used in chart and sensitive data > stored in region values and overridden as a chart value
4. Shared by two or more charts and sensitive data > stored in region values and overridden as a global value

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

## HELMING ( Process of pushing updates to Regions via HELM )

Post installing helm, the next obvious step is to reflect our changes in the production. The below steps should help you get there:

1. Validate your changes are present in the respective branch in openstack-helm repo.
2. Make sure helm serve is running in the backgroud.

```
helm serve &
```

3. Execute `make` in the top-level directory of the openstack-helm repository (if this is your 1st attempt, you may most likely bump into the below error) :

```
find . -name "*.tgz" -exec rm '{}' +
if [ -f utils/requirements.yaml ]; then helm dep up utils; fi
helm package utils
if [ -f postgres/requirements.yaml ]; then helm dep up postgres; fi
helm package postgres
if [ -f barbican/requirements.yaml ]; then helm dep up barbican; fi
Error: no repository definition for http://localhost:8879/charts, http://localhost:8879/charts. Try 'helm repo add'
make: *** [build-barbican] Error 1
```

Fix the error by adding the repo :

```
helm repo add local http://localhost:8879/charts
```

4. Get the current version of cc-regions. Thinking Why? Most of CCloud information is in this repo.
5. Execute make in the top-level directory of cc-regions. Adding the desired region to make command saves time, else all the regions will undergo execution.
6. If you wish to validate your changes are reflected prior to helm upgrade. `helm diff` is a great plugin to validate this, more information can be found here [helm diff](https://github.com/databus23/helm-diff)
7. Final Step. If the expected changes are shown, execute `helm upgrade staging staging` in the top-level directory of cc-regions(it will be good if you update the slack channel with this regard, as this prevents impacting other user changes).

## Node Affinity

We have two use cases for exclusive nodes:

  * Hypervisor
  * Network

Only specific pods should be scheduled to these nodes. We will achieve this by
tainting the nodes:

```
kubectl taint node network0 species=network:NoSchedule
kubectl taint node network1 species=network:NoSchedule
kubectl taint node minion1  species=hypervisor:NoSchedule
```

Now nothing can be scheduled there. Pods that should be able to go to this need to
have a toleration added.

```
annotations:
  scheduler.alpha.kubernetes.io/tolerations: '[{"key":"species","value":"hypervisor"}]'
```

These pods could still go to any node though. We need to confine KVM pods to
the hypervisors and neutron agents to their dedicated network nodes. We do this
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


## Hot-Fixing

While generally patches should be integrated in the image used, we provide a pattern to apply patches on the start of a container via configMaps.
The startup script will try to apply all files matching the pattern `/*-patches/*.patch` to the kolla venv site-packages directory.
Patches, where the first file does not seem to match any existing file will be silently ignored.

The files have to be unified diff, containing the relative path to the base directory of the package.
The most basic way do to so is running `diff -ruN <original.dir> <patched.dir>`. If the changes are in a git repository or any other source-control system, you have an easier way to generate the output.
For git, you can simply to a `git diff <ORIGINAL>:<PATCHED>`, or `git format-patch -o <helm-directory>/patches <ORGINAL>:<PATCHED>` .

You still have to add the patches to either the config-map specified in the deployment, or amount another configmap ending in "-patches" containing the files.

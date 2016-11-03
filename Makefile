.PHONY: $(shell find * -type d -depth 0)

all: openstack europe-example-region

europe-example-region: build-europe-example-region

openstack: barbican cinder designate horizon ironic keystone glance manila memcached neutron nova rabbitmq
openstack: build-openstack

barbican: utils postgres
barbican: build-barbican

cinder: utils postgres
cinder: build-cinder

designate: utils mariadb
designate: build-designate


glance: utils postgres
glance: build-glance

horizon: utils
horizon: build-horizon

ironic: utils postgres
ironic: build-ironic

keystone: utils postgres
keystone: build-keystone

manila: utils postgres
manila: build-manila

memcached: build-memcached

nova: utils postgres
nova: build-nova

neutron: utils postgres
neutron: build-neutron

#dependencies
mariadb: build-mariadb
postgres: build-postgres
rabbitmq: build-rabbitmq
utils: build-utils

build-%:
	if [ -f $*/Makefile ]; then make -C $*; fi
	if [ -f $*/requirements.yaml ]; then helm dep up $*; fi
	helm package $*

#%.bla: #$(firstword $(subst -, ,%))
#  echo $(wildcard $(firstword $(subst -, ,$*))/**/*)

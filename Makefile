.PHONY: $(sort $(dir $(wildcard */)))

all: clean openstack europe-example-region

europe-example-region: build-europe-example-region

openstack: barbican cinder designate horizon ironic keystone glance manila memcached neutron nova rabbitmq rabbitmq_notifications neutron_vendor healthchecks
openstack: build-openstack

healthchecks: build-healthchecks

barbican: utils postgres pg_metrics
barbican: build-barbican

cinder: utils postgres rabbitmq_notifications
cinder: build-cinder

designate: utils mariadb mysql_metrics
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

nova: utils postgres rabbitmq_notifications
nova: build-nova

neutron: utils postgres
neutron: build-neutron

neutron_vendor: utils
neutron_vendor: build-neutron_vendor

#dependencies
pg_metrics: build-pg_metrics
mysql_metrics: build-mysql_metrics
mariadb: build-mariadb
postgres: build-postgres pg_metrics
rabbitmq: build-rabbitmq
rabbitmq_notifications: build-rabbitmq_notifications
utils: build-utils

build-%:
	if [ -f $*/requirements.yaml ]; then helm dep up $*; fi
	helm package $*

lint: lint-barbican lint-cinder lint-designate lint-europe-example-region
lint: lint-glance lint-horizon lint-ironic lint-keystone lint-mariadb
lint: lint-memcached lint-neutron lint-nova lint-openstack lint-postgres
lint: lint-neutron_vendor lint-rabbitmq lint-rabbitmq_notifications lint-utils lint-pg_metrics
lint: lint-mysql_metrics
lint-%:
	helm lint $*

clean:
	find . -name "*.tgz" -exec rm '{}' +

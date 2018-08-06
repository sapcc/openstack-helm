.PHONY: $(sort $(dir $(wildcard */)))

all: clean openstack europe-example-region

europe-example-region: build-europe-example-region

openstack: cinder memcached neutron nova rabbitmq rabbitmq_notifications neutron_vendor healthchecks
openstack: build-openstack

healthchecks: build-healthchecks

cinder: utils postgres rabbitmq_notifications
cinder: build-cinder

memcached: build-memcached

nova: utils postgres rabbitmq_notifications
nova: build-nova

neutron: utils postgres
neutron: build-neutron

neutron_vendor: utils
neutron_vendor: build-neutron_vendor

#dependencies
pg_metrics: build-pg_metrics
postgres: build-postgres pg_metrics
rabbitmq: build-rabbitmq
rabbitmq_notifications: build-rabbitmq_notifications
utils: build-utils


lint: lint-europe-example-region
lint: lint-memcached lint-neutron lint-nova lint-openstack lint-postgres
lint: lint-neutron_vendor lint-rabbitmq lint-rabbitmq_notifications lint-utils lint-pg_metrics

build-%:
	if [ -f $*/requirements.yaml ]; then helm dep up --skip-refresh $*; fi
	helm package $*

lint-%:
	helm lint $*

clean:
	find . -name "*.tgz" -exec rm '{}' +

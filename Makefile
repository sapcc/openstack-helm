.PHONY: $(sort $(dir $(wildcard */)))

all: clean openstack europe-example-region

europe-example-region: build-europe-example-region

openstack: rabbitmq
openstack: build-openstack

#dependencies
rabbitmq: build-rabbitmq
utils: build-utils


lint: lint-europe-example-region
lint: lint-openstack
lint: lint-rabbitmq lint-utils

build-%:
	if [ -f $*/requirements.yaml ]; then helm dep up --skip-refresh $*; fi
	helm package $*

lint-%:
	helm lint $*

clean:
	find . -name "*.tgz" -exec rm '{}' +

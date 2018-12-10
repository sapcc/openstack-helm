.PHONY: $(sort $(dir $(wildcard */)))

all: clean openstack

openstack: rabbitmq
openstack: build-openstack

#dependencies
rabbitmq: build-rabbitmq
utils: build-utils

lint: lint-openstack
lint: lint-rabbitmq lint-utils

build-%:
	if [ -f $*/requirements.yaml ]; then helm dep up --skip-refresh $*; fi
	helm package $*

lint-%:
	helm lint $*

clean:
	find . -name "*.tgz" -exec rm '{}' +

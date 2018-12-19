.PHONY: $(sort $(dir $(wildcard */)))

all: clean openstack

openstack: build-openstack

lint: lint-openstack

build-%:
	if [ -f $*/requirements.yaml ]; then helm dep up --skip-refresh $*; fi
	helm package $*

lint-%:
	helm lint $*

clean:
	find . -name "*.tgz" -exec rm '{}' +

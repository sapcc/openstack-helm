.PHONY: $(shell find * -type d -depth 0)

all: europe-example-region


staging: europe-example-region


build-%:
	if [ -f $*/Makefile ]; then make -C $*; fi
	if [ -f $*/requirements.yaml ]; then helm dep up $*; fi
	helm package $*

#%.bla: #$(firstword $(subst -, ,%))
#  echo $(wildcard $(firstword $(subst -, ,$*))/**/*)

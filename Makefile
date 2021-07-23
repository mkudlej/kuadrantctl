SHELL := /bin/bash

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_PATH := $(patsubst %/,%,$(dir $(MKFILE_PATH)))
GO ?= go

include utils.mk

all: help

.PHONY : help
help: Makefile
	@sed -n 's/^##//p' $<

# Kind tool
KIND = $(PROJECT_PATH)/bin/kind
KIND_CLUSTER_NAME = kuadrant-local
$(KIND):
	$(call go-get-tool,$(KIND),sigs.k8s.io/kind@v0.11.1)

.PHONY : kind
kind: $(KIND)

# istioctl tool
ISTIOCTL = $(PROJECT_PATH)/bin/istioctl
ISTIOCTLVERSION = 1.9.4
istioctl:
ifeq (,$(wildcard $(ISTIOCTL)))
	@{ \
	set -e ;\
	mkdir -p $(dir $(ISTIOCTL)) ;\
	curl -sSL https://raw.githubusercontent.com/istio/istio/master/release/downloadIstioCtl.sh | ISTIO_VERSION=$(ISTIOCTLVERSION) HOME=$(PROJECT_PATH)/bin/ sh - > /dev/null 2>&1;\
	mv $(PROJECT_PATH)/bin/.istioctl/bin/istioctl $(ISTIOCTL) ;\
	rm -r $(PROJECT_PATH)/bin/.istioctl ;\
	chmod +x $(ISTIOCTL) ;\
	}
endif

## test: Run unit tests
.PHONY : test
test: fmt vet
	$(GO) test  -v ./...

## install: Build and install kuadrantctl binary ($GOBIN or GOPATH/bin)
.PHONY : install
install: fmt vet
	$(GO) install

.PHONY : fmt
fmt:
	$(GO) fmt ./...

.PHONY : vet
vet:
	$(GO) vet ./...

# Generates istio manifests with patches.
.PHONY: generate-istio-manifests
generate-istio-manifests: istioctl
	$(ISTIOCTL) manifest generate --set profile=minimal --set values.gateways.istio-ingressgateway.autoscaleEnabled=false --set values.pilot.autoscaleEnabled=false --set values.global.istioNamespace=kuadrant-system -f istiomanifests/patches/istio-externalProvider.yaml -o istiomanifests/autogenerated

.PHONY: istio-manifest-update-test
istio-manifest-update-test: generate-istio-manifests
	git diff --exit-code ./istiomanifests/autogenerated
	[ -z "$$(git ls-files --other --exclude-standard --directory --no-empty-directory ./istiomanifests/autogenerated)" ]

# Generates kuadrant manifests.
KUADRANTVERSION=v0.0.1-pre2
.PHONY: generate-kuadrant-manifests
generate-kuadrant-manifests:
	$(eval TMP := $(shell mktemp -d))
	cd $(TMP); git clone --depth 1 --branch $(KUADRANTVERSION) https://github.com/kuadrant/kuadrant-controller.git
	cd $(TMP)/kuadrant-controller; make kustomize; bin/kustomize build config/default -o $(PROJECT_PATH)/kuadrantmanifests/autogenerated/kuadrant.yaml 
	-rm -rf $(TMP)

.PHONY: kuadrant-manifest-update-test
kuadrant-manifest-update-test: generate-kuadrant-manifests
	git diff --exit-code ./kuadrantmanifests/autogenerated
	[ -z "$$(git ls-files --other --exclude-standard --directory --no-empty-directory ./kuadrantmanifests/autogenerated)" ]

.PHONY : cluster-cleanup
cluster-cleanup: $(KIND)
	$(KIND) delete cluster --name $(KIND_CLUSTER_NAME)

.PHONY : cluster-setup
cluster-setup: $(KIND)
	$(KIND) create cluster --name $(KIND_CLUSTER_NAME) --config utils/kind/cluster.yaml

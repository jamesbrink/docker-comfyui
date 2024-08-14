#!/usr/bin/make -f

SHELL                   := /usr/bin/env bash
REPO_NAMESPACE          ?= jamesbrink
REPO_USERNAME           ?= jamesbrink
REPO_API_URL            ?= https://hub.docker.com/v2
IMAGE_NAME              ?= comfyui
CUDA_VERSION            ?= 12.2.2
BASE_IMAGE              ?= nvidia/cuda:$(CUDA_VERSION)-runtime-ubuntu22.04
MODELS                  ?= false
SED                     := $(shell [[ `command -v gsed` ]] && echo gsed || echo sed)
VERSION                 := v0.0.8
UI_MANAGER_VERSION      ?= main

# Default target is to build container
.PHONY: default
default: base

# Build the docker image
.PHONY: base
base:
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):latest \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION) \
		--target=base \
		--file Dockerfile .; \

push-base: base
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):latest; \
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION);

.PHONY: sd-1.5
sd-1.5: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):sd-1.5 \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-sd-1.5 \
		--target=sd-1.5 \
		--file Dockerfile .; \

push-sd-1.5: sd-1.5
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):sd-1.5; \
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-sd-1.5;

.PHONY: sd-turbo
sd-turbo: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):sd-turbo \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-sd-turbo \
		--target=sd-turbo \
		--file Dockerfile .; \

push-sd-turbo: sd-turbo
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):sd-turbo; \
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-sd-turbo;

.PHONY: svd-14-frame
svd-14-frame: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):svd-14-frame \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-svd-14-frame \
		--target=svd-14-frame \
		--file Dockerfile .; \

push-svd-14-frame: svd-14-frame
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):svd-14-frame; \
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-svd-14-frame;

.PHONY: svd-25-frame
svd-25-frame: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):svd-25-frame \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-svd-25-frame \
		--target=svd-25-frame \
		--file Dockerfile .; \

push-svd-25-frame: svd-25-frame
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):svd-25-frame; \
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-svd-25-frame;

.PHONY: svd
svd: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):svd \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-svd \
		--target=svd \
		--file Dockerfile .; \

push-svd: svd
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):svd; \
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-svd;

.PHONY: all-models
all-models: base sd-turbo sd-1.5 svd-14-frame svd-25-frame svd
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):all-models \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-all-models \
		--file Dockerfile .; \

push-all-models: all-models
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):all-models; \
	docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION)-all-models;

# List built images
.PHONY: list
list:
	docker images $(REPO_NAMESPACE)/$(IMAGE_NAME) --filter "dangling=false"

# Run any tests
.PHONY: test
test:
	docker run -t $(REPO_NAMESPACE)/$(IMAGE_NAME) env | grep VERSION | grep $(VERSION)

# Remove existing images
.PHONY: clean
clean:
	docker rmi $$(docker images $(REPO_NAMESPACE)/$(IMAGE_NAME) --format="{{.Repository}}:{{.Tag}}") --force

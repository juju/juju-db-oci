# Copyright 2022 Canonical Ltd.
# Licensed under the AGPLv3, see LICENCE file for details.

BUILD_IMAGE=bash -c '. "./make_functions.sh"; build_image "$$@"' build_image
MICROK8S_IMAGE_UPDATE=bash -c '. "./make_functions.sh"; microk8s_image_update "$$@"' microk8s_image_update
IMAGES?=$(shell yq -o=t '.images | keys' < images.yaml)

default: build

microk8s-image-update: .build-test $(patsubst %,.microk8s-image-update/%,$(IMAGES))
.microk8s-image-update/%:
	$(MICROK8S_IMAGE_UPDATE) "$(@:.microk8s-image-update/%=%)"
.build-test: OUTPUT_TYPE=type=docker
.build-test: IS_LOCAL=1
.build-test: $(IMAGES)

build: OUTPUT_TYPE=type=image,push=false
build: $(IMAGES)

check:
	shellcheck ./*.sh

images-json:
	@yq -o=j '.images | keys' < images.yaml | jq -c

push: OUTPUT_TYPE=type=image,push=true
push: $(IMAGES)

%:
	$(BUILD_IMAGE) "$@" "$(OUTPUT_TYPE)" "${IS_LOCAL}"

.PHONY: default
.PHONY: build
.PHONY: microk8s-image-update
.PHONY: .build-test
.PHONY: .microk8s-image-update/%
.PHONY: check
.PHONY: push
.PHONY: %


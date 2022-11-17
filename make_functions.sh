#!/bin/bash
set -euf

_build_args_builder() {
  build_args=$1

  output=""
  for build_arg in ${build_args}; do
    output="${output} --build-arg ${build_arg}"
  done

  echo "$output"
}

_tag_argument_builder() {
  reg_paths=$1
  tags=$2

  output=""
  for reg_path in ${reg_paths//,/ }; do
    for tag in ${tags//,/ }; do
      output="${output} -t ${reg_path}:${tag}"
    done
  done

  echo "$output"
}

build_image() {
  image=${1-""}
  if [ -z "$image" ]; then
    echo "You must supply the image to build in images.yaml"
    exit 1
  fi
  output=${2-""}
  if [ -z "$output" ]; then
    echo "You must supply the docker buildx output to use for image ${image}"
    exit 1
  fi
  is_local=${3-0}

  dockerfile=Dockerfile
  reg_paths=$(yq -o=c ".images.[\"${image}\"].registry_paths" < images.yaml)
  tags=$(yq -o=c ".images.[\"${image}\"].tags" < images.yaml)
  platforms=$(yq -o=c ".images.[\"${image}\"].platforms" < images.yaml)
  build_args=$(yq -o=t ".images.[\"${image}\"].build_args" < images.yaml)

  cmd_build_args=$(_build_args_builder "$build_args")
  cmd_tags=$(_tag_argument_builder "$reg_paths" "$tags")

  if [[ "${is_local}" -eq 1 ]]; then
    cmd_platforms=""
  else
    cmd_platforms="--platform ${platforms}"
  fi

  echo "Building ${image} for build args \"$build_args\" and platforms \"$platforms\""
  echo ${cmd_platforms}
  docker buildx build ${cmd_platforms} ${cmd_build_args} \
    -f "$dockerfile" . ${cmd_tags} -o "$output" --progress=auto
}

import_microk8s() {
  image=${1-""}
  if [ -z "$image" ]; then
    echo "You must supply the image to build in images.yaml"
    exit 1
  fi
  reg_paths=$(yq -o=c ".images.[\"${image}\"].registry_paths" < images.yaml)
  tags=$(yq -o=c ".images.[\"${image}\"].tags" < images.yaml)
  for reg_path in ${reg_paths//,/ }; do
    for tag in ${tags//,/ }; do
      docker save "${reg_path}:${tag}" | sudo microk8s.ctr --namespace k8s.io image import -
    done
  done
}

#!/bin/bash
set -euf

OCI_BUILDER=${OCI_BUILDER:-( (which podman 2>&1 > /dev/null && echo podman) || echo docker )}
DOCKER_BIN=${DOCKER_BIN:-$(which ${OCI_BUILDER} || true)}
DEFAULT_PLATFORM=${PLATFORM:-"linux/amd64"}

_build_args_builder() {
  build_args=$1

  output=""
  for build_arg in ${build_args}; do
    output="${output} --build-arg ${build_arg}"
  done

  echo "$output"
}

_image_path_list_builder() {
  reg_paths=$1
  tags=$2

  output=""
  for reg_path in ${reg_paths//,/ }; do
    for tag in ${tags//,/ }; do
      output="${output} ${reg_path}:${tag}"
    done
  done

  echo "$output"
}

_image_path_tag_builder() {
  image_paths=$1
  tag=$2

  output=""
  for image_path in ${image_paths}; do
    output="${output} ${tag} ${image_path}"
  done

  echo "$output"
}

build_image() {
  if [ -z "$DOCKER_BIN" ]; then
    echo "No valid docker executable was found"
    exit 1
  fi
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

  image_paths=$(_image_path_list_builder "$reg_paths" "$tags")

  if [[ "${is_local}" -eq 1 ]]; then
    platforms="${DEFAULT_PLATFORM}"
  fi

  echo "Building ${image_paths} for platforms \"$platforms\""

  build_dir="."
  cmd_build_args=$(_build_args_builder "$build_args")
  cmd_platforms="--platform ${platforms}"

  if [[ "${OCI_BUILDER}" = "docker" ]]; then
      repo_image_tags=$(_image_path_tag_builder "${image_paths}" "-t")
      BUILDX_NO_DEFAULT_ATTESTATIONS=true DOCKER_BUILDKIT=1 "$DOCKER_BIN" buildx build \
          -f "$dockerfile" \
          ${repo_image_tags} \
          ${cmd_platforms} \
          ${cmd_build_args} \
          --provenance=false \
          --progress=auto \
          -o "${output}" \
          "${build_dir}"
  elif [[ "${OCI_BUILDER}" = "podman" ]]; then
      for image_path in ${image_paths}; do
        "$DOCKER_BIN" manifest rm "${image_path}" || true
        "$DOCKER_BIN" manifest create "${image_path}"
        "$DOCKER_BIN" build \
            --jobs "4" \
            -f "$dockerfile" \
            --manifest "${image_path}" \
            ${cmd_platforms} \
            ${cmd_build_args} \
            "${build_dir}"
      done
      if [[ "${output}" == *"push=true"* ]]; then
          for image_path in ${image_paths}; do
            echo "Pushing ${image_path}"
            "$DOCKER_BIN" manifest push -f v2s2 "${image_path}" "docker://${image_path}"
          done
      fi
  else
      echo "unknown OCI_BUILDER=${OCI_BUILDER} expected docker or podman"
      exit 1
  fi
}

microk8s_image_update() {
  image=${1-""}
  if [ -z "$image" ]; then
    echo "You must supply the image to build in images.yaml"
    exit 1
  fi
  reg_paths=$(yq -o=c ".images.[\"${image}\"].registry_paths" < images.yaml)
  tags=$(yq -o=c ".images.[\"${image}\"].tags" < images.yaml)
  test_tag=$(yq ".images.[\"${image}\"].test_tag" < images.yaml)
  for reg_path in ${reg_paths//,/ }; do
    for tag in ${tags//,/ }; do
      last_tag=${tag}
      docker save "${reg_path}:${tag}" | sudo microk8s.ctr --namespace k8s.io image import -
    done
    docker tag "${reg_path}:${last_tag}" "${reg_path}:${test_tag}"
    docker save "${reg_path}:${test_tag}" | sudo microk8s.ctr --namespace k8s.io image import -
  done
}

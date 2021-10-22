#!/bin/bash
set -eux

# Arguments
OPERATOR_IMAGE_ACCOUNT=${OPERATOR_IMAGE_ACCOUNT:-jujusolutions}
JUJUDB_SNAP_RISK=${JUJUDB_SNAP_RISK:-stable}
JUJUDB_SNAP_TRACK=${JUJUDB_SNAP_TRACK:-latest}
JUJUDB_VERSION=${JUJUDB_VERSION:-4.0.18}

if [ -z "${OPERATOR_IMAGE_ACCOUNT_PREFIX:-}" ]; then
    if [ "${OPERATOR_IMAGE_ACCOUNT}" = "jujuqabot" ]; then
        OPERATOR_IMAGE_ACCOUNT_PREFIX=jujuqa
    elif [ "${OPERATOR_IMAGE_ACCOUNT}" = "jujusolutions" ]; then
        OPERATOR_IMAGE_ACCOUNT_PREFIX=juju
    else
        echo "Unknown Docker hub account ${OPERATOR_IMAGE_ACCOUNT}"
        exit 1
    fi
fi

VERSION_MAJ_MIN=$(echo ${JUJUDB_VERSION} | cut -d '.' -f 1,2)

IMAGE_AMD64="${OPERATOR_IMAGE_ACCOUNT_PREFIX}amd64/juju-db"
IMAGE_ARM64="${OPERATOR_IMAGE_ACCOUNT_PREFIX}arm64/juju-db"
IMAGE_PPC64LE="${OPERATOR_IMAGE_ACCOUNT_PREFIX}ppc64le/juju-db"
IMAGE_S390X="${OPERATOR_IMAGE_ACCOUNT_PREFIX}s390x/juju-db"
MANIFEST="${OPERATOR_IMAGE_ACCOUNT}/juju-db"

# Build images
docker build \
    --build-arg "SNAP_ARCH=amd64" \
    --build-arg "BASE_ARCH=amd64" \
    --build-arg "SNAP_RISK=${JUJUDB_SNAP_RISK}" \
    --build-arg "SNAP_TRACK=${JUJUDB_SNAP_TRACK}" \
    --build-arg "SNAP_VERSION=${JUJUDB_VERSION}" \
    -t "${IMAGE_AMD64}:${JUJUDB_VERSION}" -t "${IMAGE_AMD64}:${VERSION_MAJ_MIN}" .
docker build \
    --build-arg "SNAP_ARCH=arm64" \
    --build-arg "BASE_ARCH=arm64v8" \
    --build-arg "SNAP_RISK=${JUJUDB_SNAP_RISK}" \
    --build-arg "SNAP_TRACK=${JUJUDB_SNAP_TRACK}" \
    --build-arg "SNAP_VERSION=${JUJUDB_VERSION}" \
    -t "${IMAGE_ARM64}:${JUJUDB_VERSION}" -t "${IMAGE_ARM64}:${VERSION_MAJ_MIN}" .
docker build \
    --build-arg "SNAP_ARCH=ppc64el" \
    --build-arg "BASE_ARCH=ppc64le" \
    --build-arg "SNAP_RISK=${JUJUDB_SNAP_RISK}" \
    --build-arg "SNAP_TRACK=${JUJUDB_SNAP_TRACK}" \
    --build-arg "SNAP_VERSION=${JUJUDB_VERSION}" \
    -t "${IMAGE_PPC64LE}:${JUJUDB_VERSION}" -t "${IMAGE_PPC64LE}:${VERSION_MAJ_MIN}" .
docker build \
    --build-arg "SNAP_ARCH=s390x" \
    --build-arg "BASE_ARCH=s390x" \
    --build-arg "SNAP_RISK=${JUJUDB_SNAP_RISK}" \
    --build-arg "SNAP_TRACK=${JUJUDB_SNAP_TRACK}" \
    --build-arg "SNAP_VERSION=${JUJUDB_VERSION}" \
    -t "${IMAGE_S390X}:${JUJUDB_VERSION}" -t "${IMAGE_S390X}:${VERSION_MAJ_MIN}" .

# Push images
docker push "${IMAGE_AMD64}:${JUJUDB_VERSION}"
docker push "${IMAGE_ARM64}:${JUJUDB_VERSION}"
docker push "${IMAGE_PPC64LE}:${JUJUDB_VERSION}"
docker push "${IMAGE_S390X}:${JUJUDB_VERSION}"

docker push "${IMAGE_AMD64}:${VERSION_MAJ_MIN}"
docker push "${IMAGE_ARM64}:${VERSION_MAJ_MIN}"
docker push "${IMAGE_PPC64LE}:${VERSION_MAJ_MIN}"
docker push "${IMAGE_S390X}:${VERSION_MAJ_MIN}"

# Create manifests
docker manifest create -a "${MANIFEST}:${JUJUDB_VERSION}" \
"${IMAGE_AMD64}:${JUJUDB_VERSION}" \
"${IMAGE_ARM64}:${JUJUDB_VERSION}" \
"${IMAGE_PPC64LE}:${JUJUDB_VERSION}" \
"${IMAGE_S390X}:${JUJUDB_VERSION}"
docker manifest annotate "${MANIFEST}:${JUJUDB_VERSION}" "${IMAGE_AMD64}:${JUJUDB_VERSION}" --arch amd64
docker manifest annotate "${MANIFEST}:${JUJUDB_VERSION}" "${IMAGE_ARM64}:${JUJUDB_VERSION}" --arch arm64
docker manifest annotate "${MANIFEST}:${JUJUDB_VERSION}" "${IMAGE_PPC64LE}:${JUJUDB_VERSION}" --arch ppc64le
docker manifest annotate "${MANIFEST}:${JUJUDB_VERSION}" "${IMAGE_S390X}:${JUJUDB_VERSION}" --arch s390x
docker manifest inspect --verbose "${MANIFEST}:${JUJUDB_VERSION}"
docker manifest push "${MANIFEST}:${JUJUDB_VERSION}"

docker manifest create -a "${MANIFEST}:${VERSION_MAJ_MIN}" \
"${IMAGE_AMD64}:${VERSION_MAJ_MIN}" \
"${IMAGE_ARM64}:${VERSION_MAJ_MIN}" \
"${IMAGE_PPC64LE}:${VERSION_MAJ_MIN}" \
"${IMAGE_S390X}:${VERSION_MAJ_MIN}"
docker manifest annotate "${MANIFEST}:${VERSION_MAJ_MIN}" "${IMAGE_AMD64}:${VERSION_MAJ_MIN}" --arch amd64
docker manifest annotate "${MANIFEST}:${VERSION_MAJ_MIN}" "${IMAGE_ARM64}:${VERSION_MAJ_MIN}" --arch arm64
docker manifest annotate "${MANIFEST}:${VERSION_MAJ_MIN}" "${IMAGE_PPC64LE}:${VERSION_MAJ_MIN}" --arch ppc64le
docker manifest annotate "${MANIFEST}:${VERSION_MAJ_MIN}" "${IMAGE_S390X}:${VERSION_MAJ_MIN}" --arch s390x
docker manifest inspect --verbose "${MANIFEST}:${VERSION_MAJ_MIN}"
docker manifest push "${MANIFEST}:${VERSION_MAJ_MIN}"

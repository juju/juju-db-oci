ARG SNAP_RISK=stable
ARG SNAP_TRACK=latest
ARG SNAP_ARCH
ARG SNAP_VERSION
ARG BASE_ARCH

FROM ubuntu:20.04

RUN apt-get update && apt-get install -y --no-install-recommends jq squashfs-tools curl ca-certificates

WORKDIR /root

ARG SNAP_RISK
ARG SNAP_TRACK
ARG SNAP_ARCH
ARG SNAP_VERSION

RUN curl "https://api.snapcraft.io/v2/snaps/info/juju-db" -s -H "Snap-Device-Series: 16" > snapstore.json
RUN cat snapstore.json | jq -j --arg risk "$SNAP_RISK" --arg track "$SNAP_TRACK" --arg arch "$SNAP_ARCH" --arg version "$SNAP_VERSION" \
    '."channel-map"|map(select(.channel.risk==$risk)|select(.channel.track==$track)|select(.channel.architecture==$arch)|select(.version==$version).download.url)[0]' > download.url
RUN curl $(cat download.url) -L -o juju-db.snap -s -H "Snap-Device-Series: 16"
RUN unsquashfs juju-db.snap

FROM $BASE_ARCH/ubuntu:20.04

COPY --from=0 /root/squashfs-root /

ENTRYPOINT [ /bin/mongod ]

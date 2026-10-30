# UBlue : https://github.com/orgs/ublue-os/packages
# Fedora: https://quay.io/fedora/fedora-bootc
# CentOS: https://quay.io/centos-bootc/centos-bootc
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-nvidia:stable

FROM scratch AS ctx
COPY build_files /
COPY files /files

FROM ${BASE_IMAGE}

# Cache-bust: dcli-bootc passes a content hash of build_files/ and files/ as
# DCLI_BUILD_HASH. Bind-mounted content is not part of podman's layer cache
# key, so without this the customization layer could be silently reused even
# after the build inputs change.
ARG DCLI_BUILD_HASH=dev

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /bin/sh -c 'echo "dcli-bootc build inputs: ${DCLI_BUILD_HASH}" > /tmp/.build-hash' && \
    /ctx/build.sh && \
    ostree container commit

# Verify final image and contents are correct.
RUN bootc container lint

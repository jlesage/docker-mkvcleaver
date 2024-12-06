#
# mkvcleaver Dockerfile
#
# https://github.com/jlesage/docker-mkvcleaver
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG MKVCLEAVER_VERSION=0800
ARG MKVTOOLNIX_VERSION=33.1.0

# Define software download URLs.
ARG MKVCLEAVER_URL=https://www.videohelp.com/download/MKVCleaver_x64_v${MKVCLEAVER_VERSION}.exe
ARG MKVTOOLNIX_URL=https://mkvtoolnix.download/windows/releases/${MKVTOOLNIX_VERSION}/mkvtoolnix-64-bit-${MKVTOOLNIX_VERSION}.7z

# Build MKVCleaver.
FROM alpine:3.17 AS mkvcleaver
ARG MKVCLEAVER_URL
ARG MKVTOOLNIX_URL
COPY src/mkvcleaver /build
RUN /build/build.sh "$MKVCLEAVER_URL" "$MKVTOOLNIX_URL"

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.17-v4.6.7

ARG MKVCLEAVER_VERSION
ARG DOCKER_IMAGE_VERSION

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN \
    add-pkg \
        wine

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/mkvcleaver-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=mkvcleaver /opt/mkvcleaver /opt/mkvcleaver
COPY --from=mkvcleaver /opt/mkvtoolnix /opt/mkvtoolnix
COPY --from=mkvcleaver /defaults /defaults

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "MKVCleaver" && \
    set-cont-env APP_VERSION "$MKVCLEAVER_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Define mountable directories.
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="mkvcleaver" \
      org.label-schema.description="Docker container for MKVCleaver" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-mkvcleaver" \
      org.label-schema.schema-version="1.0"

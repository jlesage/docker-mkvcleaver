#
# mkvcleaver Dockerfile
#
# https://github.com/jlesage/docker-mkvcleaver
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG MKVCLEAVER_VERSION=0802
ARG MKVTOOLNIX_VERSION=33.1.0
ARG MEDIAINFO_VERSION=26.01
ARG WINETRICKS_VERSION=20260125

# Define software download URLs.
ARG MKVCLEAVER_URL=https://blogs.sapib.ca/apps/download/d47a70b2339c4809edd842ebc45d2efc/MKVCleaver_x64_v0802.exe
ARG MKVTOOLNIX_URL=https://mkvtoolnix.download/windows/releases/${MKVTOOLNIX_VERSION}/mkvtoolnix-64-bit-${MKVTOOLNIX_VERSION}.7z
ARG MEDIAINFO_URL=https://mediaarea.net/download/binary/libmediainfo0/${MEDIAINFO_VERSION}/MediaInfo_DLL_${MEDIAINFO_VERSION}_Windows_x64_WithoutInstaller.7z
ARG WINETRICKS_URL=https://github.com/Winetricks/winetricks/archive/refs/tags/${WINETRICKS_VERSION}.tar.gz

# Build winetricks.
FROM alpine:3.18 AS winetricks
ARG WINETRICKS_URL
RUN \
    apk --no-cache add curl make && \
    mkdir /tmp/winetricks && \
    curl -# -L -f "$WINETRICKS_URL" | tar xz --strip 1 -C /tmp/winetricks && \
    DESTDIR=/tmp/winetricks-install make -C /tmp/winetricks install

# Build MKVCleaver.
FROM alpine:3.18 AS mkvcleaver
ARG MKVCLEAVER_URL
ARG MKVTOOLNIX_URL
ARG MEDIAINFO_URL
COPY --from=winetricks /tmp/winetricks-install /
COPY src/mkvcleaver /build
RUN /build/build.sh "$MKVCLEAVER_URL" "$MKVTOOLNIX_URL" "$MEDIAINFO_URL"

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.18-v4.12.6

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

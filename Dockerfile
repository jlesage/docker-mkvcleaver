#
# mkvcleaver Dockerfile
#
# https://github.com/jlesage/docker-mkvcleaver
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.9-v3.5.2

# Define software versions.
ARG MKVTOOLNIX_VERSION=33.1.0
ARG MKVCLEAVER_VERSION=0800

# Define software download URLs.
ARG MKVTOOLNIX_URL=https://mkvtoolnix.download/windows/releases/${MKVTOOLNIX_VERSION}/mkvtoolnix-64-bit-${MKVTOOLNIX_VERSION}.7z
ARG MKVCLEAVER_URL=https://www.videohelp.com/download/MKVCleaver_x64_v${MKVCLEAVER_VERSION}.exe

# Define working directory.
WORKDIR /tmp

# Install Wine.
RUN \
    add-pkg \
        wine-libs \
        wine

# Install MKVCleaver
RUN \
    add-pkg --virtual build-dependencies curl procps grep && \

    echo "Downloading MKVCleaver..." && \
    mkdir /opt/mkvcleaver && \
    DOWNLOAD_UID="$(curl -s -L ${MKVCLEAVER_URL} | egrep -o 'https://[^ ]+MKVCleaver_x64_v[0-9]+\.exe\?r=[a-zA-Z0-9]+' | uniq | cut -d'=' -f2)" && \
    curl -# -L -o /opt/mkvcleaver/MKVCleaver.exe ${MKVCLEAVER_URL}?r=${DOWNLOAD_UID} && \
    chmod 644 /opt/mkvcleaver/MKVCleaver.exe && \

    echo "Starting X server..." && \
    (/usr/bin/Xvfb :0 &) && \
    while ! xdpyinfo -display :0 > /dev/null 2>&1; do sleep 1; done && \

    echo "Installing MKVcleaver..." && \
    # Since we are using the portable version, we just need to launch the
    # executable and wait until it extracts its files.
    # NOTE: WINEDLLOVERRIDES is needed to avoid prompts about installing
    # mono and greko.
    (env WINEPREFIX=/opt/mkvcleaver WINEDLLOVERRIDES="mscoree,mshtml=" wine64 /opt/mkvcleaver/MKVCleaver.exe &) && \
    while [ ! -f /opt/mkvcleaver/mkvcleaver_db.sqlite ]; do sleep 1; done && \
    pkill MKVCleaver.exe && \

    echo "Waiting for wineserver to terminate..." && \
    while ps | grep -v grep | grep -qw wineserver; do sleep 1; done && \

    echo "Stopping X server..." && \
    kill $(cat /tmp/.X0-lock) && \
    while ps | grep -v grep | grep -qw Xvfb; do sleep 1; done && \

    # Adjust some Windows directories.
    rm /opt/mkvcleaver/drive_c/users/root/"My Documents" && \
    rm /opt/mkvcleaver/drive_c/users/root/"My Music" && \
    rm /opt/mkvcleaver/drive_c/users/root/"My Pictures" && \
    rm /opt/mkvcleaver/drive_c/users/root/"My Videos" && \
    mkdir /opt/mkvcleaver/drive_c/users/root/"My Documents" && \
    mkdir /opt/mkvcleaver/drive_c/users/root/"My Music" && \
    mkdir /opt/mkvcleaver/drive_c/users/root/"My Pictures" && \
    mkdir /opt/mkvcleaver/drive_c/users/root/"My Videos" && \
    rm -r /opt/mkvcleaver/drive_c/users/root/Temp && \
    ln -s /config/temp /opt/mkvcleaver/drive_c/users/root/Temp && \

    # Rename Windows user.
    mv /opt/mkvcleaver/drive_c/users/root /opt/mkvcleaver/drive_c/users/app && \
    sed-patch 's|\\root\\|\\app\\|g' /opt/mkvcleaver/user.reg  && \
    sed-patch 's|\\root\\|\\app\\|g' /opt/mkvcleaver/userdef.reg && \

    # Save some stuff outside the container.
    rm /opt/mkvcleaver/mkvcleaver_db.* && \
    ln -s /config/custom.ini /opt/mkvcleaver/custom.ini && \
    ln -s /config/mkvcleaver_db.sqlite /opt/mkvcleaver/mkvcleaver_db.sqlite && \
    ln -s /config/mkvcleaver_db.sqlite-shm /opt/mkvcleaver/mkvcleaver_db.sqlite-shm && \
    ln -s /config/mkvcleaver_db.sqlite-wal /opt/mkvcleaver/mkvcleaver_db.sqlite-wal && \
    mv /opt/mkvcleaver/user.reg /defaults/ && \
    ln -s /config/user.reg /opt/mkvcleaver/user.reg && \
    mv /opt/mkvcleaver/system.reg /defaults/ && \
    ln -s /config/system.reg /opt/mkvcleaver/system.reg && \

    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install MKVToolNix.
RUN \
    add-pkg --virtual build-dependencies curl p7zip && \
    curl -# -L -o mkvtoolnix.7z ${MKVTOOLNIX_URL} && \
    7za x mkvtoolnix.7z && \
    mkdir /opt/mkvtoolnix && \
    mv mkvtoolnix/mkvextract.exe /opt/mkvtoolnix/ && \
    mv mkvtoolnix/mkvmerge.exe /opt/mkvtoolnix/ && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" title="MKVcleaver *">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="MKVcleaver \*">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/mkvcleaver-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="MKVCleaver" \
    WINEPREFIX=/opt/mkvcleaver

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="mkvcleaver" \
      org.label-schema.description="Docker container for MKVCleaver" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-mkvcleaver" \
      org.label-schema.schema-version="1.0"

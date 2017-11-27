#
# mkvcleaver Dockerfile
#
# https://github.com/jlesage/docker-mkvcleaver
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6

# Define software versions.
ARG WINEMONO_VERSION=4.6.4
ARG MKVTOOLNIX_VERSION=17.0.0
ARG MKVCLEAVER_VERSION=0702

# Define software download URLs.
ARG WINEMONO_URL=http://dl.winehq.org/wine/wine-mono/${WINEMONO_VERSION}/wine-mono-${WINEMONO_VERSION}.msi
ARG MKVTOOLNIX_URL=https://mkvtoolnix.download/windows/releases/${MKVTOOLNIX_VERSION}/mkvtoolnix-64-bit-${MKVTOOLNIX_VERSION}.7z
ARG MKVCLEAVER_URL=https://www.videohelp.com/download/MKVCleaver_x64_v${MKVCLEAVER_VERSION}.exe?r=PMTPBTQk
# Define working directory.
WORKDIR /tmp

# Install Wine.
RUN \
    echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories && \
    add-pkg \
        ncurses-libs \
        wine-libs@edge \
        wine@edge

# Initialize wine.
#RUN \
#    echo "Initializing wine..." && \
#    # Start a X server.
#    echo "Starting the X server..." && \
#    (/usr/bin/Xvfb :0 &) && \
#    while ! xdpyinfo -display :0 > /dev/null 2>&1; do sleep 1; done && \
#    # Run wineboot.
#    env DISPLAY=:0 WINEPREFIX=/opt/mkvcleaver wineboot && \
#    # Adjust Windows drives.
#    ln -s /storage /opt/mkvcleaver/dosdevices/d: && \
#    # Adjust some Windows directories.
#    rm /opt/mkvcleaver/drive_c/users/root/"My Documents" && \
#    rm /opt/mkvcleaver/drive_c/users/root/"My Music" && \
#    rm /opt/mkvcleaver/drive_c/users/root/"My Pictures" && \
#    rm /opt/mkvcleaver/drive_c/users/root/"My Videos" && \
#    mkdir /opt/mkvcleaver/drive_c/users/root/"My Documents" && \
#    mkdir /opt/mkvcleaver/drive_c/users/root/"My Music" && \
#    mkdir /opt/mkvcleaver/drive_c/users/root/"My Pictures" && \
#    mkdir /opt/mkvcleaver/drive_c/users/root/"My Videos" && \
#    rm -r /opt/mkvcleaver/drive_c/users/root/Temp && \
#    ln -s /config/temp /opt/mkvcleaver/drive_c/users/root/Temp && \
#    # Wait for wineserver to terminate.
#    echo "Waiting for wineserver to terminate..." && \
#    while ps | grep -v grep | grep -qw wineserver; do sleep 1; done && \
#    # Stop the X server.
#    echo "Stopping the X server..." && \
#    kill $(cat /tmp/.X0-lock) && \
#    while ps | grep -v grep | grep -qw Xvfb; do sleep 1; done && \
#    # Rename Windows user.
#    mv /opt/mkvcleaver/drive_c/users/root /opt/mkvcleaver/drive_c/users/app && \
#    sed-patch 's|\\root\\|\\app\\|g' /opt/mkvcleaver/user.reg  && \
#    sed-patch 's|\\root\\|\\app\\|g' /opt/mkvcleaver/userdef.reg && \
#    # Cleanup.
#    rm -rf /tmp/*

# Install MKVCleaver
RUN \
    add-pkg --virtual build-dependencies curl procps && \

    echo "Dowloading wine mono..." && \
    mkdir -p /usr/share/wine/mono/ && \
    curl -# -L -o /usr/share/wine/mono/wine-mono-${WINEMONO_VERSION}.msi ${WINEMONO_URL} && \

    echo "Downloading MKVCleaver..." && \
    mkdir /opt/mkvcleaver && \
    curl -# -L -o /opt/mkvcleaver/MKVCleaver.exe ${MKVCLEAVER_URL} && \
    chmod 644 /opt/mkvcleaver/MKVCleaver.exe && \

    echo "Starting X server..." && \
    (/usr/bin/Xvfb :0 &) && \
    while ! xdpyinfo -display :0 > /dev/null 2>&1; do sleep 1; done && \

    echo "Installing MKVcleaver..." && \
    # Since we are using the portable version, we just need to launch the
    # executable and wait until it extracts its files.
    (env WINEPREFIX=/opt/mkvcleaver wine64 /opt/mkvcleaver/MKVCleaver.exe &) && \
    while [ ! -f /opt/mkvcleaver/mkvcleaver_db.sqlite ]; do sleep 1; done && \
    pkill MKVCleaver.exe && \

#    echo "Enabling font smoothing..." && \
#    echo 'REGEDIT4' >> fontsmoothing.reg && \
#    echo >> fontsmoothing.reg && \
#    echo '[HKEY_CURRENT_USER\Control Panel\Desktop]' >> fontsmoothing.reg && \
#    echo '"FontSmoothing"="2"' >> fontsmoothing.reg && \
#    echo '"FontSmoothingGamma"=dword:00000578' >> fontsmoothing.reg && \
#    echo '"FontSmoothingOrientation"=dword:00000001' >> fontsmoothing.reg && \
#    echo '"FontSmoothingType"=dword:00000002' >> fontsmoothing.reg && \
#    regedit /s fontsmoothing.reg && \

    echo "Waiting for wineserver to terminate..." && \
    while ps | grep -v grep | grep -qw wineserver; do sleep 1; done && \

    echo "Stopping X server..." && \
    kill $(cat /tmp/.X0-lock) && \
    while ps | grep -v grep | grep -qw Xvfb; do sleep 1; done && \

    # Adjust Windows drives.
#    ln -s /storage /opt/mkvcleaver/dosdevices/d: && \

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
    rm -r /usr/share/wine/mono && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install MKVToolNix.
RUN \
    add-pkg --virtual build-dependencies curl p7zip && \
    curl -# -L -o mkvtoolnix.7z ${MKVTOOLNIX_URL} && \
    7za x mkvtoolnix.7z && \
    mkdir /opt/mkvtoolnix && \
    mv mkvtoolnix/mkvextract.exe /opt/mkvtoolnix/ && \
    mv mkvtoolnix/mkvmerge.exe /opt/mkvtoolnix/ && \
    mv mkvtoolnix/locale /opt/mkvtoolnix/ && \
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
#VOLUME ["/output"]

# Metadata.
LABEL \
      org.label-schema.name="mkvcleaver" \
      org.label-schema.description="Docker container for MKVCleaver" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-mkvcleaver" \
      org.label-schema.schema-version="1.0"

#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Set same default compilation flags as abuild.
function log {
    echo ">>> $*"
}

MKVCLEAVER_URL="${1:-}"
MKVTOOLNIX_URL="${2:-}"

if [ -z "$MKVCLEAVER_URL" ]; then
    log "ERROR: MKVCleaver URL missing."
    exit 1
fi

if [ -z "$MKVTOOLNIX_URL" ]; then
    log "ERROR: MKVToolNix URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    p7zip \
    shadow \
    su-exec \
    wine \
    xvfb-run \

#
# Install MKVCleaver.
#

export WINEPREFIX=/opt/mkvcleaver
export WINEDLLOVERRIDES="mscoree,mshtml="
export XDG_CACHE_HOME=/tmp/xdg_cache

log "Creating Wine environment..."
useradd --system app
mkdir /opt/mkvcleaver
chown app:app /opt/mkvcleaver
su-exec app wineboot
su-exec app wineserver -w
chown -R root:root /opt/mkvcleaver

log "Downloading MKVCleaver..."
DOWNLOAD_UID="$(curl -s -L ${MKVCLEAVER_URL} | egrep -o 'https://[^ ]+MKVCleaver_x64_v[0-9]+\.exe\?r=[a-zA-Z0-9]+' | uniq | cut -d'=' -f2)"
curl -# -L -f -o /opt/mkvcleaver/MKVCleaver.exe ${MKVCLEAVER_URL}?r=${DOWNLOAD_UID}
chmod 644 /opt/mkvcleaver/MKVCleaver.exe

log "Installing MKVCleaver..."
# Since we are using the portable version, we just need to launch the
# executable and wait until it extracts its files.
# NOTE: WINEDLLOVERRIDES is needed to avoid prompts about installing
# mono and greko.
#(env WINEPREFIX=/opt/mkvcleaver WINEDLLOVERRIDES="mscoree,mshtml=" wine64 /opt/mkvcleaver/MKVCleaver.exe &)
xvfb-run wine64 /opt/mkvcleaver/MKVCleaver.exe &
while [ ! -f /opt/mkvcleaver/mkvcleaver_db.sqlite ]; do sleep 1; done
sleep 5
pkill MKVCleaver.exe
wineserver -w

log "Adjusting Wine environment..."

# Enable font smoothing.
wine64 reg add 'HKCU\Control Panel\Desktop' /v FontSmoothing /t REG_SZ /d 2 /f
wine64 reg add 'HKCU\Control Panel\Desktop' /v FontSmoothingGamma /t REG_DWORD /d 0x578 /f
wine64 reg add 'HKCU\Control Panel\Desktop' /v FontSmoothingOrientation /t REG_DWORD /d 1 /f
wine64 reg add 'HKCU\Control Panel\Desktop' /v FontSmoothingType /t REG_DWORD /d 2 /f
wineserver -w

# Save some stuff outside the container.
rm /opt/mkvcleaver/mkvcleaver_db.*
ln -s /config/custom.ini /opt/mkvcleaver/custom.ini
ln -s /config/mkvcleaver_db.sqlite /opt/mkvcleaver/mkvcleaver_db.sqlite
ln -s /config/mkvcleaver_db.sqlite-shm /opt/mkvcleaver/mkvcleaver_db.sqlite-shm
ln -s /config/mkvcleaver_db.sqlite-wal /opt/mkvcleaver/mkvcleaver_db.sqlite-wal

mkdir /defaults
for F in user.reg system.reg; do
    mv /opt/mkvcleaver/"$F" /defaults/
    ln -s /tmp/"$F" /opt/mkvcleaver/"$F"
done

#
# Install MKVToolNix.
#

log "Downloading MKVToolNix..."
curl -# -L -f -o /tmp/mkvtoolnix.7z ${MKVTOOLNIX_URL}

log "Installing MKVToolNix..."
7za -o/tmp x /tmp/mkvtoolnix.7z
mkdir /opt/mkvtoolnix/
cp -v /tmp/mkvtoolnix/mkvextract.exe /opt/mkvtoolnix/
cp -v /tmp/mkvtoolnix/mkvmerge.exe /opt/mkvtoolnix/

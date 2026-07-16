#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo ">>> $*"
}

MKVCLEAVER_URL="${1:-}"
MKVTOOLNIX_URL="${2:-}"
MEDIAINFO_URL="${3:-}"

if [ -z "$MKVCLEAVER_URL" ]; then
    log "ERROR: MKVCleaver URL missing."
    exit 1
fi

if [ -z "$MKVTOOLNIX_URL" ]; then
    log "ERROR: MKVToolNix URL missing."
    exit 1
fi

if [ -z "$MEDIAINFO_URL" ]; then
    log "ERROR: MediaInfo URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    7zip \
    shadow \
    su-exec \
    wine \
    xvfb-run \
    cabextract \
    wget \

#
# Install MKVCleaver.
#

if command -v wine >/dev/null; then
    export WINE=wine
else
    export WINE=wine64
fi
export WINEPREFIX=/opt/mkvcleaver
export WINEDLLOVERRIDES="mscoree,mshtml="
export XDG_CACHE_HOME=/tmp/xdg_cache
export HOME=/tmp

log "Creating Wine environment..."
useradd --system app
mkdir /opt/mkvcleaver
chown app:app /opt/mkvcleaver
su-exec app wineboot -i
su-exec app winecfg -v win7
su-exec app wineserver -w

log "Adjusting Wine environment..."

# MKVCleaver is an AutoIt app with fixed-pixel control sizes. Wine's default
# font metrics are wider than real Windows fonts, which causes truncated
# labels and dialogs that look too small for their content — especially
# noticeable since the 0.8.0.2 GUI refresh. Install only the fonts the app
# actually uses (Tahoma/MS Shell Dlg, Arial, Times New Roman).
log "Installing Windows fonts..."
su-exec app winetricks -q tahoma arial times
su-exec app wineserver -w

log "Enabling font smoothing..."
su-exec app winetricks -q fontsmooth=rgb
su-exec app wineserver -w

# Cleanup log file created by Winetricks.
rm -f "$WINEPREFIX"/winetricks.log

log "Downloading MKVCleaver..."
curl -# -L -f -o /opt/mkvcleaver/MKVCleaver.exe ${MKVCLEAVER_URL}
chmod 644 /opt/mkvcleaver/MKVCleaver.exe

log "Installing MKVCleaver..."
# Since we are using the portable version, we just need to launch the
# executable and wait until it extracts its files.
# NOTE: WINEDLLOVERRIDES is needed to avoid prompts about installing
# mono and greko.
su-exec app xvfb-run "$WINE" /opt/mkvcleaver/MKVCleaver.exe &
while [ ! -f /opt/mkvcleaver/mkvcleaver.db ]; do
    sleep 5
    log "Waiting for installation to terminate..."
done
sleep 5
pkill MKVCleaver.exe
su-exec app wineserver -w

# We are done, change ownership of the Wine prefix.
chown -R root:root "$WINEPREFIX"

# Save some stuff outside the container.
rm /opt/mkvcleaver/mkvcleaver.db*
ln -s /config/custom.ini /opt/mkvcleaver/custom.ini
ln -s /config/mkvcleaver.db /opt/mkvcleaver/mkvcleaver.db
ln -s /config/mkvcleaver.db-shm /opt/mkvcleaver/mkvcleaver.db-shm
ln -s /config/mkvcleaver.db-wal /opt/mkvcleaver/mkvcleaver.db-wal

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
7z -o/tmp x /tmp/mkvtoolnix.7z
mkdir /opt/mkvtoolnix/
cp -v /tmp/mkvtoolnix/mkvextract.exe /opt/mkvtoolnix/
cp -v /tmp/mkvtoolnix/mkvmerge.exe /opt/mkvtoolnix/

#
# Install MediaInfo.
#

log "Downloading MediaInfo..."
curl -# -L -f -o /tmp/mediainfo.7z ${MEDIAINFO_URL}

log "Installing MediaInfo..."
mkdir /tmp/mediainfo
7z -o/tmp/mediainfo x /tmp/mediainfo.7z
cp -v /tmp/mediainfo/MediaInfo.dll /opt/mkvcleaver/

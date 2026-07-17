#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo ">>> $*"
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

MKVCLEAVER_URL="${1:-}"
MKVTOOLNIX_URL="${2:-}"
MEDIAINFO_URL="${3:-}"
MKVCLEAVER_SOURCE_URL="${4:-}"
AUTOIT_URL="${5:-}"

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

if [ -z "$MKVCLEAVER_SOURCE_URL" ]; then
    log "ERROR: MKVCleaver source URL missing."
    exit 1
fi

if [ -z "$AUTOIT_URL" ]; then
    log "ERROR: AutoIt URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    libarchive-tools \
    7zip \
    shadow \
    su-exec \
    wine \
    cabextract \
    wget \
    patch \
    unzip \
    python3 \
    py3-pip \

pip3 install --no-cache-dir \
    autoit-ripper \
    pefile \

if command -v wine >/dev/null; then
    export WINE=wine
else
    export WINE=wine64
fi
export WINEPREFIX=/opt/mkvcleaver
export WINEDLLOVERRIDES="mscoree,mshtml="
export XDG_CACHE_HOME=/tmp/xdg_cache
export HOME=/tmp
export MKVCLEAVER_PORTABLE_DIR="/opt/mkvcleaver/source/64 bit/Portable"

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
# labels and dialogs that look too small for their content.
log "Installing Windows fonts..."
su-exec app winetricks -q tahoma arial times

log "Enabling font smoothing..."
su-exec app winetricks -q fontsmooth=rgb

# Register AutoIt, so its include directory can be used by apps.
su-exec app "$WINE" reg add 'HKCU\Software\AutoIt v3\AutoIt' /v InstallDir /t REG_SZ /d 'Z:\opt\autoit' /f
su-exec app "$WINE" reg add 'HKLM\Software\AutoIt v3\AutoIt' /v InstallDir /t REG_SZ /d 'Z:\opt\autoit' /f

# Done with Wine environment changes. Wait for the Wine server to terminate.
su-exec app wineserver -w

# Cleanup log file created by Winetricks.
rm -f "$WINEPREFIX"/winetricks.log

# Persist Wine registry defaults outside the container.
mkdir /defaults
for F in userdef.reg user.reg system.reg; do
    mv /opt/mkvcleaver/"$F" /defaults/
    ln -s /tmp/"$F" /opt/mkvcleaver/"$F"
done

# Create symlink for the temporary directories.
rm -r "$WINEPREFIX"/drive_c/users/app/Temp
rm -r "$WINEPREFIX"/drive_c/windows/temp
ln -s /tmp "$WINEPREFIX"/drive_c/users/app/Temp
ln -s /tmp "$WINEPREFIX"/drive_c/windows/temp

# We are done, change ownership of the Wine prefix.
chown -R root:root "$WINEPREFIX"

#
# Install MKVCleaver source.
#

log "Downloading MKVCleaver source..."
mkdir /tmp/mkvcleaver-source
curl -# -L -f "$MKVCLEAVER_SOURCE_URL" | bsdtar -xv --strip 1 -C /tmp/mkvcleaver-source

log "Patching MKVCleaver source..."
PATCHES="
    wine-treeview-selection-while-loop.patch
    wine-treeview-selection-internal-functions.patch
    run-from-source-version-string.patch
    about-dialog-images-from-source.patch
    working-dir.patch
    fix-log-color.patch
"
for PATCH in $PATCHES; do
    echo "Applying $PATCH..."
    patch -p1 -d /tmp/mkvcleaver-source < "$SCRIPT_DIR"/"$PATCH"
done

log "Installing MKVCleaver source..."
cp -av /tmp/mkvcleaver-source /opt/mkvcleaver/source

#
# Install MKVCleaver 3rd party dependencies.
#

log "Downloading MKVCleaver..."
curl -# -L -f -o /tmp/MKVCleaver_portable.exe "$MKVCLEAVER_URL"

log "Installing MKVCleaver third-party dependencies..."

/build/extract_portable_deps.py \
    /tmp/MKVCleaver_portable.exe \
    /tmp/mkvcleaver-deps

# Third-party files must sit next to MKVcleaver.au3 (run-from-source guide).
if [ ! -f "$MKVCLEAVER_PORTABLE_DIR/MKVcleaver.au3" ]; then
    log "ERROR: Unexpected MKVCleaver portable directory: $MKVCLEAVER_PORTABLE_DIR"
    exit 1
fi
THIRD_PARTY_DEPS="
    avc2avi.exe
    tc2cfr.exe
    mediainfo_params.sqlite
    MKVCleaver_Help.chm
    sqlite3_x64.dll
"
for DEP in $THIRD_PARTY_DEPS; do
    cp -v /tmp/mkvcleaver-deps/"$DEP" "$MKVCLEAVER_PORTABLE_DIR"/
done

#
# Install AutoIt.
# Used to run the .au3 sources.
#

log "Downloading AutoIt..."
mkdir /tmp/autoit
curl -# -L -f "$AUTOIT_URL" | bsdtar -xv --strip 1 -C /tmp/autoit

log "Installing AutoIt..."
cp -av /tmp/autoit /opt/autoit

# Keep only what is needed at runtime.
rm -r \
    /opt/autoit/Aut2Exe \
    /opt/autoit/Examples \
    /opt/autoit/SciTe \
    /opt/autoit/AutoItX \
    /opt/autoit/Extras \

#
# Install MKVToolNix.
#

log "Downloading MKVToolNix..."
curl -# -L -f -o /tmp/mkvtoolnix.7z "$MKVTOOLNIX_URL"

log "Installing MKVToolNix..."
7z -o/tmp x /tmp/mkvtoolnix.7z
mkdir /opt/mkvtoolnix/
cp -v /tmp/mkvtoolnix/mkvextract.exe /opt/mkvtoolnix/
cp -v /tmp/mkvtoolnix/mkvmerge.exe /opt/mkvtoolnix/

#
# Install MediaInfo.
#

log "Downloading MediaInfo..."
curl -# -L -f -o /tmp/mediainfo.7z "$MEDIAINFO_URL"

log "Installing MediaInfo..."
mkdir /tmp/mediainfo
7z -o/tmp/mediainfo x /tmp/mediainfo.7z
cp -v /tmp/mediainfo/MediaInfo.dll "$MKVCLEAVER_PORTABLE_DIR"/


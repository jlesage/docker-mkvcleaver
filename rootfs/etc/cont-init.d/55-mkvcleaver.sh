#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Read-only template built into the image. Not used as WINEPREFIX at runtime so
# the image can stay root-owned and the container can run with a read-only rootfs.
WINE_TEMPLATE=/opt/mkvcleaver

# Copy default configuration if needed.
[ -f /config/custom.ini ] || cp /defaults/custom.ini /config/

#
# Build a user-owned runtime WINEPREFIX.
#
# Wine only requires the top-level prefix directory to be owned by the user
# running it. Point WINEPREFIX at a writable location and link the static bulk
# from the image template so we never need to chown /opt/mkvcleaver.
#
mkdir "$WINEPREFIX"

# Copy registry files.
for F in userdef.reg user.reg system.reg; do
    cp /defaults/"$F" "$WINEPREFIX"/
done

# Copy the timestamp to avoid update of the prefix.
cp -a "$WINE_TEMPLATE/.update-timestamp" "$WINEPREFIX/.update-timestamp"

# Take ownership of the prefix.
chown -R "$USER_ID:$GROUP_ID" "$WINEPREFIX"

# Create symlinks to the read-only prefix template.
ln -sfn "$WINE_TEMPLATE/drive_c" "$WINEPREFIX/drive_c"
ln -sfn "$WINE_TEMPLATE/dosdevices" "$WINEPREFIX/dosdevices"

# Enable CJK font in Wine if needed.
if is-bool-val-true "${ENABLE_CJK_FONT:-0}"; then
    su-exec app wine64 regedit /defaults/chn_fonts.reg
    su-exec app wineserver -w
fi

# Handle dark mode.
if is-bool-val-true "${DARK_MODE:-0}"; then
    su-exec app wine64 regedit /defaults/wine-breeze-dark.reg
    su-exec app wineserver -w
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4

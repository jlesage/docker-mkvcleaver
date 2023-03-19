#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Copy default configuration if needed.
[ -f /config/custom.ini ] || cp /defaults/custom.ini /config/

# Copy registry files.
for F in user.reg system.reg; do
    cp /defaults/"$F" /tmp/
    chown "$USER_ID:$GROUP_ID" /tmp/"$F"
done

# Wine requires the WINEPREFIX directory to be owned by the user running the
# Windows app.
chown $USER_ID:$GROUP_ID "$WINEPREFIX"

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

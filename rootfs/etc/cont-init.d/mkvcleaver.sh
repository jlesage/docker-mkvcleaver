#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Make sure mandatory directories exist.
mkdir -p /config/temp

# Copy default configuration if needed.
[ -f /config/custom.ini ] || cp /defaults/custom.ini /config/
[ -f /config/user.reg ] || cp /defaults/user.reg /config/
[ -f /config/system.reg ] || cp /defaults/system.reg /config/

# Wine requires the WINEPREFIX directory to be owned by the user running the
# Windows app.
chown $USER_ID:$GROUP_ID "$WINEPREFIX"

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# vim: set ft=sh :

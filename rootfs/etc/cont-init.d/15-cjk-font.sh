#!/bin/sh

#
# NOTE: This script replaces the one from the baseimage.  Wine has its own way
#       of installing and activating CJK font:
#         - Font file is pre-installed under the WINEPREFIX.
#         - Font is installed by applying settings in registry.
# NOTE: Setting the `LANG` environment variable is also enough to properly.
#       display CJK characters.
#
exit 0

# vim:ft=sh:ts=4:sw=4:et:sts=4

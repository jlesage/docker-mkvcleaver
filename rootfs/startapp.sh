#!/bin/sh

if command -v wine >/dev/null; then
    export WINE=wine
else
    export WINE=wine64
fi

cd /storage
exec "$WINE" \
    "Z:\opt\autoit\AutoIt3_x64.exe" \
    "Z:\opt\mkvcleaver\source\64 bit\Portable\MKVcleaver.au3"

# vim:ft=sh:ts=4:sw=4:et:sts=4

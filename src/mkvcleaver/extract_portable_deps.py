#!/usr/bin/env python3
"""
Extract FileInstall payloads from a compiled AutoIt (EA06) portable EXE
without executing it. Uses autoit-ripper.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def clean_name(name: str) -> str:
    """Turn AutoIt FileInstall source paths into simple basenames."""
    if isinstance(name, bytes):
        name = name.decode("utf-8", "replace")
    # Normalize separators and strip relative prefixes.
    name = name.replace("/", "\\")
    base = name.split("\\")[-1].strip()
    return base or "unknown.bin"


def wanted_basename(name: str) -> str | None:
    """
    Map an embedded FileInstall source name to the runtime filename expected
    next to MKVcleaver.au3 (see upstream run-from-source guide).
    """
    base = clean_name(name).lower()
    # Embedded names may differ slightly (e.g. "mkvcleaver help.chm"); output
    # names match what the app loads from @ScriptDir.
    mapping = {
        "avc2avi.exe": "avc2avi.exe",
        "tc2cfr.exe": "tc2cfr.exe",
        "mediainfo_params.sqlite": "mediainfo_params.sqlite",
        "mkvcleaver help.chm": "MKVCleaver_Help.chm",
        "sqlite3_x64.dll": "sqlite3_x64.dll",
    }
    return mapping.get(base)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("exe", type=Path, help="Path to MKVCleaver portable EXE")
    parser.add_argument("outdir", type=Path, help="Directory to write extracted files")
    args = parser.parse_args()

    try:
        from autoit_ripper import AutoItVersion, extract
    except ImportError:
        print("ERROR: autoit-ripper is not installed", file=sys.stderr)
        return 1

    data = args.exe.read_bytes()
    items = extract(data=data, version=AutoItVersion.EA06)
    if not items:
        print("ERROR: no AutoIt resources found in EXE", file=sys.stderr)
        return 1

    args.outdir.mkdir(parents=True, exist_ok=True)
    written: dict[str, int] = {}

    for name, content in items:
        out_name = wanted_basename(name if isinstance(name, str) else name.decode("utf-8", "replace"))
        if not out_name:
            continue
        out_path = args.outdir / out_name
        out_path.write_bytes(content)
        written[out_name] = len(content)
        print(f"extracted {out_name} ({len(content)} bytes)")

    required = [
        "avc2avi.exe",
        "tc2cfr.exe",
        "mediainfo_params.sqlite",
        "MKVCleaver_Help.chm",
        "sqlite3_x64.dll",
    ]
    missing = [r for r in required if r not in written]
    if missing:
        print("ERROR: missing required embedded files:", ", ".join(missing), file=sys.stderr)
        print("Found resources:", file=sys.stderr)
        for name, content in items:
            n = name.decode("utf-8", "replace") if isinstance(name, bytes) else str(name)
            print(f"  {n!r} ({len(content)} bytes)", file=sys.stderr)
        return 1

    print(f"OK: extracted {len(written)} dependency files to {args.outdir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

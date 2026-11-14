#!/bin/sh
# Run from any working directory; LÖVE can only see files inside its source.
set -eu

if [ "$#" -ne 1 ] || [ "$1" != "collect" ]; then
    echo "Usage: sh examples/run.sh collect" >&2
    exit 2
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
root=$(CDPATH= cd -- "$script_dir/.." && pwd -P)
love_bin=${LOVE_BIN:-love}
if ! command -v "$love_bin" >/dev/null 2>&1; then
    echo "LÖVE not found: $love_bin (set LOVE_BIN to its executable)" >&2
    exit 1
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/astra2d-example.XXXXXXXX")
trap 'rm -rf "$tmp"' 0
trap 'exit 1' HUP INT TERM
cp -R "$root/engine" "$tmp/engine"
cp -R "$script_dir/collect/." "$tmp/"
"$love_bin" "$tmp"

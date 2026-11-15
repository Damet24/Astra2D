#!/bin/sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ASTRA_EXAMPLE_SMOKE=1
export ASTRA_EXAMPLE_SMOKE
sh "$script_dir/run.sh" collect

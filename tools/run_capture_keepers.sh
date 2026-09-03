#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# :4/:9 have live PLAY windows; use :5 so we do not cover or kill them.
export DISPLAY="${DISPLAY:-:5}"
exec godot --path . --display-driver x11 --rendering-driver opengl3 --script tools/capture_keepers.gd

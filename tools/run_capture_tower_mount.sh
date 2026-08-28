#!/bin/bash
set -euo pipefail
cd /workspace/emberline-frontier-07
# :4/:9 have live PLAY windows; use :5 so we do not cover or kill them.
export DISPLAY="${DISPLAY:-:5}"
exec /home/box/.local/bin/godot --path . --display-driver x11 --rendering-driver opengl3 --script tools/capture_tower_mount.gd

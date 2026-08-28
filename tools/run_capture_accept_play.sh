#!/bin/bash
set -euo pipefail
cd /workspace/emberline-frontier-07
export DISPLAY="${DISPLAY:-:4}"
exec /home/box/.local/bin/godot --path . --display-driver x11 --rendering-driver opengl3 --script tools/capture_accept_play.gd

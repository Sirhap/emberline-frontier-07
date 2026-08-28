#!/bin/bash
set -euo pipefail
cd /workspace/emberline-frontier-07
export DISPLAY="${DISPLAY:-:5}"
exec /home/box/.local/bin/godot --path . --display-driver x11 --rendering-driver opengl3 --script tools/capture_v19_bolt.gd

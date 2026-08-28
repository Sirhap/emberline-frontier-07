#!/bin/bash
set -euo pipefail
cd /workspace/emberline-frontier-07
# :4 has the live PLAY window; use :5 (same Xvfb+GLX) so we do not cover it.
export DISPLAY="${DISPLAY:-:5}"
exec /home/box/.local/bin/godot --path . --display-driver x11 --rendering-driver opengl3 --script tools/capture_live_qa.gd

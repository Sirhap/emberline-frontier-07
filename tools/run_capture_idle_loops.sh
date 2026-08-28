#!/bin/bash
set -euo pipefail
cd /workspace/emberline-frontier-07
export DISPLAY="${DISPLAY:-:4}"
exec /home/box/godot/Godot_v4.7.2-stable_linux.x86_64 --path . --display-driver x11 --rendering-driver opengl3 --script tools/capture_idle_loops.gd

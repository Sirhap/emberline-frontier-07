#!/bin/bash
set -euo pipefail
export DISPLAY="${DISPLAY:-:5}"
exec /home/box/.local/bin/godot --path /workspace/emberline-frontier-07 --display-driver x11 --rendering-driver opengl3 --script tools/capture_trainer_icons.gd

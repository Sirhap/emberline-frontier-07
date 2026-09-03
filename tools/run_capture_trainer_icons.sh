#!/bin/bash
set -euo pipefail
export DISPLAY="${DISPLAY:-:5}"
exec godot --path . --display-driver x11 --rendering-driver opengl3 --script tools/capture_trainer_icons.gd

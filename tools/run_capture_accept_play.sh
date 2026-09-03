#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DISPLAY="${DISPLAY:-:4}"
exec godot --path . --display-driver x11 --rendering-driver opengl3 --script tools/capture_accept_play.gd

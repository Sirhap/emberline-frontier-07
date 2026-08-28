#!/bin/bash
set -euo pipefail
cd /workspace/emberline-frontier-07
exec /home/box/.local/bin/godot --path /workspace/emberline-frontier-07 --headless --import

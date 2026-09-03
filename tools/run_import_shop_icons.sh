#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec godot --path . --headless --import

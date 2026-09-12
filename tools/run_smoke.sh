#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

if ! command -v "$GODOT" >/dev/null 2>&1 && [[ ! -x "$GODOT" ]]; then
	echo "godot not found; set GODOT to the Godot 4.7 binary" >&2
	exit 1
fi

set +e
"$GODOT" --headless --path . --import
import_code=$?
set -e
if [[ ! -f .godot/global_script_class_cache.cfg ]]; then
	echo "import did not write .godot/global_script_class_cache.cfg (exit $import_code)" >&2
	exit 1
fi

"$GODOT" --headless --path . --script tests/smoke_test.gd

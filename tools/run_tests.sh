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

failed=0
shopt -s nullglob
for script in tests/*_test.gd; do
	echo "==> $script"
	log="$(mktemp)"
	set +e
	"$GODOT" --headless --path . --script "$script" >"$log" 2>&1
	code=$?
	set -e
	cat "$log"
	if [[ $code -ne 0 ]]; then
		echo "FAIL $script (exit $code)" >&2
		failed=1
	elif ! grep -q "PASS" "$log"; then
		echo "FAIL $script (no PASS in output)" >&2
		failed=1
	elif [[ "$script" == *meta_save_test.gd ]] && grep -q "Parse JSON failed" "$log"; then
		echo "FAIL $script (JSON parse ERROR on happy path)" >&2
		failed=1
	fi
	rm -f "$log"
done

if [[ $failed -ne 0 ]]; then
	echo "One or more tests failed." >&2
	exit 1
fi
echo "ALL TESTS PASS"

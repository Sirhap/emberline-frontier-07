#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
IMPORT_TIMEOUT="${IMPORT_TIMEOUT:-180}"
TEST_TIMEOUT="${TEST_TIMEOUT:-120}"

if ! command -v "$GODOT" >/dev/null 2>&1 && [[ ! -x "$GODOT" ]]; then
	echo "godot not found; set GODOT to the Godot 4.7 binary" >&2
	exit 1
fi

# Hard cap so a hung Godot script (paused tree / failed assert / no quit) cannot freeze CI.
run_with_timeout() {
	local secs="$1"
	shift
	if command -v timeout >/dev/null 2>&1; then
		timeout --kill-after=8s "${secs}s" "$@"
		return $?
	fi
	"$@" &
	local pid=$!
	local elapsed=0
	while kill -0 "$pid" 2>/dev/null; do
		if (( elapsed >= secs )); then
			echo "TIMEOUT ${secs}s: $*" >&2
			kill -TERM "$pid" 2>/dev/null || true
			sleep 2
			kill -KILL "$pid" 2>/dev/null || true
			wait "$pid" 2>/dev/null || true
			return 124
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	wait "$pid"
	return $?
}

set +e
run_with_timeout "$IMPORT_TIMEOUT" "$GODOT" --headless --path . --import --quit
import_code=$?
set -e
if [[ $import_code -eq 124 ]]; then
	echo "import timed out after ${IMPORT_TIMEOUT}s" >&2
	exit 1
fi
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
	run_with_timeout "$TEST_TIMEOUT" "$GODOT" --headless --path . --script "$script" >"$log" 2>&1
	code=$?
	set -e
	cat "$log"
	if [[ $code -eq 124 ]]; then
		echo "FAIL $script (timeout ${TEST_TIMEOUT}s — hung Godot did not quit)" >&2
		failed=1
	elif [[ $code -ne 0 ]]; then
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

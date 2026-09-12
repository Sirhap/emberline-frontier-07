#!/usr/bin/env bash
# Optional Windows Desktop package for 老板. Acceptance gate is Linux, not this.
# Frost skins stay in the pck. Does not publish or change Cloudflare Web.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=tools/export_accept_common.sh
source "$(dirname "$0")/export_accept_common.sh"

PRESET="Windows Accept"
OUT_DIR="dist/windows"
BIN_NAME="EmberlineFrontier07.exe"
PCK_NAME="EmberlineFrontier07.pck"
TEMPLATE_NAME="windows_release_x86_64.exe"

GODOT_BIN="$(godot_find_binary)"
TEMPLATE_PATH="$(godot_require_template "$TEMPLATE_NAME")"
echo "godot=$GODOT_BIN"
echo "template=$TEMPLATE_PATH"
echo "NOTE: Windows is optional. The acceptance gate is Linux DISPLAY=:9 (tools/export_linux_accept.sh)."

godot_assert_frost_kept "$PRESET"
godot_ensure_import "$GODOT_BIN"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "running: $GODOT_BIN --headless --path . --export-release \"$PRESET\" $OUT_DIR/$BIN_NAME"
"$GODOT_BIN" --headless --path . --export-release "$PRESET" "$OUT_DIR/$BIN_NAME"

if [[ ! -f "$OUT_DIR/$BIN_NAME" ]]; then
	echo "export did not write $OUT_DIR/$BIN_NAME" >&2
	exit 1
fi
if [[ ! -f "$OUT_DIR/$PCK_NAME" ]]; then
	echo "export did not write $OUT_DIR/$PCK_NAME (embed_pck is false; both files are required)" >&2
	exit 1
fi
godot_assert_frost_in_pck "$OUT_DIR/$PCK_NAME"

SHORTSHA="$(git rev-parse --short HEAD)"
ARCHIVE="dist/windows-accept-${SHORTSHA}.zip"
rm -f "$ARCHIVE"
if command -v zip >/dev/null 2>&1; then
	(cd "$OUT_DIR" && zip -qr "../$(basename "$ARCHIVE")" .)
else
	python3 - "$OUT_DIR" "$ARCHIVE" <<'PY'
import pathlib, sys, zipfile
src = pathlib.Path(sys.argv[1])
dest = pathlib.Path(sys.argv[2])
with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as zf:
    for path in src.rglob("*"):
        if path.is_file():
            zf.write(path, path.relative_to(src).as_posix())
PY
fi

echo ""
echo "=== Windows accept package (optional) ==="
godot_print_file_digest "$OUT_DIR/$BIN_NAME"
godot_print_file_digest "$OUT_DIR/$PCK_NAME"
godot_print_file_digest "$ARCHIVE"
echo ""
echo "Unzip and run $BIN_NAME. Keep the .pck next to the exe."
echo "Acceptance gate remains Linux: ./tools/export_linux_accept.sh"
echo "Web / Cloudflare 包未改动。"

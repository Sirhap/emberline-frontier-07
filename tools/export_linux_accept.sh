#!/usr/bin/env bash
# Linux x86_64 acceptance package for the DISPLAY=:9 gate.
# Frost skins stay in the pck. Does not publish or change Cloudflare Web.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=tools/export_accept_common.sh
source "$(dirname "$0")/export_accept_common.sh"

PRESET="Linux Accept"
OUT_DIR="dist/linux"
BIN_NAME="EmberlineFrontier07.x86_64"
PCK_NAME="EmberlineFrontier07.pck"
TEMPLATE_NAME="linux_release.x86_64"

GODOT_BIN="$(godot_find_binary)"
TEMPLATE_PATH="$(godot_require_template "$TEMPLATE_NAME")"
echo "godot=$GODOT_BIN"
echo "template=$TEMPLATE_PATH"

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
chmod +x "$OUT_DIR/$BIN_NAME"

if [[ ! -f "$OUT_DIR/$PCK_NAME" ]]; then
	echo "export did not write $OUT_DIR/$PCK_NAME (embed_pck is false; both files are required)" >&2
	exit 1
fi
godot_assert_frost_in_pck "$OUT_DIR/$PCK_NAME"

cat > "$OUT_DIR/run-accept.sh" <<'EOF'
#!/usr/bin/env bash
# Acceptance machine uses a virtual screen on DISPLAY=:9.
set -euo pipefail
cd "$(dirname "$0")"
export DISPLAY="${DISPLAY:-:9}"
exec ./EmberlineFrontier07.x86_64 "$@"
EOF
chmod +x "$OUT_DIR/run-accept.sh"

SHORTSHA="$(git rev-parse --short HEAD)"
ARCHIVE="dist/linux-accept-${SHORTSHA}.tar.gz"
rm -f "$ARCHIVE"
tar -C "$OUT_DIR" -czf "$ARCHIVE" .

echo ""
echo "=== Linux accept package ==="
godot_print_file_digest "$OUT_DIR/$BIN_NAME"
godot_print_file_digest "$OUT_DIR/$PCK_NAME"
godot_print_file_digest "$ARCHIVE"
echo ""
echo "验收机跑法 (Linux DISPLAY=:9):"
echo "  tar -xzf $ARCHIVE"
echo "  chmod +x $BIN_NAME run-accept.sh"
echo "  DISPLAY=:9 ./$BIN_NAME"
echo "  # or: ./run-accept.sh"
echo "流程: 选角 → 霜晶皮肤 → 开战技能 1s×8s → 暂停点「设」"
echo "Web / Cloudflare 包未改动。"

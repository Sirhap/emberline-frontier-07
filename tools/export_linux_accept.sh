#!/usr/bin/env bash
# Export Linux x86_64 acceptance desktop package (frost included via Linux Accept preset).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GODOT="${GODOT:-godot}"
TPL_DIR="${HOME}/.local/share/godot/export_templates/4.7.2.stable"
TPL="${TPL_DIR}/linux_release.x86_64"
if [[ ! -f "$TPL" ]]; then
  echo "missing template: $TPL" >&2
  echo "extract templates/linux_release.x86_64 from Godot_v4.7.2-stable_export_templates.tpz" >&2
  exit 1
fi
mkdir -p dist/linux
"$GODOT" --headless --path . --import || true
"$GODOT" --headless --path . --export-release "Linux Accept" dist/linux/EmberlineFrontier07.x86_64
SHA="$(git rev-parse --short HEAD)"
OUT="dist/linux-accept-${SHA}.tar.gz"
install -m 0755 /dev/null dist/linux/RUN_ACCEPT.sh 2>/dev/null || true
cat > dist/linux/RUN_ACCEPT.sh <<'RUN'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export DISPLAY="${DISPLAY:-:9}"
chmod +x ./EmberlineFrontier07.x86_64
echo "DISPLAY=$DISPLAY"
exec ./EmberlineFrontier07.x86_64 "$@"
RUN
chmod +x dist/linux/RUN_ACCEPT.sh dist/linux/EmberlineFrontier07.x86_64
tar -C dist -czf "$OUT" linux
echo "OUT=$OUT"
ls -lh dist/linux "$OUT"
sha256sum "$OUT" dist/linux/EmberlineFrontier07.pck dist/linux/EmberlineFrontier07.x86_64

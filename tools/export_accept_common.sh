#!/usr/bin/env bash
# Shared helpers for desktop acceptance exports. Source from tools/export_*_accept.sh.
# Godot 4.7.stable official template names (extracted from Godot_v4.7-stable_export_templates.tpz):
#   linux_release.x86_64
#   windows_release_x86_64.exe

GODOT_TEMPLATES_VERSION="${GODOT_TEMPLATES_VERSION:-4.7.stable}"
KEEP_FROST_IDS=(frost_warrior frost_armed)

godot_find_binary() {
	if [[ -n "${GODOT:-}" ]]; then
		if [[ -x "$GODOT" ]] || command -v "$GODOT" >/dev/null 2>&1; then
			echo "$GODOT"
			return 0
		fi
		echo "GODOT=$GODOT is not an executable" >&2
		return 1
	fi
	if command -v godot >/dev/null 2>&1; then
		command -v godot
		return 0
	fi
	echo "godot not found; set GODOT to the Godot 4.7 binary" >&2
	return 1
}

godot_template_dirs() {
	local dirs=()
	if [[ -n "${GODOT_EXPORT_TEMPLATES:-}" ]]; then
		dirs+=("$GODOT_EXPORT_TEMPLATES")
	fi
	if [[ -n "${XDG_DATA_HOME:-}" ]]; then
		dirs+=("$XDG_DATA_HOME/godot/export_templates/$GODOT_TEMPLATES_VERSION")
	fi
	dirs+=("$HOME/.local/share/godot/export_templates/$GODOT_TEMPLATES_VERSION")
	dirs+=("$HOME/Library/Application Support/Godot/export_templates/$GODOT_TEMPLATES_VERSION")
	printf '%s\n' "${dirs[@]}"
}

# Print the first existing template path for $1 (basename), or fail with install hint.
godot_require_template() {
	local name="$1"
	local dir path
	while IFS= read -r dir; do
		[[ -z "$dir" ]] && continue
		path="$dir/$name"
		if [[ -f "$path" ]]; then
			echo "$path"
			return 0
		fi
	done < <(godot_template_dirs)

	echo "MISSING Godot $GODOT_TEMPLATES_VERSION export template: $name" >&2
	echo "Godot will not invent a binary. Install the official templates, then retry." >&2
	echo "" >&2
	echo "Looked in:" >&2
	godot_template_dirs | sed 's/^/  /' >&2
	echo "" >&2
	echo "Official file (inside Godot_v4.7-stable_export_templates.tpz → templates/):" >&2
	echo "  $name" >&2
	echo "Copy it to one of those directories (Linux example):" >&2
	echo "  mkdir -p \"\$HOME/.local/share/godot/export_templates/$GODOT_TEMPLATES_VERSION\"" >&2
	echo "  cp $name \"\$HOME/.local/share/godot/export_templates/$GODOT_TEMPLATES_VERSION/\"" >&2
	echo "Or set GODOT_EXPORT_TEMPLATES to the 4.7.stable templates directory." >&2
	echo "Do not download the whole 1.28GiB tpz if you can Range-extract this one file + version.txt." >&2
	return 1
}

godot_ensure_import() {
	local godot_bin="$1"
	if [[ -f .godot/global_script_class_cache.cfg ]]; then
		echo "import cache present (.godot/global_script_class_cache.cfg)"
		return 0
	fi
	echo "running: $godot_bin --headless --path . --import"
	set +e
	"$godot_bin" --headless --path . --import
	local import_code=$?
	set -e
	if [[ ! -f .godot/global_script_class_cache.cfg ]]; then
		echo "import did not write .godot/global_script_class_cache.cfg (exit $import_code)" >&2
		return 1
	fi
}

# Fail if a desktop accept exclude_filter would drop frost packs.
godot_assert_frost_kept() {
	local preset_name="$1"
	python3 - "$preset_name" "${KEEP_FROST_IDS[@]}" <<'PY'
import sys
from pathlib import Path

preset_name = sys.argv[1]
frost_ids = sys.argv[2:]
text = Path("export_presets.cfg").read_text(encoding="utf-8")
sections = text.split("\n[")
block = None
for raw in sections:
    chunk = raw if raw.startswith("[") else "[" + raw
    if f'name="{preset_name}"' in chunk.split("\n[")[0] or (
        f'name="{preset_name}"' in chunk and "exclude_filter=" in chunk
    ):
        if f'name="{preset_name}"' in chunk:
            block = chunk
            break
if block is None:
    sys.exit(f"preset {preset_name!r} not found in export_presets.cfg")
exclude = ""
for line in block.splitlines():
    if line.startswith("exclude_filter="):
        exclude = line.split("=", 1)[1].strip().strip('"')
        break
for frost_id in frost_ids:
    if frost_id in exclude:
        sys.exit(f"{preset_name}: exclude_filter must keep {frost_id}, found it in: {exclude}")
print(f"{preset_name}: frost packs kept ({', '.join(frost_ids)})")
PY
}

godot_print_file_digest() {
	local path="$1"
	if [[ ! -e "$path" ]]; then
		echo "missing $path" >&2
		return 1
	fi
	local bytes
	bytes="$(wc -c < "$path" | tr -d ' ')"
	local digest
	if command -v sha256sum >/dev/null 2>&1; then
		digest="$(sha256sum "$path" | awk '{print $1}')"
	else
		digest="$(shasum -a 256 "$path" | awk '{print $1}')"
	fi
	printf '%s  %s bytes  sha256=%s\n' "$path" "$bytes" "$digest"
}

godot_assert_frost_in_pck() {
	local pck="$1"
	if [[ ! -f "$pck" ]]; then
		echo "pck not found: $pck" >&2
		return 1
	fi
	local frost_id
	for frost_id in "${KEEP_FROST_IDS[@]}"; do
		if ! grep -a -q "$frost_id" "$pck"; then
			echo "ERROR: $pck does not contain $frost_id (frost pack missing from accept package)" >&2
			return 1
		fi
	done
	echo "pck contains frost_warrior and frost_armed"
}

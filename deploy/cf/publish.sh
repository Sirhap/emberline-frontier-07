#!/usr/bin/env bash
# Upload Godot Web build to Cloudflare:
#   small files → Workers Static Assets
#   index.wasm / index.pck → two KV parts each (25 MiB value limit).
#   Do not serve pre-gzipped wasm: CF strips Content-Encoding and the
#   browser then tries to compile gzip bytes as wasm.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CF="$(cd "$(dirname "$0")" && pwd)"
DIST="$ROOT/dist/web"
PUBLIC="$CF/public"
STAGING="$CF/.staging"
NS="7555c2b4079b45169b5816e00debbc37"
CHUNK=$((16 * 1024 * 1024))
HOST="https://emberline.devops9527.dpdns.org"

if [[ ! -f "$DIST/index.wasm" || ! -f "$DIST/index.pck" || ! -f "$DIST/index.html" ]]; then
  echo "missing dist/web export; run:" >&2
  echo "  godot --headless --path . --export-release Web dist/web/index.html" >&2
  exit 1
fi

# WASM-OPT: shrink index.wasm compile payload when binaryen is available.
if command -v wasm-opt >/dev/null 2>&1; then
  BEFORE_WASM_OPT="$(wc -c < "$DIST/index.wasm")"
  wasm-opt -Oz --enable-simd --enable-exception-handling --enable-bulk-memory \
    --enable-sign-ext --enable-mutable-globals --enable-nontrapping-float-to-int \
    --enable-reference-types -o "$DIST/index.wasm.opt" "$DIST/index.wasm"
  mv "$DIST/index.wasm.opt" "$DIST/index.wasm"
  AFTER_WASM_OPT="$(wc -c < "$DIST/index.wasm")"
  echo "WASM_OPT ${BEFORE_WASM_OPT} -> ${AFTER_WASM_OPT}"
else
  echo "WASM_OPT skipped (wasm-opt not installed)"
fi

rm -rf "$PUBLIC" "$STAGING"
mkdir -p "$PUBLIC" "$STAGING"

rsync -a \
  --exclude '*.wasm' \
  --exclude '*.pck' \
  --exclude '*.wasm.gz' \
  --exclude '*.pck.gz' \
  --exclude '*.br' \
  "$DIST/" "$PUBLIC/"

python3 - "$PUBLIC/index.html" <<'PY'
import pathlib, re, sys
html_path = pathlib.Path(sys.argv[1])
text = html_path.read_text(encoding="utf-8")
text = re.sub(
    r'\s*<link rel="preload" href="index\.(wasm|pck)"[^>]*>',
    "",
    text,
)
html_path.write_text(text, encoding="utf-8")
PY

cat > "$PUBLIC/_headers" <<'EOF'
/*
  X-Content-Type-Options: nosniff

/index.html
  Cache-Control: public, max-age=60

/index.js
  Cache-Control: public, max-age=300

/*.png
  Cache-Control: public, max-age=86400

/*.worklet.js
  Cache-Control: public, max-age=300
EOF

python3 - "$DIST" "$STAGING" "$CHUNK" <<'PY'
import pathlib, sys
dist = pathlib.Path(sys.argv[1])
out = pathlib.Path(sys.argv[2])
chunk = int(sys.argv[3])
limit = 25 * 1024 * 1024
for name in ("index.wasm", "index.pck"):
    data = (dist / name).read_bytes()
    sizes = []
    index = 0
    offset = 0
    while offset < len(data):
        part = data[offset : offset + chunk]
        if len(part) > limit:
            raise SystemExit(f"{name} part exceeds KV 25 MiB limit")
        (out / f"{name}.{index}").write_bytes(part)
        sizes.append(str(len(part)))
        index += 1
        offset += chunk
    print(f"split {name} {len(data)} -> {' + '.join(sizes)}")
PY

VERSION="$(shasum -a 256 "$DIST/index.wasm" "$DIST/index.pck" | shasum -a 256 | cut -c1-16)"
WASM_BYTES="$(wc -c < "$DIST/index.wasm" | tr -d " ")"
PCK_BYTES="$(wc -c < "$DIST/index.pck" | tr -d " ")"
echo "ASSET_VERSION=$VERSION WASM_BYTES=$WASM_BYTES PCK_BYTES=$PCK_BYTES"
# Bust static JS cache so a new pck/wasm pairing is not paired with a stale boot script.
python3 - "$PUBLIC/index.html" "$VERSION" <<'PY2'
import pathlib, sys
html_path = pathlib.Path(sys.argv[1])
ver = sys.argv[2]
text = html_path.read_text(encoding="utf-8")
text = text.replace('src="index.js"', f'src="index.js?v={ver}"', 1)
html_path.write_text(text, encoding="utf-8")
PY2


python3 - "$PUBLIC/index.html" <<'PY3'
import pathlib, sys
html_path = pathlib.Path(sys.argv[1])
text = html_path.read_text(encoding="utf-8")
old = "          statusLabel.textContent = \"加载中 \" + Math.min(100, Math.floor((current / total) * 100)) + \"%\";\n"
new = (
"          var pct = Math.min(100, Math.floor((current / total) * 100));\n"
"          statusLabel.textContent = \"加载中 \" + pct + \"%\";\n"
"          if (pct >= 99) {\n"
"            statusLabel.textContent = \"引擎启动中…\";\n"
"            if (!window.__emberInitKick) {\n"
"              window.__emberInitKick = setTimeout(function () {\n"
"                if (statusEl.getAttribute(\"data-mode\") === \"progress\") {\n"
"                  statusLabel.textContent = \"引擎启动中（勿关页）…\";\n"
"                }\n"
"              }, 8000);\n"
"            }\n"
"          }\n"
)
if old in text:
    html_path.write_text(text.replace(old, new, 1), encoding="utf-8")
PY3


python3 - "$PUBLIC/index.html" <<'PY4'
import pathlib, sys
html_path = pathlib.Path(sys.argv[1])
text = html_path.read_text(encoding="utf-8")
text = text.replace('"emscriptenPoolSize":8', '"emscriptenPoolSize":2')
text = text.replace('"godotPoolSize":4', '"godotPoolSize":1')
html_path.write_text(text, encoding="utf-8")
PY4

# Keep GODOT_CONFIG.fileSizes in sync with post-opt wasm/pck bytes.
python3 - "$PUBLIC/index.html" "$DIST/index.wasm" "$DIST/index.pck" <<'PYFS'
import pathlib, re, sys
html_path = pathlib.Path(sys.argv[1])
wasm_n = pathlib.Path(sys.argv[2]).stat().st_size
pck_n = pathlib.Path(sys.argv[3]).stat().st_size
text = html_path.read_text(encoding="utf-8")
text2, n = re.subn(
    r'"fileSizes":\{"index\.pck":\d+,"index\.wasm":\d+\}',
    f'"fileSizes":{{"index.pck":{pck_n},"index.wasm":{wasm_n}}}',
    text,
    count=1,
)
if n != 1:
    raise SystemExit(f"fileSizes patch failed n={n}")
html_path.write_text(text2, encoding="utf-8")
print(f"FILESIZES_PATCH pck={pck_n} wasm={wasm_n}")
PYFS

ls -lh "$STAGING"

node "$CF/assert-stream-pattern.mjs"

echo "upload KV"
for path in "$STAGING"/*; do
  key="$(basename "$path")"
  wrangler kv key put --remote --config "$CF/wrangler.jsonc" --namespace-id "$NS" \
    --path "$path" "$key"
done

echo "deploy worker"

# SERIAL-PRELOAD: init wasm then pck (not Promise.all) to cut peak RAM on shared agents.
python3 - "$PUBLIC/index.js" <<'PYS'
import pathlib, sys, re
p = pathlib.Path(sys.argv[1])
text = p.read_text(encoding="utf-8")
sg = text.find("startGame: function")
window = text[sg:sg + 600] if sg >= 0 else ""
if "this.init(exe).then(function ()" in window and "Promise.all([" not in window:
    print("serial-preload already present")
else:
    pat = re.compile(
        r"return Promise\.all\(\[\s*this\.init\(exe\),\s*this\.preloadFile\(pack, pack\),\s*\]\)\.then\(function \(\) \{\s*return me\.start\.apply\(me\);\s*\}\);",
        re.M,
    )
    text2, n = pat.subn(
        "return this.init(exe).then(function () {\n\t\t\t\t\treturn me.preloadFile(pack, pack);\n\t\t\t\t}).then(function () {\n\t\t\t\t\treturn me.start.apply(me);\n\t\t\t\t});",
        text,
        count=1,
    )
    if n != 1:
        raise SystemExit(f"serial preload pattern not found n={n}")
    p.write_text(text2, encoding="utf-8")
    print("serial-preload applied")
PYS


# GC-YIELD-AFTER-INIT: breathe between wasm compile and pck ArrayBuffer.
python3 - "$PUBLIC/index.js" <<'PYG'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
text = p.read_text(encoding="utf-8")
needle = "return this.init(exe).then(function () {\n\t\t\t\t\treturn me.preloadFile(pack, pack);"
repl = (
    "return this.init(exe).then(function () {\n"
    "\t\t\t\t\treturn new Promise(function (resolve) {\n"
    "\t\t\t\t\t\ttry { if (typeof globalThis.gc === \"function\") { globalThis.gc(); } } catch (e) {}\n"
    "\t\t\t\t\t\tsetTimeout(resolve, 300);\n"
    "\t\t\t\t\t});\n"
    "\t\t\t\t}).then(function () {\n"
    "\t\t\t\t\treturn me.preloadFile(pack, pack);"
)
if "setTimeout(resolve, 50)" in text and "preloadFile(pack, pack)" in text:
    print("gc-yield already present")
elif needle in text:
    p.write_text(text.replace(needle, repl, 1), encoding="utf-8")
    print("gc-yield applied")
else:
    print("gc-yield skipped (pattern missing)")
PYG

# Bust HTML/JS even when wasm/pck bytes unchanged (loader patches).
VERSION="$( (
  shasum -a 256 "$DIST/index.wasm" "$DIST/index.pck" "$PUBLIC/index.js" "$PUBLIC/index.html"
) | shasum -a 256 | cut -c1-16)"
python3 - "$PUBLIC/index.html" "$VERSION" <<'PYV'
import pathlib, sys, re
html_path = pathlib.Path(sys.argv[1])
ver = sys.argv[2]
text = html_path.read_text(encoding="utf-8")
text = re.sub(r'src="index\.js(\?v=[^"]*)?"', f'src="index.js?v={ver}"', text, count=1)
html_path.write_text(text, encoding="utf-8")
print(f"ASSET_VERSION_REHASH={ver}")
PYV

wrangler deploy --config "$CF/wrangler.jsonc" --var "ASSET_VERSION:$VERSION" --var "WASM_BYTES:$WASM_BYTES" --var "PCK_BYTES:$PCK_BYTES"

echo "warmup"
for p in / /index.js /index.wasm /index.pck /index.png; do
  curl -sS -o /dev/null -D - --max-time 120 "$HOST$p" | tr -d '\r' \
    | grep -Ei 'HTTP/|content-type|content-encoding|content-length|x-emberline-cache|cf-cache-status' \
    || true
  echo "----- $p -----"
done

echo "done $HOST  version=$VERSION"

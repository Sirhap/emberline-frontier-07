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
import pathlib, sys
html_path = pathlib.Path(sys.argv[1])
text = html_path.read_text(encoding="utf-8")
preloads = [
    '<link rel="preload" href="index.wasm" as="fetch" type="application/wasm" crossorigin>',
    '<link rel="preload" href="index.pck" as="fetch" crossorigin>',
]
if 'href="index.wasm"' not in text or "rel=\"preload\"" not in text:
    snippet = "\n\t\t" + "\n\t\t".join(preloads)
    needle = "\t</head>"
    if needle not in text:
        raise SystemExit("index.html missing </head>")
    text = text.replace(needle, snippet + "\n" + needle, 1)
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
    part0 = data[:chunk]
    part1 = data[chunk:]
    if len(part0) > limit or len(part1) > limit:
        raise SystemExit(f"{name} part exceeds KV 25 MiB limit")
    (out / f"{name}.0").write_bytes(part0)
    (out / f"{name}.1").write_bytes(part1)
    print(f"split {name} {len(data)} -> {len(part0)} + {len(part1)}")
PY

VERSION="$(shasum -a 256 "$DIST/index.wasm" "$DIST/index.pck" | shasum -a 256 | cut -c1-16)"
echo "ASSET_VERSION=$VERSION"
ls -lh "$STAGING"

echo "upload KV"
for key in index.wasm.0 index.wasm.1 index.pck.0 index.pck.1; do
  wrangler kv key put --config "$CF/wrangler.jsonc" --namespace-id "$NS" --remote \
    --path "$STAGING/$key" "$key"
done

echo "deploy worker"
wrangler deploy --config "$CF/wrangler.jsonc" --var "ASSET_VERSION:$VERSION"

echo "warmup"
for p in / /index.js /index.wasm /index.pck /index.png; do
  curl -sS -o /dev/null -D - --max-time 120 "$HOST$p" | tr -d '\r' \
    | grep -Ei 'HTTP/|content-type|content-encoding|content-length|x-emberline-cache|cf-cache-status' \
    || true
  echo "----- $p -----"
done

echo "done $HOST  version=$VERSION"

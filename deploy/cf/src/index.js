const ORIGIN = "https://devops9527.dpdns.org:9982";
const CHUNK = 16 * 1024 * 1024;

const FILES = {
  "/index.wasm": {
    mime: "application/wasm",
    name: "index.wasm",
    sizeVar: "WASM_BYTES",
  },
  "/index.pck": {
    mime: "application/octet-stream",
    name: "index.pck",
    sizeVar: "PCK_BYTES",
  },
};

function partKeys(name, size) {
  const n = Math.max(1, Math.ceil((size || CHUNK) / CHUNK));
  return Array.from({ length: n }, (_, i) => `${name}.${i}`);
}

const CDN_CACHE = "public, max-age=86400, no-transform";
const BROWSER_CACHE = CDN_CACHE;

function fileSize(env, spec) {
  const n = Number(env[spec.sizeVar] || 0);
  return Number.isFinite(n) && n > 0 ? n : 0;
}

function fileHeaders(spec, source, size, withLength) {
  const headers = new Headers();
  headers.set("content-type", spec.mime);
  headers.set("cache-control", BROWSER_CACHE);
  headers.set("cdn-cache-control", CDN_CACHE);
  headers.set("cloudflare-cdn-cache-control", CDN_CACHE);
  headers.set("x-emberline-cache", source);
  headers.set("x-content-type-options", "nosniff");
  headers.set("accept-ranges", "bytes");
  if (withLength && size > 0) {
    headers.set("content-length", String(size));
  }
  return headers;
}

function responseInit(headers, status) {
  return { status: status || 200, headers, encodeBody: "manual" };
}

function parseRange(header, size) {
  if (!header || size <= 0) {
    return null;
  }
  const m = /^bytes=(\d*)-(\d*)$/i.exec(String(header).trim());
  if (!m) {
    return null;
  }
  let start;
  let end;
  if (m[1] === "") {
    const suffix = Number(m[2]);
    if (!Number.isFinite(suffix) || suffix <= 0) {
      return null;
    }
    start = Math.max(0, size - suffix);
    end = size - 1;
  } else {
    start = Number(m[1]);
    end = m[2] === "" ? size - 1 : Number(m[2]);
  }
  if (!Number.isFinite(start) || !Number.isFinite(end) || start < 0 || start >= size || end < start) {
    return null;
  }
  return { start, end: Math.min(end, size - 1) };
}

async function fromOrigin(path, spec, size) {
  const originRes = await fetch(ORIGIN + path, { method: "GET" });
  if (!originRes.ok || originRes.body == null) {
    return new Response("Bad Gateway", { status: 502 });
  }
  const headers = fileHeaders(spec, "ORIGIN", size, false);
  return new Response(originRes.body, responseInit(headers));
}

// Body production must live on the Response stream, not ctx.waitUntil.
// waitUntil is capped at 30s after the handler returns; a slow client then
// dies after the first 16MiB KV part (Godot progress ≈ 13% of wasm+pck).
// Prefetch at most the next part so wasm+pck in parallel stay under 128MB.
function readableFromWriter(writeFn) {
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  (async () => {
    try {
      await writeFn(writer);
      await writer.close();
    } catch (err) {
      try {
        await writer.abort(err);
      } catch {
        /* already closed */
      }
    }
  })();
  return readable;
}

async function writePart(writer, env, key, from, to) {
  const buf = await env.GAME.get(key, { type: "arrayBuffer" });
  if (buf == null) {
    throw new Error(`missing ${key}`);
  }
  const bytes = new Uint8Array(buf);
  await writer.write(from == null ? bytes : bytes.subarray(from, to));
}

export default {
  async fetch(request, env) {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method Not Allowed", {
        status: 405,
        headers: { allow: "GET, HEAD" },
      });
    }

    const url = new URL(request.url);
    const spec = FILES[url.pathname];
    if (!spec) {
      return new Response("Not Found", { status: 404 });
    }

    const expected = fileSize(env, spec);
    const keys = partKeys(spec.name, expected);
    const range = parseRange(request.headers.get("range"), expected);

    if (range && (range.start > 0 || range.end < expected - 1)) {
      const headers = fileHeaders(spec, "KV-RANGE", range.end - range.start + 1, true);
      headers.set("content-range", `bytes ${range.start}-${range.end}/${expected}`);
      if (request.method === "HEAD") {
        return new Response(null, responseInit(headers, 206));
      }
      const body = readableFromWriter(async (writer) => {
        for (let i = 0; i < keys.length; i += 1) {
          const partStart = i * CHUNK;
          const partEnd = Math.min(expected, partStart + CHUNK);
          const from = Math.max(range.start, partStart);
          const to = Math.min(range.end + 1, partEnd);
          if (from >= to) {
            continue;
          }
          await writePart(writer, env, keys[i], from - partStart, to - partStart);
        }
      });
      return new Response(body, responseInit(headers, 206));
    }

    if (request.method === "HEAD") {
      const probe = await env.GAME.get(keys[0], { type: "arrayBuffer" });
      if (probe == null) {
        const headers = fileHeaders(spec, "MISS", expected, true);
        return new Response(null, responseInit(headers, expected > 0 ? 200 : 404));
      }
      const headers = fileHeaders(spec, "KV-STREAM", expected, true);
      return new Response(null, responseInit(headers));
    }

    const first = await env.GAME.get(keys[0], { type: "arrayBuffer" });
    if (first == null) {
      return fromOrigin(url.pathname, spec, expected);
    }

	// Known exact size: set Content-Length so clients finish (avoid stuck ~99%).
    const headers = fileHeaders(spec, "KV-STREAM", expected, true);
    const body = readableFromWriter(async (writer) => {
      await writer.write(new Uint8Array(first));
      for (let i = 1; i < keys.length; i += 1) {
        await writePart(writer, env, keys[i]);
      }
    });
    return new Response(body, responseInit(headers));
  },
};

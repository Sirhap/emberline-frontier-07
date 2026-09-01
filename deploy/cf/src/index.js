const ORIGIN = "https://devops9527.dpdns.org:9982";
const CHUNK = 16 * 1024 * 1024;

const FILES = {
  "/index.wasm": {
    mime: "application/wasm",
    keys: ["index.wasm.0", "index.wasm.1"],
    sizeVar: "WASM_BYTES",
  },
  "/index.pck": {
    mime: "application/octet-stream",
    keys: ["index.pck.0", "index.pck.1"],
    sizeVar: "PCK_BYTES",
  },
};

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

function streamBody(ctx, writeFn) {
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  ctx.waitUntil(
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
    })(),
  );
  return readable;
}

export default {
  async fetch(request, env, ctx) {
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
    const range = parseRange(request.headers.get("range"), expected);

    if (range && (range.start > 0 || range.end < expected - 1)) {
      const headers = fileHeaders(spec, "KV-RANGE", range.end - range.start + 1, true);
      headers.set("content-range", `bytes ${range.start}-${range.end}/${expected}`);
      if (request.method === "HEAD") {
        return new Response(null, responseInit(headers, 206));
      }
      const body = streamBody(ctx, async (writer) => {
        const from0 = Math.min(range.start, CHUNK);
        const to0 = Math.min(range.end + 1, CHUNK);
        if (from0 < to0) {
          const first = await env.GAME.get(spec.keys[0], { type: "arrayBuffer" });
          if (first == null) {
            throw new Error("missing part 0");
          }
          await writer.write(new Uint8Array(first).subarray(from0, to0));
        }
        const from1 = Math.max(0, range.start - CHUNK);
        const to1 = Math.max(0, range.end + 1 - CHUNK);
        if (from1 < to1) {
          const second = await env.GAME.get(spec.keys[1], { type: "arrayBuffer" });
          if (second == null) {
            throw new Error("missing part 1");
          }
          await writer.write(new Uint8Array(second).subarray(from1, to1));
        }
      });
      return new Response(body, responseInit(headers, 206));
    }

    const restPromises = spec.keys.slice(1).map((key) =>
      env.GAME.get(key, { type: "arrayBuffer" }),
    );
    const first = await env.GAME.get(spec.keys[0], { type: "arrayBuffer" });
    if (first == null) {
      if (request.method === "HEAD") {
        const headers = fileHeaders(spec, "MISS", expected, true);
        return new Response(null, { status: expected > 0 ? 200 : 404, headers });
      }
      return fromOrigin(url.pathname, spec, expected);
    }

    if (request.method === "HEAD") {
      const headers = fileHeaders(spec, "KV-STREAM", expected, true);
      return new Response(null, { status: 200, headers });
    }

    const headers = fileHeaders(spec, "KV-STREAM", expected, false);
    const body = streamBody(ctx, async (writer) => {
      await writer.write(new Uint8Array(first));
      for (const pending of restPromises) {
        const buf = await pending;
        if (buf == null) {
          throw new Error("missing part 1");
        }
        await writer.write(new Uint8Array(buf));
      }
    });
    return new Response(body, responseInit(headers));
  },
};

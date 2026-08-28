const ORIGIN = "https://devops9527.dpdns.org:9982";

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

function fileHeaders(spec, source, size) {
  const headers = new Headers();
  headers.set("content-type", spec.mime);
  headers.set("cache-control", BROWSER_CACHE);
  headers.set("cdn-cache-control", CDN_CACHE);
  headers.set("cloudflare-cdn-cache-control", CDN_CACHE);
  headers.set("x-emberline-cache", source);
  headers.set("x-content-type-options", "nosniff");
  if (size > 0) {
    headers.set("content-length", String(size));
  }
  return headers;
}

function responseInit(headers) {
  return { status: 200, headers, encodeBody: "manual" };
}

async function fromOrigin(path, spec, size) {
  const originRes = await fetch(ORIGIN + path, { method: "GET" });
  if (!originRes.ok || originRes.body == null) {
    return new Response("Bad Gateway", { status: 502 });
  }
  const headers = fileHeaders(spec, "ORIGIN", size);
  const originLen = originRes.headers.get("content-length");
  if (originLen && !headers.has("content-length")) {
    headers.set("content-length", originLen);
  }
  return new Response(originRes.body, responseInit(headers));
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
    const first = await env.GAME.get(spec.keys[0], { type: "arrayBuffer" });
    if (first == null) {
      if (request.method === "HEAD") {
        const headers = fileHeaders(spec, "MISS", expected);
        return new Response(null, { status: expected > 0 ? 200 : 404, headers });
      }
      return fromOrigin(url.pathname, spec, expected);
    }

    const headers = fileHeaders(spec, "KV-STREAM", expected);
    if (request.method === "HEAD") {
      return new Response(null, { status: 200, headers });
    }

    const { readable, writable } = new TransformStream();
    const writer = writable.getWriter();
    ctx.waitUntil(
      (async () => {
        try {
          await writer.write(new Uint8Array(first));
          for (let i = 1; i < spec.keys.length; i++) {
            const buf = await env.GAME.get(spec.keys[i], {
              type: "arrayBuffer",
            });
            if (buf == null) {
              break;
            }
            await writer.write(new Uint8Array(buf));
          }
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

    return new Response(readable, responseInit(headers));
  },
};

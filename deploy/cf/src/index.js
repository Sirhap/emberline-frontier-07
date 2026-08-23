const ORIGIN = "https://devops9527.dpdns.org:9982";

const FILES = {
  "/index.wasm": {
    mime: "application/wasm",
    keys: ["index.wasm.0", "index.wasm.1"],
  },
  "/index.pck": {
    mime: "application/octet-stream",
    keys: ["index.pck.0", "index.pck.1"],
  },
};

const BROWSER_CACHE = "public, max-age=300";

function concatStreams(streams) {
  return new ReadableStream({
    async start(controller) {
      try {
        for (const stream of streams) {
          const reader = stream.getReader();
          for (;;) {
            const { done, value } = await reader.read();
            if (done) break;
            controller.enqueue(value);
          }
        }
        controller.close();
      } catch (err) {
        controller.error(err);
      }
    },
  });
}

function fileHeaders(spec, source) {
  const headers = new Headers();
  headers.set("content-type", spec.mime);
  headers.set("cache-control", BROWSER_CACHE);
  // Versioned Cache API is the edge store. Do not let the HTTP cache in
  // front of the Worker keep a previous body after a deploy.
  headers.set("cdn-cache-control", "no-store");
  headers.set("cloudflare-cdn-cache-control", "no-store");
  headers.set("x-emberline-cache", source);
  headers.set("x-content-type-options", "nosniff");
  return headers;
}

async function bodyFromKv(env, keys) {
  const parts = [];
  for (const key of keys) {
    const stream = await env.GAME.get(key, { type: "stream" });
    if (stream == null) return null;
    parts.push(stream);
  }
  if (parts.length === 1) return parts[0];
  return concatStreams(parts);
}

async function fromOrigin(path, spec) {
  const originRes = await fetch(ORIGIN + path, { method: "GET" });
  if (!originRes.ok || originRes.body == null) {
    console.error(
      JSON.stringify({
        message: "origin fallback failed",
        path,
        status: originRes.status,
      }),
    );
    return new Response("Bad Gateway", { status: 502 });
  }
  return new Response(originRes.body, {
    status: 200,
    headers: fileHeaders(spec, "ORIGIN"),
  });
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

    const cache = caches.default;
    const cacheKey = new Request(
      `https://emberline.assets/${env.ASSET_VERSION || "0"}/raw${url.pathname}`,
      { method: "GET" },
    );

    const hit = await cache.match(cacheKey);
    if (hit) {
      const headers = new Headers(hit.headers);
      headers.set("x-emberline-cache", "HIT");
      if (request.method === "HEAD") {
        return new Response(null, { status: 200, headers });
      }
      return new Response(hit.body, { status: hit.status, headers });
    }

    const body = await bodyFromKv(env, spec.keys);
    if (body == null) {
      if (request.method === "HEAD") {
        return new Response(null, { status: 404 });
      }
      return fromOrigin(url.pathname, spec);
    }

    const headers = fileHeaders(spec, "KV");
    if (request.method === "HEAD") {
      return new Response(null, { status: 200, headers });
    }

    const out = new Response(body, { status: 200, headers });
    ctx.waitUntil(cache.put(cacheKey, out.clone()));
    return out;
  },
};

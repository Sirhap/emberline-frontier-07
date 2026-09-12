import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const src = readFileSync(join(dirname(fileURLToPath(import.meta.url)), "src/index.js"), "utf8");

function fail(msg) {
  console.error(msg);
  process.exit(1);
}

if (src.includes("waitUntil(")) {
  fail(
    "wasm/pck body must stream on the Response, not ctx.waitUntil (30s cap sticks at first 16MB ≈ 13%)",
  );
}
if (src.includes("restPromises") || /keys\.slice\(1\)\.map\(/.test(src)) {
  fail(
    "do not prefetch every remaining KV part as arrayBuffer (wasm+pck in parallel exceeds 128MB)",
  );
}
if (!src.includes('encodeBody: "manual"')) {
  fail('keep encodeBody: "manual"');
}
if (!/GAME\.get\([^)]*arrayBuffer/.test(src)) {
  fail("still fetch KV parts as arrayBuffer, one at a time");
}
console.log("ok");

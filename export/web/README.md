# export/web

`emberline.html` 是 Godot Web 导出用的自定义 HTML 壳（手机全屏、不 preload wasm/pck）。这个目录不是可玩的 Web 包，里面没有 `index.html` / `index.wasm` / `index.pck`。

可玩的 Web 下发在仓库的 `deploy/cf/`：导出到 `dist/web/` 后跑 `./deploy/cf/publish.sh`，由 Cloudflare Worker 按 16MiB 切片流式下发。不要把本目录当成发布目录打开来玩。

# Linux 验收桌面包

验收机是 Linux（`DISPLAY=:9`），Web keepfrost 在 SwiftShader/~9Gi 上会 `LOAD_BLOCKED`。验收闸改走本机桌面导出。

## 导出

需要 Godot 4.7.2 的 `linux_release.x86_64` 模板。

```bash
./tools/export_linux_accept.sh
```

产物：

- `dist/linux/EmberlineFrontier07.x86_64`
- `dist/linux/EmberlineFrontier07.pck`
- `dist/linux/RUN_ACCEPT.sh`
- `dist/linux-accept-<sha>.tar.gz`

`Linux Accept` 预设与 Web keepfrost 同口径排除规则，**保留** `frost_warrior` / `frost_armed`。

## 验收机启动

同机可直接用目录（不必等 release）：

```bash
cd /workspace/emberline-frontier-07/dist/linux
DISPLAY=:9 ./RUN_ACCEPT.sh
```

链路：选角 → 霜晶 1s×8s → 暂停「设」。现网 Web ASSET 不动。

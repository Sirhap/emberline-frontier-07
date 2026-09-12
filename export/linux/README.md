# export/linux

验收门是 **Linux x86_64 桌面包**，不是 Chrome / WASM。验收机虚拟屏是 `DISPLAY=:9`。Web 仍走 Cloudflare dogfood，本目录不改线上 ASSET。

霜晶皮肤 `frost_warrior` / `frost_armed` 打进包，不要从 `Linux Accept` 的 `exclude_filter` 里删掉。

## 打包（开发机）

需要 Godot 4.7 编辑器二进制，以及官方导出模板：

```
linux_release.x86_64
```

放到 `~/.local/share/godot/export_templates/4.7.stable/`（macOS 是 `~/Library/Application Support/Godot/export_templates/4.7.stable/`）。缺文件时从官方 `Godot_v4.7-stable_export_templates.tpz` 的 `templates/` 里抽出这一份和 `version.txt`，不要整包下。模板不在就失败，脚本不会造假二进制。

```bash
./tools/export_linux_accept.sh
```

产物：

- `dist/linux/EmberlineFrontier07.x86_64` — 可执行文件
- `dist/linux/EmberlineFrontier07.pck` — 资源包（必须和二进制同目录）
- `dist/linux/run-accept.sh` — 默认 `DISPLAY=:9` 启动
- `dist/linux-accept-<shortsha>.tar.gz` — 交给验收的压缩包

脚本会打印各文件字节数和 sha256。

## 验收机跑法

```bash
tar -xzf linux-accept-<shortsha>.tar.gz
chmod +x EmberlineFrontier07.x86_64 run-accept.sh
DISPLAY=:9 ./EmberlineFrontier07.x86_64
```

或：

```bash
./run-accept.sh
```

不要用浏览器打开 Web。本包是原生 GL Compatibility 窗口。

流程：

1. 选角屏选出骑士或刺客。
2. 皮肤选霜晶战士（`frost_warrior`），确认出战。
3. 家园点「开始远征」，进战场后放技能：变身约 1s 切入，持械约 8s。
4. HUD「停」或 Esc / P 暂停，点「设」。

通过条件：选角能进、霜晶变身完整、暂停「设」可点。不要用 Chrome LOAD_BLOCKED 当桌面包失败。

## 和 Web 的关系

`export_presets.cfg` 里的 `Web` 预设保持原样。`deploy/cf/publish.sh` 和线上 Worker 不在这条验收路径里。桌面过了不等于 Web 过了；Web 继续当 dogfood。

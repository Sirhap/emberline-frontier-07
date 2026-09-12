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

1. 选角屏选出骑士。BOOT / 设置已过，不要改那条路径。
2. 皮肤选霜晶战士（`frost_warrior`），确认出战。
3. 家园点「开始远征」，进战场后放技能 = T0。输入在 ≤1.2s 解锁，持械约 8s。
4. **T1.2 起只有 3 秒验收护盾**（`FROST_ACCEPT_GUARD = 3.0`：短无敌 + 漏怪/刷怪暂缓）。这 3 秒后即使仍持械，英雄可死、核心可掉。
5. **必须在 T1.2 之后 3 秒内截到三帧（缺一不可）：**
   - `LIVE-MOVE`：相对武装待机有明显位移（走/跑）。
   - `LIVE-JUMP`：腾空跳帧，脚离地 / 收腿，不是贴地站桩。K / 跳钮。持械跳立刻抬约 112px、锁收腿帧约 1.1s，脚下阴影留在原地。倒地/待机竖直持剑不算。
   - `LIVE-ATTACK`：明确挥砍姿态（横出冰剑），HP>0、核心未掉。J / 攻击钮。持械攻击会立刻打断跳跃并锁侧向平挥约 1.1s，画横向冰刃。倒地复活条（「倒地复活」）或躺在核心上的帧不算。
6. 倒地复活条或「核心失守」结算 = 失败证据。HUD「停」或 Esc / P 暂停，点「设」。

通过条件：选角能进；T1.2 起 3 秒内持械三帧都清楚且未倒地/核爆；暂停「设」可点。不要用 Chrome LOAD_BLOCKED 当桌面包失败。

merge 后重测：`./tools/export_linux_accept.sh` 打新包，验收机 `DISPLAY=:9` 跑新 `linux-accept-<shortsha>.tar.gz`，不要用 tip `3d41d1d` 的旧包。

无头自证（有显示时才出 PNG）：

```bash
godot --path . --script tools/capture_frost_armed_window.gd
# dogfood-output/frost-armed-window/LIVE-T0.png
# dogfood-output/frost-armed-window/LIVE-MOVE.png
# dogfood-output/frost-armed-window/LIVE-JUMP.png
# dogfood-output/frost-armed-window/LIVE-ATTACK.png
```

## 和 Web 的关系

`export_presets.cfg` 里的 `Web` 预设保持原样。`deploy/cf/publish.sh` 和线上 Worker 不在这条验收路径里。桌面过了不等于 Web 过了；Web 继续当 dogfood。

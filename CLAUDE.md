# 余烬防线：前线 07

Godot 4.7 Compatibility，视口 1280×720。单局 **1–10 波可玩闭环**：准备 → 作战 → 清场。不是 19 章内容愿景。

Grok / Claude / Cursor 的项目记忆是 `AGENTS.md` 与 `CLAUDE.md`，两份必须逐字相同。改规则同时改这两份（或以 AGENTS.md 为准整文件覆盖 CLAUDE.md）。

## 动手前

- 数字与规则以代码为准：`scripts/main.gd`、`enemy.gd`、`tower.gd`、`hero.gd`。
- 设计文档优先级：`docs/superpowers/specs/2026-08-20-core-rules-run-flow-design.md` > 本文件 > README > `docs/soul-knight-endless-td-design.md`（愿景，冻结）。
- 沿用现有写法。最小改动。不要顺手重构 `main.gd`。
- 不要 `git commit` / `push`，除非用户明确要求。不要提交到 `main` / `master`。不要 `--no-verify` 或强制推送。
- 不要读、打印、编辑 `.env` 或密钥。

## 冻结（不要发明）

不要无素材加新武器 ID、新塔 ID、新 NPC、融合、雇佣兵、Boon / 天赋、多地图、墙、可封闭路径。不要把 `main.gd` 拆 Autoload。Wave 11+ 词缀另开文档。不要给回旋镖/手雷/药水单独发明新机制——全部走现有近战挥砍或远程弹道。

v1 内容：

| 类 | ID |
|---|---|
| 塔 | `pulse` 80 / `burst` 110 / `frost` 90，各 3 级 |
| 武器 | `WeaponCatalog` 全表：`assets/generated/weapons` + 对应 `weapon-fx`。开局 `sword`（空手片 + 叠 `hold-sword` 大宝剑）。第 1 波货架仍是 `pistol`。掉落 `BASIC_IDS` / `BOSS_IDS`。`pulse-pistol` / `arc-cannon` 只有 FX、未进表 |
| NPC | 商人 `merchant`、训练师 `trainer`。走近按 `E` 才出货架 |
| 敌人 | `scout` / `brute` / `runner` / `mage` / 每 5 波 `boss` |

出售返还 `floor(build_cost * 0.60)`，脉冲 = 48。不退升级费。

## 当前闭环

- `WaveDirector`：`PREP` 100s → `COMBAT` → 配额清完且场上无活怪（1.0s 防抖）→ `scrap += 50`，并在核心一侧 `HOME_REWARD_SPOTS` 刷 3 个可捡奖励（废料锭 / 药剂 / 武器）→ 再准备。失败条件只有核心 0。商人 / 训练师在战场北侧各自房间里（南门进），准备期地上有 `SHOP_SHELVES` 货架，点货架可买。刷怪 `4 + wave * 2`（第 1 波 6 只，侦察+偶发跑者，非法师）；间隔 `max(0.40, 0.90 - wave * 0.04)`。
- 开局 300 废料、核心 10、英雄剑、100 血、无冲刺。倒地 4s，在核心附近以 40 血复活。局不结束。
- 双武器槽（元气骑士）：右下角 `WeaponDock` 显示两把，`Q` 或点槽切换。新枪填空槽，两槽都满则替换当前槽。
- 虚拟按键常驻：左下摇杆 `MoveStick`，右下攻击/跳跃/冲刺/交谈。键盘 WASD/J/K/空格/E 仍可用。摇杆优先当瞄准方向。
- 镜头跟随英雄。地板向北扩出商店翼 `SHOP_WING`（y=-400..112），北墙南门进商人 / 训练师房间。核心西侧仍可走 `HOME_HALL`（x=-80..76）。8 垫仍在战场上。
- 建造容量 = 8 个固定垫 `TOWER_PADS`，**不是** 48px 自由格子。垫 7 `(888, 360)` 在车道上，塔只绕行不封路。
- 作战可填空垫（未缩放 `build_cost`）和升级；新买入只在准备且须 `E`。开战 `close_and_refund()` 退未放置持塔。
- 仇恨只在 `enemy.gd`：拉仇欧氏 96px，拴绳 144px，脱仇墙钟 0.40s。没有挡路函数。倒地立刻全场脱仇。
- 漏怪当且仅当 `not _aggro` 且距核心 ≤ 22px。未仇恨迈步停 22px，仇恨停 26px。漏怪不否决清波。
- 活怪顶 40（刷出前检查，不减配额）；子弹一条 FIFO 池 120，闲置禁止 `queue_free`；塔 ≤ 8。
- Tab / HUD 倍速 **只**乘刷怪间隔和清波防抖，不加速敌人 / 塔 / 弹 / 仇恨。准备倒计时不加速。
- 清波写 `user://run.json`（`slots` 与 `shop.rng` 都在 refresh **之后**拍）。战斗中途不存。核心归零或重开都 `delete_run()`。烟测只用 `user://run_smoke.json` / `records_smoke.json`。
- 跳跃：`hero.gd` `JUMP_HEIGHT = 32`。抠图把脚贴画布底之后高度必须留下，设成 0 会看起来没跳。

## 开发者模式

默认关。`F1` 或 `` ` `` 开关。关掉时清无敌。

**按键的唯一源是 `scripts/main.gd` 的 `DEV_CHEATS`。** Overlay 由该表生成，`_handle_dev_key` 按表 `fn` 分发。改键的步骤：

1. 改 `DEV_CHEATS` 一行（`key` / `label` / `desc` / `row` / `fn`）并实现 `fn`。
2. 把同一张 `label` + `desc` 表同步进 **AGENTS.md 和 CLAUDE.md**（两份必须相同）。
3. 跑 `godot --headless --path . --script tests/smoke_test.gd`。烟测会核对 overlay 与两份记忆都含每条 `desc`。

禁止在 overlay 字符串或 `_handle_dev_key` 的 match 里另写一份键表。

| 键 | 效果 |
|---|---|
| F1 / ` | 开关开发者面板 |
| 1 | +500废料 |
| 2 | 满血/满核 |
| 3 | 冲刺 |
| 4 | 开战/跳过准备 |
| 5 | 侦察 |
| 6 | 重装 |
| 7 | Boss |
| 8 | 清怪 |
| 9 | 核心-1 |
| 0 | 无敌 |
| G | 手枪 |
| B | 霰弹 |
| P | 全垫脉冲 |
| [ | 上一把 |
| ] | 下一把 |

开着时额外画出：垫编号 0–7、敌人 96/144 圈、HUD `E n/40  B n/120  T n/8`。面板在 `(16, 280)`，避开摇杆和右侧塔信息。

## 文件地图

- `scripts/main.gd` — 场景、8 垫、弹池、存档、`DEV_CHEATS`
- `scripts/enemy.gd` — 走核心、仇恨、漏怪
- `scripts/hero.gd` — 移动、跳 32px、武器、冲刺、倒地、`debug_god`
- `scripts/tower.gd` — 三种塔、`sell_refund`
- `scripts/shop.gd` / `wave_director.gd` / `weapon_catalog.gd` / `run_save.gd` / `hud.gd`
- `tests/smoke_test.gd` — 无头验收
- `tools/capture_dev.gd` — F1 开着截图
- `export_presets.cfg` — Web 发布预设（nothreads）
- `deploy/openresty-emberline.conf` — 1Panel OpenResty 站点配置

## SSH 与部署

本机 `~/.ssh/config` 别名（不要读/打印/复制 PEM；权限 `600`）：

```
Host xianyu-server
  HostName 101.47.156.248
  User root
  Port 22
  IdentityFile /Users/sirhao/Downloads/login.pem
  IdentitiesOnly yes
```

Godot 4.7 Web **nothreads** 静态站（无需 COOP/COEP）。Web 导出必须 HTTPS（安全上下文），HTTP 会白屏报 `Secure Context missing`。玩：

- **https://emberline.devops9527.dpdns.org/** — Cloudflare Worker。html/js/png 走 Static Assets；`index.wasm` / `index.pck` 超过 25MiB 单文件限制，各切两片进 Workers KV。不要预压缩 wasm（CF 会剥掉 `Content-Encoding`，浏览器会把 gzip 字节当 wasm 编译）。不要走源站直连。
- 源站仍是 `https://devops9527.dpdns.org:9982/`（直连跨境只有十几 KB/s，会卡加载条；仅作备份）。
- Worker：`deploy/cf/`，账号 `devops.local@outlook.com`，脚本 `emberline-web`。改包后跑 `deploy/cf/publish.sh`（压缩、分片、上传 KV、部署）。账号未开通 R2，不要改用 R2。

**不要绑 `devops9527.dpdns.org` 的 80/443**，主域名留给别的站。子域 `emberline.` 只给这个游戏。证书：CF Universal SSL。源站证书仍是 1Panel `devops9527.dpdns.org`（`:9982`，有效至 2026-10-29）。

服务器：Ubuntu + 1Panel OpenResty 容器 `1Panel-openresty-09cZ`（host network）。站点 `/opt/1panel/www/sites/emberline/index`，conf `/opt/1panel/www/conf.d/emberline.conf`（仓库副本 `deploy/openresty-emberline.conf`）。`/opt/1panel/www` 挂到容器 `/www`，`conf.d` 挂到 `/usr/local/openresty/nginx/conf/conf.d`。同机占用：`bvn-game` :9980、`vs` :9981、`xy.devops9527.dpdns.org` :80/:443、`devops9527.dpdns.org` :3001；本游戏只听 **9982**。UFW 已放行 `8000:9999/tcp`。

Web 模板在 macOS `~/Library/Application Support/Godot/export_templates/4.7.stable/web_nothreads_release.zip`。缺文件时从官方 tpz（约 1.28GB）Range 抽出 `web_nothreads_*.zip` + `version.txt`，不要整包下载。

重新发布：

```bash
godot --headless --path . --export-release Web dist/web/index.html
./deploy/cf/publish.sh
# 源站备份（可选）
rsync -avz --delete dist/web/ xianyu-server:/opt/1panel/www/sites/emberline/index/
scp deploy/openresty-emberline.conf xianyu-server:/opt/1panel/www/conf.d/emberline.conf
ssh xianyu-server 'docker exec 1Panel-openresty-09cZ nginx -t && docker exec 1Panel-openresty-09cZ nginx -s reload'
```

`dist/` 不进 git。导出 `variant/thread_support=false`、画布 Adaptive。当前 pck 仍含 MCP addon autoload（Web 上只轮询 `user://`）；不要当运行时依赖。

## 验证

```bash
godot --headless --path . --script tests/smoke_test.gd
```

改 HUD / 垫 / 开发者面板后，用 `godot --path .` 或 `tools/capture_dev.gd` 看画面，不要只靠断言。

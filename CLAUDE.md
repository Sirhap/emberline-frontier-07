# 余烬防线：前线 07

Godot 4.7 Compatibility，视口 1280×720。单局 **1–10 波可玩闭环**：准备 → 作战 → 清场。不是 19 章内容愿景。

Grok / Claude / Cursor 的项目记忆是 `AGENTS.md` 与 `CLAUDE.md`，两份必须逐字相同。改规则同时改这两份（或以 AGENTS.md 为准整文件覆盖 CLAUDE.md）。

## 动手前

- 数字与规则以代码为准：`scripts/main.gd`、`enemy.gd`、`tower.gd`、`hero.gd`。
- 设计文档优先级：`docs/character-progression-home-hub-implementation.md`（人物等级/天赋/家园目标）> `docs/superpowers/specs/2026-08-20-core-rules-run-flow-design.md` > 本文件 > README > `docs/soul-knight-endless-td-design.md`（愿景，冻结）。
- 沿用现有写法。最小改动。不要顺手重构 `main.gd`。
- 不要 `git commit` / `push`，除非用户明确要求。不要提交到 `main` / `master`。不要 `--no-verify` 或强制推送。
- 不要读、打印、编辑 `.env` 或密钥。

## 冻结（不要发明）

不要无素材加新武器 ID（设施/NPC 本轮 SK 对标除外）、融合、雇佣兵、多地图、可封闭整图路径。不要把 `main.gd` 拆 Autoload。Wave 11+ 词缀另开文档。不要给回旋镖/手雷/药水单独发明新机制——全部走现有近战挥砍或远程弹道。局内成长是 Lv1–10 + 三选一天赋，**不要**做成跨局永久战力或宠物；生产路径禁止战斗内切人（开发者 `H` 除外，且本局不计入 `user://meta.json`）。

人物等级、击杀经验、三选一天赋、家园、人物选择、武器/敌人图鉴是 2026-09-01 已明确批准的新目标，按 `docs/character-progression-home-hub-implementation.md` 实现，不受旧核心 spec 的“无天赋/Meta 空”限制。新游戏必须先在启动选人屏选择骑士或刺客；正常战斗中不再切人物。宠物只做“暂未开放”，当前闯关只有 `endless_td` 无尽塔防。

v1 内容：

| 类 | ID |
|---|---|
| 塔 / 设施 | 战斗塔 `pulse` 80 / `frost` 90（放下即开火，不装枪）；全息垫 `hologram` 50（空垫装枪才开火）；设施 `barrier` 60 / `amplifier` 100 / `pulse_clear` 120 / `energy_orb` 90 |
| 武器 | `WeaponCatalog` 全表：`assets/generated/weapons` + 对应 `weapon-fx`。开局 `sword`（空手片 + 叠 `hold-sword` 大宝剑）。第 1 波货架是 pulse / hologram / frost，商人不卖武器。掉落 `BASIC_IDS` / `BOSS_IDS`。`pulse-pistol` / `arc-cannon` 只有 FX、未进表 |
| NPC | 商人 `merchant`、机械师 `mechanic`、导师 `trainer`（素材目录 `mentor`）、召唤师 `summoner`、军官 `officer`（氛围交谈、不卖货）。点金边台座购买，`E` 交谈可选 |
| 英雄 | 点「开始远征」进塔防，默认骑士 `ember_hero`；档案 `last_selected_hero` 为刺客时用 `assassin`。局内 HUD 头像只展示，不切人。骑士/刺客技能仍走冲刺槽：骑士浮剑 `1/2/3` 发，刺客 `3 + skill_level` 影分身（最多 6）。局内 Lv1–10 + 三选一天赋。 |
| 敌人 | `scout` / `brute` / `runner` / `mage`；每 5 波精英重装；每 15 波 `boss`；波尾 3/8 为潮汐波 |

出售返还 `floor(build_cost * 0.60)`，脉冲 = 48。不退升级费。

## 当前闭环

- 入口是 `scenes/app_root.tscn`：冷启动先全屏选人（横排卡：骑士/刺客可玩，其余槽「暂未开放」），所有字走 `assets/fonts/cjk-ui.ttf`，点选中卡「已出战」写入 `last_selected_hero` 再进家园 `HomeHub` + `HomeRoom`。选人卡「皮肤」列出已入库完整包并写入 `last_skin`，不完整的不能选；桌面端选人/家园 F1 或选人「导入」开工坊（战场开发者 `I`），Web 无入口。战斗结束回家园，不再重选。点「开始远征」开新局（档案上次英雄，缺省骑士）。继续远征用存档里的英雄。家园不摆选人石座、不摆传送门。空房间底图烘焙成 `floor-room.png`（夜）和 `floor-room-day.png`（昼）。黑夜家具按 `layout-ref.png` 摆位并锁定；白天换 `office-sheet` / `station-pack` 里还没用过的切片（工位仍是 `desk-coder`）。禁止从 `layout-ref` 整图抠件，禁止把整张参考图当地板，不用农场书架 / 石像 / 沙发。点书架 / BUG 灯牌 / 白板 / 懒人沙发浏览图鉴或提示宠物未开放。家具脚底有空气墙（带高度）：落地挡住，跳跃离地高度达到墙高即可翻过（`JUMP_HEIGHT` 32，滑板/杂物可过，工位/冰箱/书架不可过）；墙上挂件不挡路。家园 `HomeWalker` 可 WASD 走动、K/空格跳跃，不能攻击或放技能，不显示虚拟摇杆；身高对齐「牛来」，不拿战斗武器。烟测仍直接加载 `main.tscn`，默认骑士局。
- `WaveDirector`：`PREP` 50s → `COMBAT` → 配额清完且场上无活怪（1.0s 防抖）→ `scrap += 50`，并在核心一侧 `HOME_REWARD_SPOTS` 刷 3 个传送带奖励（金币 / 药剂 / 武器）→ 再准备。地上奖励不走近吸拾：点选或「拾取」收一件，「丢弃」或 20s 超时进仓库。失败条件：核心 0 **或** 英雄第五次倒地（共复活 4 次）。失败发 `run_finished`，AppRoot 写 `user://meta.json` 后回家园，不 `reload_current_scene()`。上房间、战场、下房间是**三间地牢房**：北 **上房间**机械师+商人，中间 **COMBAT_ROOM** 核心+传送带，南 **下房间**召唤师+军官+导师。上/下房间贴着战场南北墙，中间没有小过道；门口是金护栏开口（准备期可走，翼板挡住）。准备期 `SHOP_SHELVES` 为台座+浮空图标，点台座可买。刷怪 `4 + wave * 2`（潮汐波 ×1.55）；间隔 `max(0.40, 0.90 - wave * 0.04)`。
- 开局 300 金币、核心 10、英雄剑。骑士 Lv1：120 血 / 护甲 2 / 移速 165；刺客 Lv1：105 血 / 护甲 1 / 移速 175。冲刺/影分身已解锁。击杀给局内 XP（漏怪与开发者清怪不给）。升级暂停三选一天赋。导师货架：锻造、技能。机械师：机械修复。召唤师：随机金币/回血/金矿/炸伤；波≥3 可买半价。不再出旧导师生命/能量/护盾循环。倒地后 4 秒以 40 血在核心旁复活，共 4 次；第五次倒地结束本局。HUD「停」或 Esc / P 暂停（天赋选卡期间 Esc 不能关掉三选一）。
- 双武器槽（元气骑士）：右下攻击键左侧一个切换圆钮。点钮或 `Q` 在已填武器槽 0、已填武器槽 1、以及非空炮台手之间循环。新枪填空槽，两槽都满则替换当前槽。炮台手只用于放置，攻击仍用上次选中的武器。骑士 `skill_level` 0/1/2 开火 1/2/3 发当前武器。
- 虚拟按键常驻：左下摇杆 `MoveStick`，右下大圆攻击（无字）+ 跳/冲刺或影分身/交谈圆钮。键盘 WASD/J/K/空格/E 仍可用。摇杆优先当瞄准方向。刺客技能走现有冲刺槽（开局即有）：释放转圈绿阵时身边刷 `3 + skill_level` 个冒泡影分身（最多 6），持续 5s，自动锁敌近战。近战挥砍与冲刺清半径内敌弹。
- 镜头跟随英雄。上房间贴战场北墙、下房间贴战场南墙，只隔墙带，门口换成金护栏开口，不要再铺一段小过道。墙是金边石墙。东扩与南北口按格铺走廊，口是金边石墙上的洞；传送门嵌在洞里（洞内是黑洞，不是地砖），没激活时是封石。最多 6 门（每 90 波多开 1 门），红=激活 / 蓝=闲置。`SpawnPortalNorth` / `NorthW` / `NorthE` / `SpawnPortalSouth` / `SouthW` / `SpawnPortalEast`。原房南墙仍在 y=640。核心西侧仍可走 `HOME_HALL`。镜头钳在 `FLOOR_BOUNDS`。
- 建造容量 = 16 座（全息垫 + 战斗塔 + 设施）。开局战场 `TOWER_PADS` 有空全息垫，点垫把当前武器装上。商人第 1 波卖脉冲 / 全息垫 / 霜钉（脉冲和霜钉放下即开火；全息垫空垫装枪）；第 2 波起货架可能混到脉冲、霜钉和设施。商人不再出爆裂塔。点地砖放下仓库炮台/设施。核心台 `CORE_PLATFORM` 整块不能放。固定炮台放下即打自己的弹；全息垫装上武器后打该武器，空垫不开火。掩体挡怪；增幅器范围加伤；脉冲装置清敌弹；能量装置回冲刺。塔只绕行；掩体可硬挡。
- 塔 120 血（小血条；掩体更高）。未拉英雄仇且距塔 ≤40px 时打塔不绕过。0 血清垫、不退费；走近废垫 E 或点击按 `build_cost` 补建。仓库炮台手仍可点空格放下。
- 准备期走近柜台（约 110px）点货买入。武器进双槽，炮台进英雄仓库（同种叠数）。炮台手点空地砖放下，准备和作战都行。武器手点空全息垫把当前武器装上；点已装枪的全息垫则交换。点固定炮台不装枪。上厅柜台朝南门口、机械师 / 商人站自己柜台后；下厅反向，柜台朝北门口（同一台座图竖直翻转）、召唤师 / 导师站自己柜台后，军官无柜台、与两侧拉开距离。中间过道不摆货摊。买完对应 NPC 跑到该台座播补货动画后回站位（第 1 波 pulse / hologram / frost）。开战不退武器槽。空建造垫是灰金属台+绿箭头；装枪后仍占座。
- 仇恨只在 `enemy.gd`：拉仇欧氏 96px，拴绳 144px，脱仇墙钟 0.40s。倒地立刻全场脱仇。
- 漏怪当且仅当 `not _aggro` 且距核心 ≤ 22px。未仇恨迈步停 22px，仇恨停 26px。漏怪不否决清波。
- 活怪顶 40（刷出前检查，不减配额）；子弹一条 FIFO 池 120，闲置禁止 `queue_free`；塔 ≤ 16。
- Tab / HUD 倍速 **只**乘刷怪间隔和清波防抖，不加速敌人 / 塔 / 弹 / 仇恨。准备倒计时不加速。
- 清波写 `user://run.json` v2（`slots` 与 `shop.rng` 都在 refresh **之后**拍；拍 `hero.progression`，不存派生攻击/最大生命）。战斗中途不存。核心归零、英雄第五次倒地或重开都 `delete_run()`。跨局资料在 `user://meta.json`。烟测只用 `user://run_smoke.json` / `records_smoke.json` / `meta_smoke.json`。
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
| 1 | +500金币 |
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
| P | 仓库铺满脉冲 |
| T | +1脉冲仓库 |
| Y | 炮台手 |
| F | 锻造+1 |
| N | 技能+1 |
| [ | 上一把 |
| ] | 下一把 |
| H | 切换英雄 |
| M | 装上炮台 |
| I | 打开皮肤英雄导入 |

开着时额外画出：敌人 96/144 圈、HUD `E n/40  B n/120  T n/16`。面板在 `(16, 280)`，避开摇杆和右侧塔信息。

## 文件地图

- `scripts/app_root.gd` / `scenes/app_root.tscn` — 进程入口：家园 → 战场
- `scripts/pack_studio.gd` / `scenes/ui/pack_studio.tscn` / `scripts/hero_pack_importer.gd` — 游戏内皮肤/英雄导入工坊
- `scripts/home_hub.gd` / `scripts/home_room.gd` / `assets/generated/home/` — 家园视觉单独拼接，不引用战场地板
- `scripts/codex_panel.gd` / `scripts/character_progression.gd` / `scripts/talent_catalog.gd` / `scripts/meta_save.gd`
- `scripts/main.gd` — 场景、地砖放塔、弹池、存档、`DEV_CHEATS`、局内等级
- `scripts/enemy.gd` — 走核心、仇恨、漏怪
- `scripts/hero.gd` — 移动、跳 32px、武器、冲刺、倒地、护甲、`debug_god`
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
- Worker：`deploy/cf/`，账号 `devops.local@outlook.com`，脚本 `emberline-web`。改包后跑 `deploy/cf/publish.sh`（分片、上传 KV、部署）。账号未开通 R2，不要改用 R2。
- **手机能加载的下发（2026-08-28 实证，后面必须用，不要改回整包）：** Worker 对 wasm/pck 用 TransformStream，每段 `GAME.get(key, arrayBuffer)` 立刻 write，第一段 16MB 到了就回给浏览器。不要等两段拼成整包再 `Response`（国内 5G 会卡在进度 40–80%）。不要 KV `type:"stream"` 拼接，不要 `FixedLengthStream`（中途断），不要 Cache API。`encodeBody: "manual"`；`cache-control` / `cdn-cache-control` 用 `public, max-age=86400, no-transform`（不要 `no-store`）。不要 preload wasm/pck。HEAD 带 Content-Length；GET 流式时 CF 可能剥掉 Content-Length 改 chunked，靠 HTML `fileSizes`。手机须关标签重开。

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

改 HUD / 垫 / 开发者面板 / 房间后，用 `godot --path .` 或 `tools/capture_look.gd` 看画面，不要只靠断言。

## 视觉验收（不要将就）

烟测过、坐标对、能走进去 **不等于** 画面过。用户说「视觉验收」或丢来元气骑士截图时，那张图就是规格，不是参考建议。

本项目画面对标 **元气骑士地牢**：房间必须是战场同一套砖砌出来的（现用 `grid-battlefield-v6.png` 裁砖铺），墙是金边石墙，门是墙上开的洞、地砖从门洞连进去。禁止把 `draw_rect` 色块、青框、灰板走廊当成房间交差。

说「通过」之前必须自己截玩家视角（战场 / 门口 / 房内），问：这帧能不能和战场地砖、和元气骑士截图放在一起，而不像另一个游戏的调试层。不能，就改到能，再截再看。功能对、样子像面板，算没做。

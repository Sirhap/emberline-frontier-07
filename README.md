# 余烬防线：前线 07

Godot 4.7、1280×720。进程入口是 `scenes/app_root.tscn`：冷启动全屏选人（骑士 / 刺客），再进家园，点「开始远征」开塔防。战场是三间地牢房（北上房间、中间 COMBAT_ROOM、南下房间）。50 秒准备 → 作战 → 清场 +50 金币，核心一侧掉 3 个传送带奖励。闯关模式是无尽塔防 `endless_td`：非固定 5 波通关制，第 10 波后不强制结算。验收与可玩主区间是第 1–10 波。烟测仍直接加载 `main.tscn`，默认骑士局。

## 启动

1. 用 Godot 4.7 打开本目录的 `project.godot`（编辑器会先 import，生成 `.godot/`）。
2. 运行主场景 `scenes/app_root.tscn`。
3. 选人后进家园，点「开始远征」。开局 50 秒准备：走近柜台点金边台座买入。战场开局 `TOWER_PADS` 有空全息垫，点垫把当前武器装上；仓库炮台 / 设施点地砖放下。建造容量 16。倒计时结束自动开战。

## 操作

- 左下虚拟摇杆或 `WASD` / 方向键：移动英雄。
- 右下虚拟键：攻击、跳跃、冲刺 / 影分身、交谈（键盘仍是 `J` / `K` / 空格 / `E`）。
- `Space`：冲刺 / 影分身（开局即有；导师货架升级技能）。
- `J` 或攻击按钮：当前武器开火。
- `Q` 或右下角切换钮：在已填武器槽 0、已填武器槽 1、以及非空炮台手之间循环。
- `K`：短跳（高度 32px）。
- `U`：升级当前选中的塔。
- HUD「出售」：按造价 60% 卖掉选中塔（无热键）。
- `Tab` 或 HUD 速度按钮：切换 1× / 2×。只加快刷怪间隔和清波防抖，不加快敌人 / 塔 / 弹。
- 点空全息垫：把当前武器装上；点已装枪的垫则交换。点地砖放下仓库炮台 / 设施。核心台不能放。
- 点击已部署塔：选中并显示升级 / 出售。
- HUD「停」或 Esc / P：暂停（天赋选卡期间 Esc 不能关掉三选一）。
- `F1` 或 `` ` ``：开发者模式（默认关）。键表见 `scripts/main.gd` 的 `DEV_CHEATS`，与 HUD overlay 同一份。

## 玩法

- 初始 300 金币、核心 10 点生命、开局剑。骑士 Lv1：120 血 / 护甲 2 / 移速 165；刺客 Lv1：105 血 / 护甲 1 / 移速 175。
- 失败：核心归零，**或**英雄第五次倒地（共复活 4 次）。失败写 `user://meta.json` 后回家园，不重载战场。
- 建造容量 16（全息垫 + 战斗塔 + 设施）。开局战场种空全息垫。商人第 1 波卖脉冲 80 / 全息垫 50 / 霜钉 90，不卖爆裂、不卖武器。第 2 波起货架可能混到脉冲、霜钉和设施（掩体 60 / 增幅器 100 / 脉冲装置 120 / 能量装置 90）。出售只退造价的 60%（脉冲 48），不退升级费。
- 脉冲和霜钉放下即开火；全息垫空垫装枪才开火。敌人默认走向核心。只有走进英雄 96px 才拉仇，144px 外 0.4 秒脱仇。贴着核心肉抗且正在仇恨时不漏怪。
- 武器见 `WeaponCatalog`（开局剑，掉落会换成图鉴里的枪、弓、杖、投掷物）；开发者模式 `[` / `]` 循环切换。
- 倒地 4 秒后在核心附近复活并回 40 血，共 4 次。
- 清波写入 `user://run.json` v2。战斗中途不存。核心归零、第五次倒地或重开都删局内存档。跨局资料在 `user://meta.json`。

## 入口—核心约定

主场景 `scenes/app_root.tscn`：选人 → 家园 → `main.tscn` 战场。中间 COMBAT_ROOM 核心在 `(154, 336)`。敌军从南北东传送门进入。塔绕行不封路。`main.gd` 的 `get_route_contract()` 与无头烟测会校验开阔布局。

## 资产与结构

- `assets/generated/`：战场、核心、塔与设施、敌人、投射物、拾取物和界面图标。
- `assets/hero/`：英雄帧；运行时由 XSXB actor 播放。
- `scripts/wave_director.gd`、`shop.gd`、`weapon_catalog.gd`：波次、商店和武器数值。
- `scripts/main.gd`：场景编排、全息垫 / 容量 16、弹池、存档、开发者键表。
- `scripts/hero.gd`：移动、近战、远程、冲刺、倒地复活。跳跃高度 32px。
- `scripts/hud.gd`：中文状态栏、商店、技能、结束结算、开发者面板。
- `scripts/app_root.gd`：选人、家园、进战斗、失败回家。
- `AGENTS.md` / `CLAUDE.md`：给开发者模型的项目记忆，两份必须相同。
- `export/web/emberline.html`：Godot Web 导出用的自定义 HTML 壳，本身不是可玩包。正式 Web 包在 `deploy/cf/`（见该目录与 `export/web/README.md`）。

## 验证

干净克隆没有 `.godot/`，也就没有 `global_script_class_cache.cfg`。只跑 README 旧命令会 Parse Error（缺 `class_name`，例如 `HeroDefinitionCatalog`）。必须先 import。

验收可复跑（复制即用）：

```bash
godot --headless --path . --import
godot --headless --path . --script tests/smoke_test.gd
```

或一条脚本（同样是 import + 烟测）：

```bash
./tools/run_smoke.sh
```

全套 `tests/*_test.gd`（含烟测）：

```bash
./tools/run_tests.sh
```

`GODOT` 环境变量可指向本机二进制（默认 `godot`）。改 HUD / 垫 / 开发者面板 / 房间后，用 `godot --path .` 或 `tools/capture_look.gd` 看画面，不要只靠断言。

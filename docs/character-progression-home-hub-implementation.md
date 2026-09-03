# 人物等级、天赋成长与家园实现规格

日期：2026-09-01  
状态：待实现，本文描述目标行为，不代表当前代码已经完成  
引擎：Godot 4.7 Compatibility  
视口：1280×720  
适用范围：现有 1–10 波无尽塔防闭环 + 新家园入口

## 0. 文档地位与冲突处理

本文是用户 2026-09-01 明确提出的新需求，专门覆盖以下旧冻结项：

- `docs/superpowers/specs/2026-08-20-core-rules-run-flow-design.md` 中“无 Boon / 天赋、无解锁树、Meta 空”的限制。
- `AGENTS.md` 中“开局直接骑士、战斗 HUD 可随时切骑士/刺客”的现状描述。
- `project.godot` 当前直接启动 `main.tscn` 的入口。

除上述明确覆盖项外，旧核心规则继续有效：1–10 波闭环、塔与武器 ID、敌人公式、建造容量、子弹池、仇恨、存档检查点、Web 部署规则均不在本文顺手重做。

实现时的设计文档优先级应为：

1. 本文。
2. `docs/superpowers/specs/2026-08-20-core-rules-run-flow-design.md`。
3. `AGENTS.md` / `CLAUDE.md`。
4. README。
5. `docs/soul-knight-endless-td-design.md` 愿景文档。

## 1. 目标结果

完成后启动流程必须是：

```text
启动应用
  → 家园（未选择人物，不能开始新游戏）
  → 选择骑士或刺客
  → 选择闯关模式
  → 当前只有“无尽塔防”可用
  → 创建新局
  → PREP → COMBAT → 清场循环
  → 击杀获得经验
  → 自动升级并暂停战斗进行三选一天赋
  → 失败结算
  → 写入图鉴/记录
  → 返回家园
```

人物等级是**单局成长**：新局从 1 级开始，失败后清空等级、经验和本局天赋。家园保存图鉴、记录、已解锁人物和上次选择，不永久增加人物战斗强度。

这样既满足人物升级，又不会让长期玩家永久碾压第 1–10 波。

## 2. 明确非目标

本批不要顺手实现：

- 宠物战斗、宠物养成、宠物跟随；家园只显示“暂未开放”。
- 第二种闯关模式、新地图、剧情章节。
- 永久属性点、付费强化、角色升星。
- 新武器 ID、新敌人 ID、融合、雇佣兵。
- 战斗中切换人物。
- 把 `main.gd` 拆成 Autoload。
- 重写现有波次、塔、仇恨、子弹池。

## 3. 术语与状态分层

### 3.1 家园 Meta

跨局保存：

- 已解锁人物。
- 上次选择的人物。
- 武器图鉴发现状态。
- 敌人图鉴发现、击杀和漏怪次数。
- 每个人物的最高单局等级、最高波次、累计击杀、出战次数。
- 每种模式的最高波次。
- 旧 `records.json` 中的历史最高记录。

写入 `user://meta.json`。

### 3.2 单局 Run

只属于当前无尽塔防局：

- 选择的人物和模式。
- 等级、当前经验、天赋层数、天赋 RNG。
- 当前生命、护甲、武器槽、锻造、技能等级。
- 塔、仓库、金币、核心、波次、商店。
- 已击败数量、运行时间。

继续写 `user://run.json`，版本提升到 2。

### 3.3 战场 Field

只存在内存：

- 当前活怪、子弹、攻击动画、技能施法。
- 当前未完成波次的生成进度。
- 天赋选择弹窗的暂停原因。

战斗中途仍不写盘。崩溃后回到上一波清完后的准备期。

## 4. 应用级状态机

新增应用入口状态机：

```text
BOOT
  → HOME_UNSELECTED
  → HOME_SELECTED
  → MODE_SELECT
  → RUN_LOADING
  → RUN_ACTIVE
  → RUN_RESULT
  → HOME_UNSELECTED
```

规则：

1. 应用永远先进入家园，不再直接进入 `main.tscn`。
2. 每次回到家园，新游戏的 `selection_confirmed` 都重置为 `false`。
3. 可以高亮上次使用的人物，但玩家必须主动点击一次人物台座，才算本次选择完成。
4. 未选择人物时，“开始闯关”不可用，并显示“请先选择人物”。
5. 如果存在合法 `run.json`，家园显示“继续上次防线”。继续时使用存档内的人物，不允许重新选人。
6. 如果存在断点局，玩家选择“新游戏”时必须二次确认“新开会覆盖上次断点”。确认后才删除 `run.json`。
7. 结算界面提供“返回家园”，不直接 `reload_current_scene()`。

## 5. 场景组织

不要使用新的 Autoload。使用持久根场景承载场景切换：

```text
res://scenes/app_root.tscn
AppRoot (Node)
  SceneHost (Node)
  FadeLayer (CanvasLayer)
```

`project.godot`：

```ini
[application]
run/main_scene="res://scenes/app_root.tscn"
```

`AppRoot` 的接口保持小而深：

```gdscript
## Opens the home and refreshes profile/codex data.
func show_home() -> void

## Starts or resumes one run from a validated launch configuration.
func start_run(config: RunLaunchConfig) -> void

## Applies one run result to Meta and returns to the home.
func finish_run(result: Dictionary) -> void
```

`main.tscn` 保留为无尽塔防运行场景。新增：

```gdscript
signal run_finished(result: Dictionary)

## Must be called before the scene enters the tree.
func configure_launch(config: RunLaunchConfig) -> void
```

`AppRoot` 先实例化 `main.tscn`，调用 `configure_launch()`，再 `add_child()`，确保 `_ready()` 创建英雄前已经知道人物和模式。

## 6. 人物静态定义

新增 `scripts/hero_definition_catalog.gd`，只保存静态数据，不保存运行状态。

### 6.1 骑士 `ember_hero`

| 字段 | 数值 |
|---|---:|
| 初始生命 | 120 |
| 每级生命成长 | +10 |
| 初始攻击强度 | 100 |
| 每级攻击强度 | +2 |
| 初始防御 | 2 |
| 防御成长 | Lv4 / 7 / 10 各 +1 |
| 初始护甲容量 | 2 |
| 护甲成长 | Lv5 / 9 各 +1 |
| 移速 | 165 |
| 初始武器 | `sword` |
| 技能 | 现有冲刺 |
| 技能等级 | 0–2，对应 1 / 2 / 3 份当前武器攻击 |

### 6.2 刺客 `assassin`

| 字段 | 数值 |
|---|---:|
| 初始生命 | 105 |
| 每级生命成长 | +8 |
| 初始攻击强度 | 105 |
| 每级攻击强度 | +3 |
| 初始防御 | 1 |
| 防御成长 | Lv5 / 9 各 +1 |
| 初始护甲容量 | 1 |
| 护甲成长 | Lv4 / 7 / 10 各 +1 |
| 移速 | 175 |
| 初始武器 | `sword` |
| 技能 | 现有影分身 |
| 技能等级 | 0–3，对应 3 / 4 / 5 / 6 个分身 |

### 6.3 1–10 级派生表

| 等级 | 骑士 HP | 骑士攻击 | 骑士防御 | 骑士护甲 | 刺客 HP | 刺客攻击 | 刺客防御 | 刺客护甲 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 120 | 100 | 2 | 2 | 105 | 105 | 1 | 1 |
| 2 | 130 | 102 | 2 | 2 | 113 | 108 | 1 | 1 |
| 3 | 140 | 104 | 2 | 2 | 121 | 111 | 1 | 1 |
| 4 | 150 | 106 | 3 | 2 | 129 | 114 | 1 | 2 |
| 5 | 160 | 108 | 3 | 3 | 137 | 117 | 2 | 2 |
| 6 | 170 | 110 | 3 | 3 | 145 | 120 | 2 | 2 |
| 7 | 180 | 112 | 4 | 3 | 153 | 123 | 2 | 3 |
| 8 | 190 | 114 | 4 | 3 | 161 | 126 | 2 | 3 |
| 9 | 200 | 116 | 4 | 4 | 169 | 129 | 3 | 3 |
| 10 | 210 | 118 | 5 | 4 | 177 | 132 | 3 | 4 |

攻击强度不是固定伤害，而是人物伤害百分比：100 = 100%，118 = 118%。

## 7. 经验与自动升级

### 7.1 经验来源

任何己方来源击杀都给人物经验，包括英雄、固定塔、全息垫和分身。漏怪、召唤师伤害未击杀、开发者清怪不提供经验。

| 敌人 | XP |
|---|---:|
| `scout` | 5 |
| `runner` | 6 |
| `mage` | 8 |
| `brute` | 10 |
| 精英重装 | 25 |
| `boss` | 60 |

在 `enemy.gd` 增加：

```gdscript
var rank: StringName = &"normal" # normal / elite / boss

func experience_reward() -> int:
	return EnemyCatalog.experience_for(variant, rank)
```

不要依据 `source == hero` 才发经验。塔防里的塔属于玩家，本局只维护一条人物经验。

### 7.2 等级曲线

最高等级：10。

```gdscript
xp_to_next(level) = 40 + 20 * (level - 1)
```

| 到达等级 | 累计 XP |
|---:|---:|
| 2 | 40 |
| 3 | 100 |
| 4 | 180 |
| 5 | 280 |
| 6 | 400 |
| 7 | 540 |
| 8 | 700 |
| 9 | 880 |
| 10 | 1080 |

按当前 `4 + wave * 2`、W3/W8 潮汐、W5/W10 精英的实际配比，零漏全灭推演如下：

| 清完波次 | 本波 XP | 累计 XP | 预期等级 |
|---:|---:|---:|---:|
| 1 | 32 | 32 | 1 |
| 2 | 54 | 86 | 2 |
| 3 | 112 | 198 | 4 |
| 4 | 83 | 281 | 5 |
| 5 | 119 | 400 | 6 |
| 6 | 112 | 512 | 6 |
| 7 | 123 | 635 | 7 |
| 8 | 210 | 845 | 8（接近 9） |
| 9 | 146 | 991 | 9 |
| 10 | 187 | 1178 | 10 |

因此 1–10 波最多触发 9 次天赋选择，平均约每波一次；W3 潮汐波可能在一波内连续升两级，必须正确排队两次选择。

### 7.3 升级顺序

`main._on_enemy_defeated()` 中顺序固定：

1. 从 `_enemies` 移除敌人。
2. 增加击杀、金币、图鉴计数。
3. 调用 `CharacterProgression.award_kill()`。
4. 应用所有跨级基础成长。
5. 若产生待选天赋，当前帧命中/死亡 FX 完成后打开天赋层。
6. 再处理掉落与 HUD。

一次高额经验可以连升多级。使用 `while xp >= xp_to_next(level)`，每升一级 `pending_choices += 1`。天赋选择按等级顺序逐个处理，不能把两次升级合并成一次选择。

到达 Lv10 后：

- XP 条显示 `MAX`。
- 不再累计可见 XP。
- 不再生成天赋选择。

### 7.4 基础成长的生命/护甲结算

升级时先计算旧派生属性和新派生属性：

```text
max_health_delta = new.max_health - old.max_health
armor_delta      = new.armor_capacity - old.armor_capacity
```

- `health += max_health_delta`，不是回满。
- `armor_current += armor_delta`，不超过新容量。
- 防御与攻击立即生效。
- 升级发生在英雄倒地时，增长仍记录；不强制复活。

## 8. 天赋三选一

### 8.1 生成规则

每次升级生成三张不重复卡：

1. 一张攻击类。
2. 一张防御类。
3. 一张功能类。

过滤规则：

- 排除不属于当前人物的专属天赋。
- 排除已经达到 `max_stacks` 的天赋。
- 同一次选择不重复。
- 某分类没有可选项时，从所有未满天赋补位。
- 选择由独立 `talent_rng` 生成，不使用商店或掉落 RNG。
- `talent_rng_state` 写入 `run.json`，保证继续游戏后结果确定。

### 8.2 通用天赋表

新增 `scripts/talent_catalog.gd`，数据字段至少包括：

```gdscript
{
	"id": &"force_training",
	"title": "火力训练",
	"description": "人物造成的全部伤害 +8%",
	"category": &"offense",
	"hero_ids": [],
	"max_stacks": 3,
	"icon": "res://assets/generated/ui/talents/force-training.png",
}
```

| ID | 分类 | 效果 | 上限 |
|---|---|---|---:|
| `force_training` | 攻击 | 人物全部伤害 +8% | 3 |
| `rapid_trigger` | 攻击 | 远程武器冷却 ×0.92 | 3 |
| `blade_training` | 攻击 | 近战与分身近战伤害 +10% | 2 |
| `tempered_body` | 防御 | 最大生命 +15，并补 15 | 3 |
| `composite_armor` | 防御 | 护甲容量 +1，并补 1 | 3 |
| `defensive_posture` | 防御 | 防御 +1 | 3 |
| `swift_step` | 功能 | 移速 +5% | 2 |
| `energy_loop` | 功能 | 技能/冲刺冷却 ×0.90 | 2 |
| `field_medic` | 功能 | 清波时恢复 8% 最大生命 | 2 |
| `scavenger` | 功能 | 击杀金币 +10%，逐只向下取整 | 2 |

### 8.3 骑士专属天赋

| ID | 分类 | 效果 | 上限 |
|---|---|---|---:|
| `knight_counterfire` | 防御 | 消耗护甲时清除人物周围 64px 敌弹 | 1 |
| `knight_overdrive` | 攻击 | 冲刺后 2s 内下一次攻击 +25% 伤害/层 | 2 |
| `knight_dash_guard` | 功能 | 冲刺无敌时间 +0.08s | 2 |

### 8.4 刺客专属天赋

| ID | 分类 | 效果 | 上限 |
|---|---|---|---:|
| `shadow_edge` | 攻击 | 影分身伤害 +15% | 2 |
| `shadow_duration` | 功能 | 影分身持续时间 +0.8s | 2 |
| `shadow_haste` | 功能 | 影分身技能冷却 ×0.88 | 2 |

### 8.5 叠加顺序

人物伤害统一为：

```text
base_weapon_damage
× character_attack_power / 100
× weapon_forge_multiplier
× common_damage_multiplier
× melee_or_ranged_multiplier
× skill_specific_multiplier
× amplifier_multiplier
→ round
→ max(1)
```

禁止在 `main.gd`、`hero.gd`、`hero_projectile.gd` 各乘一遍同一加成。`CharacterProgression.current_stats()` 必须返回已经汇总好的只读 `HeroStats`。

### 8.6 天赋选择暂停

天赋层打开时：

- 敌人、塔、英雄、子弹、波次、清波防抖全部暂停。
- 天赋 UI 使用 `PROCESS_MODE_WHEN_PAUSED`。
- 玩家必须选择，Esc/P 不能关闭。
- 键盘支持 `1 / 2 / 3`，手机支持点卡。
- 多级连升时，选择一张后立刻展示下一组。
- 最后一组完成后恢复进入天赋层之前的暂停状态。

当前 HUD 自己直接写 `tree.paused`。为避免“用户暂停”和“天赋暂停”互相解除，新增深模块 `PauseCoordinator`：

```gdscript
func acquire(reason: StringName) -> void
func release(reason: StringName) -> void
func is_paused_for(reason: StringName) -> bool
```

内部保存 `Dictionary[StringName, bool]`，只要存在任意 reason 就保持 `tree.paused=true`。

## 9. 天赋选择 UI

新增 `scenes/ui/talent_choice_overlay.tscn` 和 `scripts/talent_choice_overlay.gd`。

1280×720 布局：

- 全屏暗幕：黑色 alpha 0.58。
- 标题：`等级提升  /  Lv.04`，中心 `(640, 105)`。
- 三张卡：宽 280，高 340；左上分别约 `(150,170)`、`(500,170)`、`(850,170)`。
- 卡片包含：分类色、48px 图标、名称、效果描述、当前层数、`选择 1/2/3`。
- 攻击类金红、防御类青蓝、功能类青绿。
- 当前无法再叠加的卡不得进入候选，不用做灰色卡。
- 顶部 XP 条在弹窗打开前先播放升级填满动画，再切到下一等级。

视觉必须像元气骑士的像素地牢 UI：金边石/金属框、像素字体、明显选中描边。禁止用默认 Godot 灰按钮交付。

## 10. 人物运行状态独立化

当前 `EmberHero` 同时保存两个人物的 `skill_levels`，并通过 `apply_hero_kind()` 在战斗中重建渲染器。目标行为改为：

1. 新局只创建选中的人物。
2. 运行期间不显示人物切换按钮。
3. `EmberHero` 仍是骑士和刺客共享的控制器与动画驱动。
4. 人物差异来自 `HeroDefinition`、`HeroStats` 和技能分支。
5. 武器槽、锻造、生命、护甲、等级、天赋都属于当前 `HeroRunProgress`。
6. 家园选择另一个人物只影响下一局，不复制上一人物的运行状态。

### 10.1 共享与独立

共享实现：

- 移动、跳跃、受伤、倒地、双武器槽、攻击输入。
- XSXB 渲染器创建流程。
- 子弹、近战、命中停顿接口。
- 等级/天赋模块的接口。

独立数据：

- 静态基础属性与成长公式。
- 当前生命、护甲、等级、XP。
- 当前技能等级、冷却、专属天赋。
- 当前双武器、锻造和仓库。
- Meta 中该人物的记录。

### 10.2 护甲和防御入口

把 `_hero_armor` / `_hero_armor_max` 从 `main.gd` 移入人物运行状态，所有伤害只经过一个入口：

```gdscript
func take_damage(raw_amount: int, context: Dictionary = {}) -> DamageResult
```

顺序：

1. 无敌/倒地判断。
2. 若有护甲，消耗 1 层，伤害减 8；减到 0 则本次生命伤害为 0。
3. 若仍有伤害，再减人物防御。
4. 原始伤害大于 0 且未被护甲完全吸收时，生命伤害至少为 1。
5. 应用受伤无敌和反馈。

敌人接触、敌弹、召唤师炸伤都调用同一接口。

## 11. 与现有商店成长的关系

为了避免同一人物属性存在两套升级来源：

- 保留“锻造”：它是武器成长，不是人物等级。
- 保留“技能提升”：它提升骑士武器份数或刺客分身数。
- 停止在新局货架生成旧“导师·生命/能量/护盾”循环。
- 原导师第三台座可显示人物本局等级说明；v1 不增加新的付费功能。
- 机械修复、召唤师、半价天赋保持现状。

旧 v1 断点存档迁移时：

- `vitality_level × 20` 转为 `legacy_bonus_health`。
- `dash_cd_level` 转为 `legacy_dash_cooldown_level`。
- `armor_max` 转为 `legacy_bonus_armor`。
- 这些字段只为继续旧局存在；新局永远为 0。

## 12. 家园场景

新增：

```text
res://scenes/home/home_hub.tscn
HomeHub (Node2D)
  DungeonRoom
  Stations
    KnightPedestal
    AssassinPedestal
    EndlessPortal
    WeaponCodexShelf
    EnemyCodexShelf
    RecordBoard
    PetNestDisabled
  HeroPreviewSlot
  HomeCamera
  HomeHud (CanvasLayer)
  OverlayHost
```

### 12.1 视觉空间

家园是独立地牢房，不是战场上/下商店房间，也不是纯菜单色块。

- 房间范围建议：`Rect2(96, 72, 1088, 568)`。
- 地面继续裁切 `grid-battlefield-v6.png` 的砖，不画纯色大矩形冒充地板。
- 墙使用现有金边石墙语言。
- 北门是嵌在墙洞里的无尽塔防传送门。
- 两个人物台座位于南侧，朝向中央。
- 武器图鉴和敌人图鉴是东西两侧的实体书架/终端。
- 宠物窝在西南角，覆盖锁链或封条并标“暂未开放”。
- 中央留出人物预览和短距离移动区域。

建议世界坐标：

| 设施 | 坐标 |
|---|---|
| 无尽塔防门 | `(640, 118)` |
| 骑士台座 | `(480, 520)` |
| 刺客台座 | `(620, 520)` |
| 武器图鉴 | `(1040, 245)` |
| 敌人图鉴 | `(1040, 405)` |
| 记录板 | `(220, 245)` |
| 宠物窝 | `(220, 475)` |
| 人物预览出生点 | `(640, 355)` |

### 12.2 选择人物

进入家园时两个人物都在台座播放 idle。

点击台座：

1. 台座亮金边。
2. 中央预览切换对应人物。
3. 右侧人物信息卡显示 Lv1 基础属性、成长和技能说明。
4. `selection_confirmed=true`。
5. 无尽塔防门由封石变成蓝色可交互门。

允许点击台座或靠近按 `E`。未选择时可以查看图鉴，但不能进入闯关模式。

人物选择只决定下一局。战斗开始后 HUD 人物头像只读，不再可点击。

### 12.3 家园移动

- 未选择人物时不显示摇杆，所有设施可直接点击。
- 选择后中央人物可用现有移动控制器在家园短距离移动。
- 家园禁用攻击、跳跃、技能、武器切换，只显示移动和交互。
- 设施既支持走近 `E`，也支持鼠标/触屏直接点击。

### 12.4 家园 HUD

顶部：

- 左：游戏名与家园标记。
- 中：所选人物名称；未选显示“选择出战人物”。
- 右：最高波次、设置、全屏。

底部：

- 未选择：提示“点击骑士或刺客台座”。
- 已选择：提示“前往北侧传送门选择闯关”。

## 13. 闯关选择

新增 `scripts/mode_catalog.gd`：

```gdscript
const MODES := {
	&"endless_td": {
		"title": "无尽塔防",
		"description": "准备、建造并与炮台一起守住核心",
		"scene": "res://main.tscn",
		"enabled": true,
		"icon": "res://assets/generated/ui/modes/endless-td.png",
	},
}
```

模式选择层当前只展示一张可用卡：“无尽塔防”。右侧可以保留一个无点击行为的“更多模式开发中”封石门，但不要创建虚假的模式 ID。

点击“开始新局”前再次显示：

- 人物。
- 模式。
- 初始生命/攻击/防御/护甲。
- “等级与天赋本局重置”的说明。

## 14. 宠物入口

宠物仅做关闭状态：

- 显示宠物窝/蛋/脚印视觉。
- 点击或靠近提示“宠物系统暂未开放”。
- 不生成宠物节点。
- 不跟随人物。
- 不参与战斗和存档结算。
- `meta.json` 可以预留 `pets` 空结构，但不得实现抽取、解锁或数值。

## 15. 武器图鉴

图鉴数据必须直接读取 `WeaponCatalog`，不要再复制一张伤害表。

### 15.1 发现条件

以下任一事件发生即发现武器：

- 新局初始装备。
- 拾取到地面武器。
- 武器因超时进入仓库。
- 从仓库装备。
- 装入全息垫。

仅在开发者模式循环武器不计入发现。

### 15.2 图鉴展示

已发现：

- 图标、名称、类型。
- 基础伤害、弹丸数、冷却、范围。
- 近战/远程、基础/Boss 掉落标签。
- 发现次数可不显示。

未发现：

- 黑色剪影。
- 名称“？？？”。
- 数值隐藏。

筛选：全部、近战、远程、已发现。显示 `已发现 n / 总数`。

## 16. 敌人图鉴

新增 `scripts/enemy_catalog.gd`，只保存图鉴名、描述、图标路径、XP 和类型标签；波次 HP/速度公式仍以 `main.gd` 为准，避免顺手搬走数值。

图鉴 ID：

- `scout`
- `runner`
- `brute`
- `mage`
- `elite_brute`
- `boss`

发现条件：敌人第一次实际生成时发现，不要求击杀。

记录字段：

- `seen`。
- `kills`，跨局累计。
- `leaks`，抵达核心次数。
- `first_seen_wave`。
- `highest_seen_wave`。

图鉴展示当前代码公式在所选参考波次的数值。默认参考波次 1，可用 `- / +` 查看 1–10；不要把某一波计算结果写死在图鉴数据里。

## 17. Meta 存档

新增 `scripts/meta_save.gd`，路径 `user://meta.json`，烟测路径 `user://meta_smoke.json`。

建议结构：

```json
{
  "version": 1,
  "last_selected_hero": "ember_hero",
  "heroes": {
    "ember_hero": {
      "unlocked": true,
      "runs": 4,
      "highest_run_level": 9,
      "highest_wave": 10,
      "total_kills": 231
    },
    "assassin": {
      "unlocked": true,
      "runs": 1,
      "highest_run_level": 5,
      "highest_wave": 6,
      "total_kills": 72
    }
  },
  "modes": {
    "endless_td": {"unlocked": true, "highest_wave": 10}
  },
  "codex": {
    "weapons": {"sword": {"discovered": true}},
    "enemies": {
      "scout": {
        "seen": true,
        "kills": 20,
        "leaks": 2,
        "first_seen_wave": 1,
        "highest_seen_wave": 10
      }
    }
  },
  "pets": {"unlocked": [], "equipped": ""},
  "records": {
    "highest_wave": 10,
    "best_kills": 80,
    "best_survive_time": 620.0
  }
}
```

### 17.1 Meta 写入时机

- 清波：把本波新发现图鉴和累计击杀刷入 Meta。
- 失败结算：写人物记录、模式记录、最终图鉴。
- 返回家园前：确保 flush 完成。

不要每生成一只敌人就写磁盘。内存设置 dirty，检查点统一原子写入。

### 17.2 旧记录迁移

首次没有 `meta.json` 时：

1. 读取 `records.json`。
2. 把 `highest_wave`、`kill_count`、`survive_time` 写到 `meta.records`。
3. 保留原文件，不删除。
4. 原子写出 `meta.json`。

损坏 Meta 返回默认结构，不得影响 `run.json`。

## 18. Run 存档 v2

在现有 payload 上增加：

```json
{
  "version": 2,
  "mode_id": "endless_td",
  "run_seed": 123456,
  "hero": {
    "hero_id": "assassin",
    "health": 121,
    "armor": 2,
    "progression": {
      "level": 4,
      "xp": 24,
      "pending_choices": 0,
      "talent_counts": {
        "force_training": 1,
        "shadow_duration": 1,
        "tempered_body": 1
      },
      "talent_rng_state": 987654,
      "legacy_bonus_health": 0,
      "legacy_dash_cooldown_level": 0,
      "legacy_bonus_armor": 0
    },
    "weapon_slots": ["sword", "pistol"],
    "weapon_slot": 0,
    "weapon_forge": {"pistol": 2},
    "skill_rank": 1
  }
}
```

不要保存派生后的 `attack_power`、`defense`、`max_health`、`armor_capacity`。加载时由人物定义、等级、天赋和 legacy bonus 重新计算，防止改平衡后旧存档残留错误数字。

保存当前 `health` 和 `armor`，加载后 clamp 到重算出的上限。

### 18.1 v1 → v2 迁移

合法 v1 run：

- `mode_id = endless_td`。
- `hero_id = hero.hero_kind`，非法则骑士。
- `level = 1`、`xp = 0`、`pending_choices = 0`。
- `talent_counts = {}`。
- 保留武器、锻造、技能、塔、金币、波次、核心和商店。
- 把旧导师成长转换到 legacy bonus。
- 迁移成功后只在下一次清波检查点写 v2；不要加载当帧改写。

未知人物、天赋、模式：整条非法项忽略；关键字段非法则丢弃 run 并回家园显示“断点已损坏”。

## 19. 深模块与接口

### 19.1 `CharacterProgression`

这是人物成长的核心深模块。调用者不需要知道 XP 曲线、跨级、天赋过滤、派生属性顺序。

接口：

```gdscript
signal level_changed(level: int)
signal choices_ready(choices: Array[Dictionary], pending_count: int)
signal stats_changed(stats: HeroStats)

func start(hero_id: StringName, run_seed: int, restored: Dictionary = {}) -> Error
func award_kill(variant: StringName, rank: StringName) -> LevelGainResult
func choose_talent(talent_id: StringName) -> TalentChoiceResult
func apply_wave_clear() -> ProgressionEffect
func current_stats() -> HeroStats
func snapshot() -> Dictionary
```

依赖均为进程内纯数据：`HeroDefinitionCatalog`、`TalentCatalog`、`EnemyCatalog`。测试直接穿过该接口，不需要 fake adapter。

### 19.2 `MetaSave`

接口：

```gdscript
func load_profile(path: String = META_PATH) -> Dictionary
func apply_run_result(profile: Dictionary, result: Dictionary) -> Dictionary
func record_discovery(profile: Dictionary, event: Dictionary) -> Dictionary
func write_profile(profile: Dictionary, path: String = META_PATH) -> Error
```

文件系统是本地可替代依赖。烟测使用 `meta_smoke.json`，禁止写生产路径。

### 19.3 `HomeHub`

接口只发意图，不直接加载战场：

```gdscript
signal new_run_requested(hero_id: StringName, mode_id: StringName)
signal continue_requested

func configure(profile: Dictionary, resumable_run: Dictionary) -> void
```

`AppRoot` 是唯一场景切换调用者。

### 19.4 `HeroStats`

只读运行快照，字段至少包含：

```text
max_health
attack_power
defense
armor_capacity
move_speed
dash_cooldown_mult
dash_invuln_bonus
all_damage_mult
melee_damage_mult
ranged_cooldown_mult
clone_damage_mult
clone_duration_bonus
wave_heal_ratio
scrap_reward_mult
```

不要让 HUD 自己重算公式。HUD 只展示快照。

## 20. 文件变更地图

### 新增

| 文件 | 职责 | 建议上限 |
|---|---|---:|
| `scenes/app_root.tscn` | 应用根 | 小场景 |
| `scenes/home/home_hub.tscn` | 家园 | 场景 |
| `scenes/ui/talent_choice_overlay.tscn` | 三选一 | 场景 |
| `scripts/app_root.gd` | 场景状态机 | 250 行 |
| `scripts/home_hub.gd` | 家园交互 | 400 行 |
| `scripts/character_progression.gd` | 等级/天赋/派生属性 | 400 行 |
| `scripts/hero_stats.gd` | 只读属性快照 | 180 行 |
| `scripts/hero_definition_catalog.gd` | 两人物定义 | 220 行 |
| `scripts/talent_catalog.gd` | 天赋数据 | 320 行 |
| `scripts/enemy_catalog.gd` | 图鉴/XP 数据 | 220 行 |
| `scripts/mode_catalog.gd` | 模式数据 | 120 行 |
| `scripts/meta_save.gd` | Meta 校验/迁移/原子写 | 350 行 |
| `scripts/pause_coordinator.gd` | 多原因暂停 | 120 行 |
| `scripts/talent_choice_overlay.gd` | 天赋卡交互 | 300 行 |
| `scripts/codex_panel.gd` | 图鉴分页/筛选 | 400 行 |

### 修改

| 文件 | 修改内容 |
|---|---|
| `project.godot` | 主场景改 `app_root.tscn` |
| `scripts/main.gd` | 接收 launch config、接成长模块、结束发 signal；不要顺手拆文件 |
| `scripts/hero.gd` | 改为从 `HeroStats` 取移动/生命/防御/护甲；禁止生产中切人 |
| `scripts/enemy.gd` | `rank`、XP 查询、图鉴事件 |
| `scripts/hud.gd` | 等级/XP 条、只读人物头像；移除生产切人按钮 |
| `scripts/shop.gd` | 新局不再生成旧 vitality 槽 |
| `scripts/run_save.gd` | v2 校验与 v1 迁移 |
| `tests/smoke_test.gd` | 只保留跨系统主流程，细项拆到新测试 |
| `AGENTS.md` / `CLAUDE.md` | 同步入口与新规则，保持逐字一致 |

所有新公开方法都写 `##` GDScript 文档注释。错误路径返回 `Error` 或明确结果对象，文件打开失败不能静默假装成功。

## 21. 信号与数据流

```text
Enemy.defeated(enemy, reward)
  → Main 增加金币/击杀
  → MetaTracker.record_enemy_kill
  → CharacterProgression.award_kill(variant, rank)
      → level_changed
      → stats_changed
      → choices_ready
          → PauseCoordinator.acquire("talent")
          → TalentChoiceOverlay.show_choices
          → choose_talent
          → 下一组或 release("talent")

Wave clear
  → CharacterProgression.apply_wave_clear（治疗）
  → Shop.refresh
  → RunSave.write v2
  → MetaSave.flush discoveries

Run end
  → Main emit run_finished(result)
  → AppRoot
      → MetaSave.apply_run_result
      → MetaSave.write
      → RunSave.delete_run
      → show_home
```

## 22. 边缘情况

1. **最后一只怪触发升级**：先完成天赋选择，再允许清波保存。
2. **英雄倒地时升级**：基础成长和天赋生效，但不复活；UI 选择后继续倒地计时。
3. **核心同时归零和升级**：失败优先，不弹天赋层；未选择的等级不写 Meta。
4. **多级连升**：逐次三选一，基础成长一次不漏。
5. **候选不足三张**：按分类补池；仍不足属于数据错误，打印明确错误并用所有未满通用天赋补齐。
6. **天赋弹窗时用户按暂停**：用户暂停 reason 可记录，但不能关闭天赋；选完后仍保持用户暂停。
7. **断点有 pending choice**：正常检查点不允许 pending > 0；若迁移数据出现，加载后先显示选择，再进入 PREP。
8. **图鉴未知 ID**：忽略并保留其他合法条目。
9. **未选人物点击传送门**：不打开模式层，只提示。
10. **断点继续**：人物由 run 决定，家园台座选择不覆盖。
11. **家园宠物点击**：只提示，不创建空数组以外的玩法状态。
12. **战斗中开发者 H 切英雄**：只在开发者模式允许，用于素材检查；必须重建成长模块并标记该局不计入 Meta，避免污染正常记录。

## 23. 实施阶段

### 阶段 A：纯数据成长模块

新增人物、敌人、天赋目录和 `CharacterProgression`。

验收：

- 固定击杀序列能得到精确等级和 XP。
- 骑士/刺客 Lv1–10 表完全匹配本文。
- 天赋候选不重复、不出满层、不出错误人物专属。
- 同 seed、同选择历史得到同候选。

此阶段不要改主场景。

### 阶段 B：接入战场

- `main.gd` 创建 progression。
- 击杀发 XP。
- `hero.gd` 使用派生属性。
- HUD 加等级/XP。
- 护甲/防御统一入口。

验收：

- 塔击杀和英雄击杀都加相同 XP。
- 漏怪不加 XP。
- 升级 HP/护甲的当前值增量正确。
- 骑士和刺客相同武器的伤害因攻击强度不同。

### 阶段 C：天赋 UI

- 增加 PauseCoordinator。
- 三选一弹层。
- 接所有天赋效果。
- 处理多级、倒地、清波边缘。

验收：

- 战斗完全暂停。
- 只能选一张。
- 选择后效果立即反映 HUD 和伤害。
- 连续两级显示两轮而不是覆盖。

### 阶段 D：应用入口和家园

- 创建 AppRoot/HomeHub。
- 修改 `project.godot`。
- 人物台座选择。
- 模式选择与断点继续。
- 战斗 HUD 人物切换改只读。

验收：

- 首次进入不能直接开局。
- 骑士/刺客选择分别创建正确定义。
- 继续断点不允许换人。
- 失败能回家园而非重载战场。

### 阶段 E：图鉴与 Meta

- MetaSave。
- 武器/敌人图鉴。
- 记录板。
- v1 records/run 迁移。

验收：

- 发现/击杀跨局保留。
- 新武器未发现时是剪影。
- Meta 损坏不毁 run，run 损坏不毁 Meta。
- 所有烟测只写 `_smoke.json`。

### 阶段 F：视觉与发布回归

- 家园、人物选择、模式门、图鉴、天赋层逐帧验收。
- Web 导出。
- 手机触控检查。

不得在前五阶段功能未稳定时发布生产站。

## 24. 测试文件建议

新增独立测试，避免继续把全部内容堆进 2000+ 行 smoke：

```text
tests/character_progression_test.gd
tests/talent_choice_test.gd
tests/meta_save_test.gd
tests/run_v2_migration_test.gd
tests/home_hub_smoke_test.gd
tests/codex_test.gd
```

必须断言：

### 等级

- 39 XP 不升级，40 XP 升 Lv2。
- 一次 +200 XP 正确跨多级并产生对应待选次数。
- Lv10 不继续升级。
- 塔击杀与英雄击杀经验一致。

### 属性

- 两人物每级表。
- 最大生命增长只补差值。
- 护甲容量增长补差值。
- 防御不会把未被护甲吸收的正伤害降到 0。
- 所有伤害源经过同一入口。

### 天赋

- 三类各一张。
- 不重复、不越层、不串人物。
- 同 seed 确定。
- 暂停 reason 不互相覆盖。
- 最后一只怪升级必须选完才清波。

### 家园

- 未选择人物开始按钮禁用。
- 选择人物后只开放 `endless_td`。
- 宠物入口不可用。
- 新局 config 包含人物/模式/seed。
- 战斗 HUD 无生产人物切换按钮。

### 存档

- `meta_smoke.json`、`run_smoke.json`、`records_smoke.json` 完整清理。
- 测试禁止读写生产路径。
- v1 run 迁移后保留塔、武器、金币、波次。
- 派生属性不写盘，加载重算。

## 25. 视觉验收清单

必须截取 1280×720 玩家视角：

1. 家园首次进入，未选人物。
2. 骑士选中与人物属性卡。
3. 刺客选中与人物属性卡。
4. 无尽塔防模式选择层。
5. 宠物入口锁定提示。
6. 武器图鉴：已发现 + 未发现同屏。
7. 敌人图鉴和波次参考切换。
8. 战斗 HUD Lv/XP。
9. 天赋三选一。
10. 多级连续选择。

每一帧都要检查：

- 家园是否与现有地牢砖、金边墙属于同一游戏。
- 是否存在默认 Godot 控件感、纯色调试层、文字溢出。
- 手机安全区是否遮挡卡片和确认按钮。
- 人物台座、传送门、图鉴设施是否一眼能看出用途。
- 未选择人物时是否明确不能开局。

## 26. 完成定义

只有同时满足下列条件才算完成：

- 应用启动进入家园。
- 新游戏必须先选骑士或刺客。
- 当前只有无尽塔防模式可进入。
- 每个击杀按敌人类型获得 XP。
- Lv1–10 自动成长正确。
- 每级三选一天赋，暂停和恢复正确。
- 骑士/刺客基础属性、技能和运行状态独立。
- 战斗中不能正常切人物。
- 宠物显示但不可用。
- 武器/敌人图鉴跨局保存。
- 旧记录和旧 run 有明确迁移。
- 所有新增烟测通过，且不碰生产存档。
- 家园和天赋层完成视觉验收。
- Web nothreads 导出仍能加载。

## 27. 交接给实现 AI 的硬约束

1. 先读 `AGENTS.md`、本文和现有 `main.gd` / `hero.gd` / `run_save.gd`。
2. 先完成阶段 A 的纯模块和测试，再接主场景。
3. 不要直接把 XP、天赋候选和图鉴字典继续塞进 `main.gd`。
4. 不要创建 Autoload 来拆 `main.gd`；AppRoot 是场景根，不是全局单例。
5. 不要改变敌人 HP、波次数量、塔数值来“顺便平衡”等级系统；先按本文数值跑出实测。
6. 不要新增人物、武器、敌人或模式 ID。
7. 不要实现宠物玩法。
8. 每一阶段结束都跑针对性测试和完整 smoke。
9. 改 HUD/家园/天赋层必须实际截图，不可只看断言。
10. 不要 commit/push，除非用户明确要求。

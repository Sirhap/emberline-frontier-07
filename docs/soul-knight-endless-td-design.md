# 余烬防线 · 元气骑士式无尽塔防技术设计

日期：2026-08-18  
引擎：Godot 4.7 + 现有「余烬防线：前线」  
品类：俯视动作射击 × 无尽塔防 × 轻肉鸽  
一局：不限时，越打越密；玩家死或核心被拆 = 结束  
对标手感：元气骑士的走位、闪避、枪械后坐、近战挥砍；塔防的路线、阻挡、集火  
死亡：本局塔、武器、祝福清空；只留 Meta 解锁和最高波记录

不另开引擎，复用 `hero` / `tower` / `enemy` / `projectile` 和帧调工具。

## 1. 一句话玩法

你在固定地图上同时做两件事：像元气骑士一样亲手冲进怪群输出，同时摆塔锁路。怪走预设路线打核心；你和塔一起清。波次无限，强度按曲线涨，中途用本局货币刷新武器和塔。

**不是**：纯挂机 TD、不是地牢房间探索、不是 Hades 选门。地图一张（后期可多图），变化来自波次、掉落和构筑，不来自换房间。

## 2. 目标与非目标

**要做成的**

- 主角手感接近元气骑士：八向走、短无敌闪避、远程有弹道/后坐、近战有挥砍窗和打击停顿。
- 塔是「锁路工具」不是主 C。没有主角，后期清不动；没有塔，核心会被漏。
- 无尽：没有最终 Boss 关，只有里程碑波（10 / 25 / 50）给精英和选构筑。
- 同一 `run_seed` 下，波次组成、精英种类、商店货架一致。

**v1 不做**

- 联机、地牢换房、开放建造任意地形、物理碎裂、运行时热挂脚本。
- 塔不自动进化成第二主角（不给塔闪避和操作）。
- 不把「余烬行者」那套房间图状态机搬过来。

## 3. 和现有工程的关系

当前仓库已有：`hero.gd`、`tower.gd`、`enemy.gd`、`projectile.gd`、`hud.gd`、`main.gd`、对象池雏形、`xsxb_frame_tuner`。

**留下**：Motor、Hit/Hurt、子弹池、帧攻击窗、塔的索敌与射击。

**抽出去**：把 `main.gd` 里「生成一波 → 打完」的过程式逻辑，拆成 Autoload + 遭遇导演，避免再往 main 里堆波次 if。

```
res://
  actors/     hero, enemy 场景
  towers/     塔场景 + TowerData
  combat/     Hitbox, Hurtbox, DamagePacket, WeaponData
  waves/      WaveTable, Director, Path
  run/        RunSession, Loadout, Shop
  meta/       Unlock, Save
  content/    .tres
  ui/         HUD, 建造栏, 三选一, 结算
```

## 4. 运行时分层

| 层 | 对象 | 职责 | 写盘 |
|---|---|---|---|
| Meta | `MetaSystem` | 角色/塔/武器解锁、最高波、货币 | 能 |
| Run | `RunSession` | seed、波数、金币、背包、已建塔 | 仅在「波间隙」 |
| Field | `FieldDirector`（场景） | 刷怪、路径、核心血量、胜负判定 | 不能 |
| Combat | 组件 | 伤害、闪避、弹幕 | 不能 |
| Content | `.tres` | 武器、塔、敌人、波次模板 | 只读 |

`RunSession` 只发这些信号：`wave_started(n)`、`wave_cleared(n)`、`core_hurt`、`hero_down`、`run_ended(wave)`、`shop_opened`。HUD 和音效只订信号。

## 5. 一局状态机

```
Hub → PickHero → GenerateRun
  → BuildPhase（倒计时 15–25s，可提前开战）
  → WaveCombat
  → WaveClear → Reward / Shop
  → BuildPhase → …
  → Defeat（英雄死且无复活 / 核心 HP=0）→ MetaAward → Hub
```

检查点只在 `WaveClear` 写 `user://run.json`。战斗中途不存。崩溃回到上一波清完后的建造阶段。

## 6. 地图与路径

一张「前线巷战」图即可跑通 v1。

```
PathGraph
  lanes: Array[PackedVector2Array]   # 2~3 条进路
  core: Node2D
  build_slots: Array[BuildSlot]      # 预置坑位，不自由铺地
  hero_nav: NavigationRegion2D       # 主角可走区域，可越线路抄近路
```

约束：

- 怪只走 lane，不追玩家（除非该敌人带 `chase_hero` 标签）。
- 主角可以上路线挡刀、风筝、去侧路捡箱子。
- 塔只能建在 `BuildSlot`。槽位分 `front / mid / back`，贵塔限制 back，便宜挡路塔可 front。
- 核心有独立 Hurtbox，只吃「抵达」伤害，不吃流弹（避免自己炸家）。

v1 不做可破坏地形。挡路只靠「阻挡型塔」和主角站位。

## 7. 主角：元气骑士手感

`Hero` = `CharacterBody2D` + 组件，不继承一棵深类。

```
Hero
  Motor          速度、加速度、击退、闪避位移
  Health
  Hurtbox
  WeaponHost     当前武器 + 副手（近战或盾）
  Dash           8~10 帧无敌，冷却与能量
  Skill          角色技能，独立冷却
  AnimDriver     枪/近战两套动画库
```

**操作（键鼠 + 手柄同一套 InputMap）**

| 动作 | 行为 |
|---|---|
| 左摇杆 / WASD | 八向走 |
| 右摇杆 / 鼠标 | 瞄准，与移动解耦 |
| 轻攻击 | 当前武器主火力 |
| 重攻击 / 右键 | 近战清弹或盾反（角色定） |
| 闪避 | 短位移 + 无敌，可取消射击后摇 |
| 技能 | 角色主动技 |
| 1–4 / 肩键 | 切武器（本局最多 2 把） |

**武器是数据，不是子类爆炸。**

```
WeaponData
  id, slot: gun | melee
  cadence, mag, reload, spread, recoil
  projectile: ProjectileData | melee_arc: HitboxTimeline
  ammo_cost
  tags: bullet, energy, fire, shotgun, pierce
```

结算用统一 `DamagePacket`（基础 → 加 → 乘 → 暴击 → 抗性 → 护盾 → 至少 1）。

攻击窗继续走动画 method track（`hitbox_on/off`），和现有帧调器对齐。枪械用「后坐冲量 + 准星扩散」，不要做成无后坐激光扫射。

角色 v1 两个就够：

- **刃行者**：移速高，近战重击可弹开小子弹，技能短冲刺斩。
- **火线**：弹匣大，技能手雷，走位慢。

技能改的是 `RunStats` 和生成物，不动态挂脚本。

## 8. 塔

塔是「自动队友」，AI 极简：槽位静止、按索敌规则开火。

```
TowerData
  id, cost, slot_class
  range, cadence, damage
  targeting: first | close | strong | flying
  projectile / beam / aura
  block_count: int          # 0=不挡路；>0 能拦 N 个怪
```

v1 五座：机枪、炮、冰霜、路障、电塔。升级 `T1 → T2 → T3`，卖掉返还 60%。

**仇恨**：塔不打主角；主角子弹默认不伤塔。友伤关闭。

建造：BuildPhase 点槽位出轮盘。WaveCombat 中只能修/卖，不能新造。

## 9. 无尽波次

用「模板 + 曲线」，不要手写 999 波表。

```
WaveDirector.compose(n, seed):
  budget = base * pow(1.07, n) * elite_mod(n)
  packs = pick_packs(budget, tags_unlocked_by(n))
  if n % 10 == 0: append_elite_or_miniboss(n)
  if n % 25 == 0: append_mutator(n)
```

清波条件：本波配额打完 **且** 场上无活怪。漏网扣的是核心，不阻止清波。

难度三段：1–15 教学；16–40 双路+飞行+精英；41+ 突变叠层，单怪血量软帽。

## 10. 本局成长（轻肉鸽）

每清一波：金币 + 经验。每 5 波一次「三选一」，每 10 波一次「武器箱或塔图纸」。

祝福是 `BoonData`：改 `RunStats` 或挂 `Spawner`。事件源用塔防的：`hero_hit` / `hero_kill` / `tower_kill` / `dashed` / `core_leaked` / `wave_cleared`。

商店在波间隙。武器持有上限 2。

## 11. Meta

留下：角色/塔/武器图鉴、余烬、最高波。  
清空：本局塔、武器、Boon、血量。  
Meta 只开门，强度靠本局。存档：`meta.json` + 波间隙 `run.json`。

## 12. 战斗手感细则

- 闪避成功（0.15s 内子弹擦过 Hurtbox）发 `dodged`。
- **近战命中停顿 30ms，只对玩家攻击，不对玩家挨打。**
- 枪械换弹可被闪避取消，不可被普攻取消。
- 精英出场有 0.4s 警告圈。
- 核心受击时镜头微震，HUD 闪红，不要压暗全屏。

## 13. 性能

同屏敌人 ≤ 40，子弹 ≤ 120 全池化，塔 ≤ 12 槽。怪走固定点列。塔索敌每 0.15s 一次。

## 14. 测试

- `WaveDirector.compose` 对固定 seed 做 hash。
- 伤害公式纯函数测试。
- 烟测：第 1、10、25 波；漏怪扣核心；短刃取消窗、闪避无敌帧、霰弹扩散。

## 15. 里程碑

**M0 竖切**：一张图、一条路、机枪塔 ×3 槽、一把手枪、闪避、无尽波（一种小兵 + 曲线）、核心血量、死亡结算。没有祝福。确认「人在打、塔在锁、波在涨」。

**M1**：两把武器、近战清弹、五座塔、双路、10 波精英、三选一、商店、检查点。

**M2**：第二角色、飞行怪、突变、每日种子、第二张图。

**M3**：手柄、建造轮盘、伤害数字开关、20 分钟 40 波不掉帧。

## 取舍

房间图、进门选路整段丢掉。留下：`DamagePacket`、Boon/`RunStats`、对象池、帧 Hitbox、Meta 存档格式。`EncounterDirector` 换成 `WaveDirector`；`RoomNode` 换成 `PathGraph + BuildSlot`。

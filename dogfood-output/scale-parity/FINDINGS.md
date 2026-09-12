# Scale parity FINDINGS（基线｜只验不改）

- tip：`main@83f5ef3`（本地 Godot 截帧 + 代码/资源测量）
- 目录：`dogfood-output/scale-parity/`
- 依据：`MEASUREMENTS.md`、`CODE_BASELINE.md`、截图 `SP-*-{idle,attack,jump,skill}*.webp`

## 结论：**不通过（基线成立，可开改）**

同角色内，攻击/跳跃的 `VisualOwner.scale` 与待机一致；跨角色、技能帧不透明包围盒、选角肖像存在明显比例差。

## 缺陷清单

### P1-1 骑士 vs 刺客 基础缩放常量不一致
- 现象：局内 `owner_scale` 骑士恒 `0.34`，刺客恒 `0.38`（idle/attack/jump/skill 同）。
- 复现：出战两角色 → 读 `combat_visual_scale` / `VisualOwner.scale`；见 `MEASUREMENTS.md`。
- 证据：`SP-knight-idle.webp` vs `SP-assassin-idle.webp`；`scripts/hero.gd` `KNIGHT_VISUAL_SIZE`/`ASSASSIN_VISUAL_SCALE`；tuning `character.visual_size`。
- 说明：不透明身高×缩放后 idle 约 81px 接近，但常量双轨 + 画布/脚底锚点不同，动作帧会放大视觉差。

### P1-2 技能/皮肤技能帧「人突然变大」（资源包围盒）
- 现象：同 `visual_scale` 下，不透明高度相对 idle：刺客 `skill_cast` ~+31%（280/213），刺客攻击峰值 ~+23%；霜晶 `skill_cast` ~+34%，`skill_bubble` ~+26%；骑士 jump opaque 峰值 ~+11%。
- 复现：同机位播对应 clip；对照 `CODE_BASELINE.md` §2.2 与 `SP-*-skill*.webp` / `SP-*-attack.webp` / `SP-*-jump.webp`。
- 根因：帧图内容变高，不是 group `visual_size`（刺客 groups 均为 1.0）。

### P1-3 骑士技能「涨体」代码意图 vs 默认皮肤实测脱节
- 现象：`apply_skill_upgrade` 后 `combat_visual_scale` 升到 `0.34×1.08^lv`（lv2=`0.3966`），但 `ember_hero` tuning 写死 `visual_size=0.34`，`_character_scale()` 忽略 fallback → **默认骑士 sprite 不涨**，武器/碰撞侧仍用放大值。
- 复现：骑士技能升到 2 → 对比 `MEASUREMENTS.md` `knight-skill-lv2-*`。
- 风险：霜皮 `frost_*` 无 tuning visual_size，变身后会吃到 `FROST_SKILL_SIZE` 涨体，与默认皮行为不一致。

### P2-1 选角刺客肖像 zoom=1.55
- 现象：选角卡刺客放大裁切，骑士 zoom=1.0。
- 证据：`SP-assassin-select.webp` / `character_select.gd` `portrait_zoom=1.55`。

## 目标比例口径（给编程落地）

1. **基准**：以骑士默认待机为准——`character.visual_size` / `combat_visual_scale` 统一为 **`0.34`**（刺客改同值，或改成「不透明身高×缩放 = 81±3px」等价实现，二选一写死一种）。
2. **动作不变大**：idle/attack/jump/skill/皮肤技能 的 **sprite 显示倍率** 不得随技能等级变化；`skill_size_mult` 只允许改范围/伤害，**禁止**再改 `VisualOwner`/`fallback_visual_scale`。
3. **帧资源**：skill_cast / skill_bubble / 攻击峰值帧相对 idle 不透明高度 **≤ +8%**；超出则改图或加 per-clip `visual_size` 补偿压回基准。
4. **选角**：各角色 `portrait_zoom` 同值（建议全 1.0，或按不透明高度归一）。
5. **验收阈值**：同机位同分辨率，骑士/刺客/霜晶 各拍 idle|attack|jump|skill；`owner_scale` 全等；目视身高相对地砖差 ≤ 半格。

## 非本次改点
- down 帧 `frame_visual_overrides` 极端倍率（骑士 down 可达 ~2.6）仅记风险，不进本单必改。

# Scale parity 二次验收 RESULT

- PR: #12 tip `108241a`
- 基线对照: FINDINGS @ `dogfood-output/scale-parity/`
- 自动化: `tests/scale_parity_test.gd` → **SCALE PARITY PASS**
- 截帧: 本目录 `SP-*-{idle,attack,jump,skill}*.webp`

## 结论：**通过**

| 口径 | 结果 |
|---|---|
| 统一 combat/visual_size = 0.34 | 骑士/刺客/霜晶 idle·skill_lv2 均 `combat_scale=0.34`；刺客不再 0.38 |
| 技能不改 sprite 倍率 | skill_mult 仍可 >1（范围/伤害），但 `combat_visual_scale` 恒 0.34；owner 不再被技能涨体 |
| 峰值帧 ≤ idle+8% | 刺客 attack/skill_cast、霜晶 skill_cast/bubble 经 group 补偿后比值 ≤1.08（单测断言） |
| 选角 portrait_zoom | 统一 1.0 |

## 测量摘录（局内 owner_scale）

- knight idle/attack/jump/skill_lv2: `(0.34,0.34)`
- assassin idle/jump: `(0.34,0.34)`；attack `(0.3125)` / skill `(0.2938)` = 峰值补偿（压回 ≤+8%）
- frost skill 帧 `(0.2754)` = skill_cast_side 补偿

## 残差（不挡过）

- 补偿靠缩小整帧，技能瞬间人物会略小于待机；若老板要「视觉完全同高」需改图而非继续压 group。本单按 FINDINGS「改图或补偿」已满足数值口径。

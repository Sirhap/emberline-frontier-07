# 实现计划：无尽塔防

按 `docs/superpowers/specs/2026-08-17-endless-soul-knight-td-design.md` 落地。

1. 新模块：`weapon_catalog.gd`、`hero_projectile.gd`、`pickup.gd`、`wave_director.gd`、`shop.gd`
2. 扩展：`enemy.gd`（减速/接触/Boss）、`tower.gd`（三种）、`projectile.gd`（溅射/减速）、`hero.gd`（血/冲刺/远程）
3. 编排：`main.gd`、`hud.gd`
4. 生成 `assets/generated/` 缺图
5. 更新 `tests/smoke_test.gd` 与 README

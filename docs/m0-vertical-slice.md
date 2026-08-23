# M0 竖切：要改的清单

目标：一张图、锁路塔、一把手枪、闪避、无尽小兵曲线、核心、结算。不拆完整 Autoload，先在现有脚本上对齐手感。

## 现有可复用

- `scripts/hero.gd`：走、跳、近战窗、冲刺、血量
- `scripts/tower.gd` / `enemy.gd` / `projectile.gd`：索敌、路线、子弹
- `scripts/wave_director.gd` / `shop.gd`：波次与间隙
- `xsxb_frame_tuner`：帧攻击窗

## M0 必改

| 文件 | 改什么 |
|---|---|
| `scripts/hero.gd` | 近战命中 30ms 停顿；瞄准与移动解耦（鼠标）；闪避可取消后摇 |
| `scripts/main.gd` | 只在英雄近战命中时触发停顿；核心不受流弹；战斗中禁新造塔 |
| `scripts/weapon_catalog.gd` | 手枪后坐 / 扩散，不要激光手感 |
| `scripts/hud.gd` | 建造只在准备阶段；结算最高波 |
| 新 `scripts/hit_stop.gd` | 忽略 time_scale 的 30ms 停顿，可叠一次 |

## M0 先不动

- 新 Autoload 拆分、`RunSession` 存档、三选一 Boon、五座塔、第二角色
- 把 `main.gd` 整文件搬到 `actors/` `waves/`（M1 再拆）

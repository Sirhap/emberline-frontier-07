# 游戏机制审计｜基线 main@2cf039c

## 结论
**通过（附 P2 债）**。八项主契约有代码对照 + 无头全绿 + 开窗探针证据；未见 P0/P1 机制断裂。

## 命令
```bash
git rev-parse --short HEAD   # 2cf039c
./tools/run_tests.sh         # ALL TESTS PASS
# 探针（本机）：godot --path . --resolution 1280x720 --script /tmp/mech_aggro2.gd 等
```

## 逐项
1. 波次：`prep_duration=50`；清波 `scrap+=50` + 家门奖励；烟测/回归覆盖 → OK  
2. 胜负：复活库存 4、第五次倒地结束、核心归零爆炸结束并 `delete_run` → OK（smoke）  
3. 建造/商店：`PLAYER_STOCK` 无 burst；`TOWER_CAP=16`；脉冲出售实机 +48（`02-after-sell-pulse.png`）→ OK  
4. 成长：击杀 XP→三选一→属性；清波回血依赖 `field_medic`（设计文档，非无天赋保底）→ OK  
5. 倍速：仅刷怪间隔+清波防抖乘 `simulation_speed`；准备倒计时用墙钟 → OK（simulation_speed_test）  
6. 仇恨/漏怪：96/144/0.4s；倒地 `hero_seek_position=INF` → `_aggro=false`（`01-*.png` 探针 PASS）；漏怪 22px → OK  
7. 存档：合法 slots 继续恢复刺客已有视觉证据；非法空 slots → `load_run{}` + 隐藏「继续远征」（`03-*.png`）→ **拒收有效，表现偏弱**  
8. 家园链：刺客 `04/05/06`、骑士 `07/08` 开战与结束后回家园 → OK  

## P2 整改（不挡本轮「机制主路径」）
1. **非法/损坏 `run.json` 拒收无文案**：仅隐藏继续按钮，家园无提示「存档无效已忽略」。  
   - 整改：`configure` 发现磁盘有文件但 `load_run` 为空时，HUD/状态条给一句可读提示（或弹一次）。  
   - 复验：写入空 slots 坏档 → 进家园 → 无继续按钮 + 可见提示文案；删档后提示消失。

## 证据目录
`dogfood-output/mech-audit/`（01–08.png + 本报告）

# 视觉全面补验｜不通过
基线：`main@4f51b3b`  
证据目录：`dogfood-output/visual-accept-r3/`（01–16.png + crops/）  
开窗：Godot 4.7.2，1280×720，DISPLAY 实机截图（非仅无头）

## 结论
**不通过。** 无头测试此前已绿，不抵消本轮视觉 P0。

## P0（必须修，挡复验）
1. **家园 HUD 渗入战场**  
   - 现象：`AppRoot._launch_battle` 设 `_home.visible = false` 后，左下仍绘制「开始远征」；继续远征后战场同时残留「开始远征」+「继续远征」。  
   - 证据：`05`/`07`/`08`/`09`/`16` 及 `crops/*-bl.png`；运行日志 `home.visible=false` 但 `StartButton.is_visible_in_tree()=true`。  
   - 根因：`HomeHub`（Node2D）下 `CanvasLayer` HUD；父节点隐藏不断开 Control 的树可见性。  
   - 整改：开战时显式隐藏/禁用 HUD（`HUD.visible=false` 或 `process_mode`/`queue_free` 重建）；或把按钮挂到会随父可见性正确失效的层。禁止只靠 `_home.visible=false`。  
   - 复验：开战、战斗、倒地、继续远征进战四帧左下不得出现「开始/继续远征」；`is_visible_in_tree()` 对两按钮均为 false。

## P1
2. **倒地态视觉不一致**  
   - 现象：HUD「生命 0/120」「英雄倒地 / 剩余复活 4」，角色仍站立持武。  
   - 证据：`09-hero-downed.png`、`crops/09-hero-downed-mid.png`。  
   - 整改：倒地必须切 down 姿态/倒地动画（或明确倒地贴图），禁止 idle 站姿冒充倒地。  
   - 复验：截图对比点=头顶状态文案 + 角色姿态同时为倒地。

3. **商店价签被角色遮挡**  
   - 现象：`11-shop-hall` 角色压在「全息垫/霜灼塔」价签上，价格难读。  
   - 整改：价签提高 `z_index`/放到 UI 层，或角色靠近时价签避让。  
   - 复验：站在柜台前价签完整可读。

## P2（不挡本轮闭环，记债）
4. 选人 `01` 与 `02` 像素一致（档案已是刺客时再选刺客无差分）——验收脚本下次强制先选骑士再切刺客。  
5. 镜头/层级：放置区角色与全息垫描边偶发前后关系含糊（`08` mid），优先修 P0/P1。

## 已通过的路径（有图）
选人、家园、开战、放置、战斗、倍速 HUD、合法 `run.json` 下「继续远征」按钮出现、继续后刺客恢复（逻辑 OK，但 HUD 泄漏使画面仍不通过）。

## 给编程的自测/复验命令
```bash
git rev-parse --short HEAD   # 期望含修复提交
./tools/run_tests.sh
DISPLAY=:9 godot --path . --resolution 1280x720 --script tools/visual_accept_r3.gd
# 或至少：
DISPLAY=:9 godot --path . --resolution 1280x720 --script tools/visual_accept_r3_continue.gd
```
对比点：`05`/`16` 左下无家园按钮；`09` 倒地姿态；`11` 价签可读；`15` 双按钮（开始+继续）仅在家园。

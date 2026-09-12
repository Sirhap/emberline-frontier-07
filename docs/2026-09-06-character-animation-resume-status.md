# 人物动画修复续接记录（2026-09-06）

原 Grok 会话：`cb97a31c-18e5-44bd-87b6-2a5b936abfc7`。

**整体未完成；不可按旧会话的“二次验收全过”交付三向动画。** 本轮继续了代码修复、素材筛选和玩家视角验收；没有提交、发布或安装未通过验收的素材。

## 本轮已完成的代码

- `scripts/hero.gd`：远程开火保持 idle/run 身体循环，不开启近战动画计时器、不重置步态；枪口、弹道、后坐力散布和射击冷却保留。
- `scripts/hero.gd`：XSXB actor 加入场景、加载动画清单后再解析初始 idle。修复半成品三向配置在 `_ready` 前解析不存在 `idle_side`、未启动身体动画的问题。既有三向缺片回退代码保留。
- `tests/smoke_test.gd`：替换“刺客开枪必须播放近战 attack”的旧契约。
- `tests/ranged_body_test.gd`：覆盖两角色站立/移动射击、循环不重启、弹道信号、冷却、跳跃/技能阻挡、无延迟近战伤害、切回剑仍可攻击。
- `tests/hero_direction_test.gd`：默认只验已有侧视、初始纹理和缺片回退；完整模式严格报告缺失方向，不能用默认模式冒充三向完成。
- `tools/capture_direction_resume.gd`：真实 1280×720 家园/战场截帧，共 140 张；等角色切换淡入结束后抓图，只使用 smoke 存档路径。

## 素材审核与断点

独立验收 agent 审核了两套 canonical、6 组旧视频抽帧及后续小样。

| 旧素材 | 审核结果 |
| --- | --- |
| 骑士转身 | 正面 017–025、背面 036–048 可作朝向参考；靴底裁切、身材拉长和新增胸甲，不可直接接入 |
| 骑士正跑 | 偏右前方、反复转身、大量靴底裁切；没有合格完整正跑周期 |
| 骑士背跑 | 落脚阶段裁切、长围巾尾与身份参考不连续；不能只留腾空帧蒙混过关 |
| 刺客转身 | 正背朝向清楚，但靴底裁切；站姿仍需修复/重制 |
| 刺客正跑 | 有条件复用；原 8fps 抽帧不够，已从 24fps 原视频重新提取候选 |
| 刺客背跑 | 有条件修复；亮绿色护臂偏离 canonical，需纠正并复审 |

最新候选路径：`dogfood-output/visual-fix/qa-resume/assassin-proof-v3/`。384×384 RGBA，正/背各 16 张播放帧 + 1 张相同端点，24fps，循环播放排除第 17 张。固定整段缩放与原点，保留腾空/落脚；不是逐帧把身高强拉相同。底部透明留边 4px，未来接入须补偿 4px 绘制偏移（manifest 已记录）。GIF 使用厘秒量化，共 670ms；PNG/manifest 的精确播放时间为 16/24 秒。

端点像素比较、JSON 契约通过；连续性工具仍要求视觉复核。端点相同不代表步态、身份、比例或循环已经通过。**两个候选均未安装到生产动画清单。** 第一版逐帧脚贴底小样仍保留在 `assassin-proof/`，第二版 `assassin-proof-v2/` 背跑因改色误伤帽子和披风被独立验收打回，不能误用。v3 将改色限制在护臂空间窗口，保留两版失败证据。

原图目录 `incoming/`、旧 `locked/` 不因名字而获得通过状态。骑士/刺客生产清单仍缺：`idle_front`、`idle_back`、`run_front`、`run_back`、`jump_front`、`jump_back`，合计 12 槽。生产战斗锁侧视的既有策略不变。

## 重生成阻塞

旧会话指定的临时代理可以认证并列出 `grok-imagine-video-1.5`，但实际生成返回 HTTP 429：`upstream_quota_exhausted`，消息“上游账号额度等待恢复”。用户确认暂时没有其他有额度的图像/视频服务。已停止重复提交。

`dogfood-output/visual-fix/proofs-v2/` 已保存 canonical 留边参考、提示词和生成约束；当前没有成功创建的新视频 job。凭据没有写入脚本、提示词或本记录。

## 验证

以下均在本轮实际执行通过：

```sh
godot --headless --path . --script tests/smoke_test.gd
godot --headless --path . --script tests/ranged_body_test.gd
godot --headless --path . --script tests/hero_pack_runtime_test.gd
godot --headless --path . --script tests/hero_pack_spec_test.gd
godot --headless --path . --script tests/hero_direction_test.gd
```

完整方向验收执行失败（预期且未放宽）：

```sh
godot --headless --path . --script tests/hero_direction_test.gd -- --require-directions
```

报告 12 个缺失槽，60 条失败检查（重复检查了骑士切换回来后的行为）。

实景证据在 `dogfood-output/visual-fix/qa-resume/runtime/`，`capture-evidence.json` 记录实际 clip/frame/state；文件名 `before-incomplete-*` 提醒三向未完成。`godot --path . --script tools/capture_direction_resume.gd` 可重拍。GUI 工具成功不等于视觉验收通过。

独立验收已确认：远程 idle/run 身体修复 PASS；actor 初始化与侧面回退 PASS；重拍取证有效性 PASS（抽查，非逐张批准 140 图）。完整三向整体 FAIL；刺客候选不得计作交付。验收遵循动画技能的身份、边界和时间连续性要求，未将自动端点测试当作视觉通过。

v3 独立复审：帽子与中央/下部披风改色误伤已改善，背跑恢复为候选；4px 底部留白/偏移记录、16 帧 670ms GIF 通过。16→1 逐帧存在姿势突变风险，实际速度下无缝循环、生产接入、跨动作衔接仍未验证。正背跑均不作 PASS 或成品交付。

## 恢复后顺序

1. 有额度后先重制骑士和刺客正背面站姿；锁原始身体比例与完整脚底，独立验收后再生成依赖动作。
2. 修复/筛选刺客原视频，检查头部、护臂、持刀、跑步循环与侧视切换比例；不合格就重制。
3. 补家园正背面 idle/run/jump，素材先过关再注册生产动画清单。
4. 完整方向测试通过，再重拍家园方向切换、跳跃与战斗射击；由独立 agent 最终验收。原任务的全动作比例和剩余动画占位仍须逐项核验，不得从本轮代码测试推导“全部完成”。

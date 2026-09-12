# 人物动画任务：给下一位 AI 的完整交接

更新时间：2026-09-07 傍晚（北京时间）。本文件记录第三轮已装进生产的结果。

## 1. 用户要完成什么

项目：`/Volumes/other/IdeaProjects/sirhao/emberline-frontier-07`，macOS，Godot 4.7 Compatibility，1280×720。

用户要求修复人物动画视觉：缺少的图片/视频自行生成，修动作连贯性，尤其各动作之间人物大小和比例一致。允许多 agent 并行；要求独立验收 agent，不通过就返工，**素材先验收再接入项目**。用户后来明确同意直接生成图片关键帧，不必坚持视频路线。

当前优先完成的具体范围：骑士、刺客的家园正背面 idle/run/jump，共 12 个动画槽，随后完成运行时接入、跨动作/跨视角比例与连续性验收。此前已发现的其他视觉缺口须核验，不可用这 12 槽掩盖原任务的剩余问题。

**当前状态（2026-09-07 夜，12 槽独立验收续）：骑士/刺客正背 idle/run/jump 12 槽已在生产。本轮独立量测发现骑士正背跑脚悬空（gap 最高 31px）且背面身高 247–263（待机 239）；刺客背面跑第 3/8 帧矮 16px 且浮 23px。未重画：按待机身高 shared-scale、接触帧脚贴 `canvas-1`、腾空夹在 12/14px。安装后骑士跑 h≈225–242 gap 0–12；刺客跑 h≈204–220 / 209–219 gap 0–14。idle/jump 未改。远程开火与 actor 初始化未覆盖。未 git commit。**

## 2. 先遵守这些约束

- 先读仓库 `AGENTS.md`、`CLAUDE.md`；如修改项目规则，两份必须逐字一致。本交接没有修改它们。
- 保留现有 dirty worktree。大量修改来自用户/前一位 Grok，不能 reset、checkout 覆盖，也不能把全部 diff 当成本轮成果。
- 不要提交、push、发布、改生产服务配置，除非用户另行授权。
- 不读取/打印/编辑 `.env` 或密钥；旧聊天日志包含凭据，读取时必须过滤，不可贴进交接或代码。
- 最小改动，不重构 `main.gd`，不发明武器/玩法。
- 战场现有策略锁侧视；正背面供家园 HomeWalker 使用。家园不能攻击/放技能，但能跳跃。
- 保留 `JUMP_HEIGHT = 32`。素材脚锚与代码抬升分开，不能把跳高设 0 掩盖配准问题。
- 烟测只用 `run_smoke.json`、`records_smoke.json`、`meta_smoke.json`，避免污染真实存档。

## 3. 本轮已交付

| 角色 | 已接入生产的家园方向片 |
| --- | --- |
| 骑士 `ember_hero` | `idle_front/back` 6×8fps；`run_front/back` 8×16fps；`jump_front/back` 7×14fps |
| 刺客 `ember_assassin`（玩法 ID `assassin`） | `idle_front/back` 6×8fps；`run_front/back` 8×16fps（v3 原视频）；`jump_front/back` 9×10fps |

- [x] 12 槽已进 `idle|run|jump/{front,back}/`，manifest 已登记。侧视仍用根目录 bare `idle/run/jump`。
- [x] 跳跃只取 H3 最长腾空段，脚贴画布底；代码 `JUMP_HEIGHT = 32`；取证 apex `air_clearance == 32`。
- [x] 刺客正跑握刀改为下外，与待机一致（不再用 H3 胸前交叉）。
- [x] `--require-directions`、烟测、远程身体、`git diff --check` 通过；家园截图站位 `Vector2(380, 430)`，不压家具。
- [x] 刺客侧视/根 `run`：8 帧 16fps 真跑。接触帧脚 `y=383`、腾空帧脚约 `369–372`（约 12px 离地）。旧 walk 备份在 `dogfood-output/visual-fix/qa-resume/assassin-side-run-repair/backup-old-run/`。H3 侧跑成片有品红→青绿漂色和刀尖染色，未接入。
- [x] 正背待机真屈膝：GenerateImage 马步键帧 + 品红先抠再 despill，缩放到目标身高后脚贴 `canvas-1`。骑士 idle 宽 158（侧视 162），刺客 idle 宽 180（侧视 161，马步略宽）。6 帧呼吸沿用旧 idle 的脚锚微拉伸（239→243 / 213→217）。run/jump 正背未改。备份在 `facing-pass/backup/`。
- [x] 骑士 `attack_front/back` 8×16fps：举剑→横斩→收势，真朝向，不含徒手 idle 起收（避免剑瞬移）。`dash_front/back` 6×24fps：马步 idle + 朝镜头/背对镜头冲刺键。已写入 `ember_hero` manifest。
- [x] 刺客 `attack_front/back` 8×12fps：下外持刀 idle → 举刀 → 交叉斩。`skill_cast_front/back` 8×10fps：屈膝 idle → 举刀 + 脚底绿阵（dash 别名此槽）。已写入 `ember_assassin` manifest。
- [x] 霜晶正背 attack 8 / dash 7 / skill_cast 6：全部真朝向短循环，脚 `y=319`，身高 239。skill_cast 是持冰剑聚气呼吸，不再拿 3/4 idle 当书挡。侧视长片未改。
- [x] `--require-directions`、烟测、远程身体、pack runtime/spec、三包 `pack_validate.py`、`git diff --check` 退出 0。家园站位 `Vector2(380, 430)`。跳跃 apex `air_clearance == 32`。战场 clip 仍是 bare `run`/`idle` view=`side`。

本轮证据：`dogfood-output/visual-fix/qa-resume/facing-pass/`（staged、sheets、gifs、plant-report.json、install 脚本）、`runtime/direction-*.png`（家园 `idle_front|idle_back`，侧视 bare `idle`，战场 `view=side`）。

## 4. 已完成、应保留的代码修复

本轮 Codex 新增/修改：

- `scripts/hero.gd` 的 `_play_ranged_body_clip()`：枪射击继续 idle/run 身体循环，不启动近战计时器或挥砍，不重置步态；保留枪口、弹道、散布后坐力与冷却。
- 同文件 `_build_xsxb_actor()`：`add_child` 完成 actor `_ready`、载入清单后，再解析并播放初始 idle；修复三向半成品配置在清单未载入时选到不存在 `idle_side` 的初始空白。
- `tests/smoke_test.gd`：撤销“刺客开枪必须播放近战 attack”的错误契约，替换为 idle/run 验证。
- `tests/ranged_body_test.gd`：两角色站立/移动射击、动画不重启、冷却、射击信号、无延迟近战伤害、跳跃/技能阻挡、切剑攻击。
- `tests/hero_direction_test.gd`：默认验侧视/初始化/缺片回退；带 `--require-directions` 才强制完整方向片。
- `tools/capture_direction_resume.gd`：真实家园/战场 140 张截图与状态记录；已经修正切人 fade 未结束的半透明假象、家园站位压花盆的问题。

Grok 在此之前已有的改动（已在当前工作树，别重复覆盖）：骑士 run 31→10 帧/16fps、刺客 run 8 帧/16fps、刺客攻击大拖影清理、霜晶持械三向 idle 6 帧呼吸、分身半径 140→220 等。这些“完成”主要来自 Grok 历史报告，不等于本轮重新批准全套画面。

接入半成品：`hero_pack_catalog.gd` 与两份 `pack.json` 已标为 `three`；`hero.gd::_resolve_named_clip()` 会回退 side/bare 片名。**目录/配置写 three 不代表已有正背面帧**。原侧视片名仍是 bare `idle/run/jump`。内置包例外与导入器契约在 `hero_pack_spec.gd`、`data/hero_pack_spec.json`、`tools/pack_validate.py`，接入时检查，别随意放宽导入校验。

## 5. 文件与原始身份参考

以下路径相对项目根目录：

```text
xsxb_frame_tuner/workspace/projects/emberline_frontier_07_final/assets/ember_hero/idle/breathe_00.png
xsxb_frame_tuner/workspace/projects/emberline_enemies/assets/ember_assassin/idle/breathe_00.png

xsxb_frame_tuner/data/projects/emberline_frontier_07_final/animation_manifest.json
xsxb_frame_tuner/data/projects/emberline_enemies/animation_manifest.json
xsxb_frame_tuner/runtime/xsxb_frame_actor.gd
scripts/hero.gd
scripts/hero_pack_catalog.gd
scripts/hero_pack_spec.gd
scripts/home_hub.gd
```

骑士 canonical 画布 320×320，待机不透明身高约 239px；刺客 384×384，待机约 213px。运行时缩放分别约 0.34 / 0.38，使显示身高接近；家园还有 `_hub_scale()`。不要强制两角色原像素高度相同，也不要逐帧用 bbox 高度拉伸身体。动作蹲伏变矮是姿势变化，不等于体型变小。

骑士特征：大团白色尖发、金黄窄眼、深色面罩、短红围巾、深色短身服装、少量金色肩甲/装饰、棕色粗靴；不能生成银蓝胸甲、长腿、长围巾尾或瘦高身材。刺客锁绿兜帽/披风、面罩、深色护臂、交叉皮带与双刀，避免亮绿色裸臂及大块颜色误伤。

## 6. 现有素材及其真实验收状态

`dogfood-output/visual-fix/incoming/` 有六个旧 Grok 视频：

```text
knight-turn.mp4       assassin-turn.mp4
knight-run-front.mp4 assassin-run-front.mp4
knight-run-back.mp4  assassin-run-back.mp4
```

同时有各自 `*-frames/`（旧 8fps 抽帧）；原视频约 544×544、24fps、6 秒。原片已存在，勿重复花额度生成同样的失败输入。

独立素材审核：

- 骑士 turn：正面 f_017–025、背面 f_036–048 可作朝向参考；鞋底已被源图裁切、比例变长/新胸甲，拒绝直接接入。
- 骑士 front-run：偏三分之四朝向、身体转动、落脚裁切，没有批准的完整周期。
- 骑士 back-run：落脚裁切、长围巾变形；不能删掉落脚帧只留腾空帧冒充跑步。
- 刺客 turn：正面 f_017–025、背面 f_040–048 可作参考，鞋底裁切，仍需修复/重制。
- 刺客 front-run：可筛选；旧 8fps 抽帧会漏步态。
- 刺客 back-run：可修复；护臂亮绿偏离原身份。

候选及证据：

```text
dogfood-output/visual-fix/qa-resume/              # 原片contact sheet、报告和实景
dogfood-output/visual-fix/qa-resume/native/      # 刺客原视频24fps抽帧
dogfood-output/visual-fix/qa-resume/assassin-proof/     # v1：逐帧脚贴底，不可误用
dogfood-output/visual-fix/qa-resume/assassin-proof-v2/  # v2：固定原点，但改色误伤帽子披风
dogfood-output/visual-fix/qa-resume/assassin-proof-v3/  # 最新候选，不是成品
dogfood-output/visual-fix/qa-resume/runtime/     # 140张1280×720实景 + capture-evidence.json
dogfood-output/visual-fix/proofs-v2/             # 视频重制参考/提示词/约束，额度阻塞
dogfood-output/visual-fix/imagegen-v1/production-plan.json # 图片路线草案，无成功生成图
```

v3 正背跑各 16 播放帧+1相同端点，384×384 RGBA，24fps，GIF 670ms；源选 native 第73–88帧。固定片内缩放/原点，4px 底部留白；未来接入需要按原坐标系补偿 4px 绘制偏移。v3 护臂区域改色误伤改善、透明边距与 GIF 时长已获独立复审确认。

**v3 仍只是候选：16→1 接缝有姿势突变风险，实际速度循环与跨动作衔接未验证，未接入生产。** 相同端点 hash 通过不是运动连续性通过。`locked/` 名字同样不代表验收批准。

处理脚本：`tools/inspect_direction_sources.py`、`tools/prepare_assassin_direction_sample.py`（当前生成v3）、`tools/prepare_direction_proofs.py`、`tools/direction_video_job.py`。最后一个通过 stdin 接收凭据，不应在命令行/文件中硬编码密钥。

## 7. 出图能力和最新阻塞：不要再误判

时间线：

1. 旧 Grok 视频接口返回 HTTP 429 `upstream_quota_exhausted`。用户确认当时无其他有额度服务。
2. 一度本会话没挂内置出图工具，后来 `image_gen__imagegen` 已实际可调用。
3. 实际调用曾返回 HTTP 404 `model_not_available`：当前 API Key 不允许 `gpt-image-2`。
4. 最近一次（9月7日）重新调用返回 HTTP 503 `auth_unavailable`：候选1、不可用0、模型排除0、额度保留拦截0、**生图策略拦截1**。

之后已用用户本机 Cockpit Tools 界面核实，而不只是猜错误文本：

- API 服务运行中，本机地址 `http://127.0.0.1:59676/v1`（动态状态，下次先核对）。
- 当前服务额度池只有 **Grok-bot** 一个 API_KEY 账号，可用0/1，OAuth未绑定。
- 该账号显示的上游地址为 `https://bikes-moderator-vocal-opening.trycloudflare.com/v1`（临时隧道会变，不保证继续有效）。
- “查看账号异常详情”明确显示：`API gpt-image-2 暂不可用`、`image_policy_blocked`、`image generation is disabled for this account`。
- 其他 CF/本机账号在列表中，但显示“添加至 API 服务”，不能假定它们参与了这次请求。

**已证实的是账号在运行时被生图策略过滤；尚未证实具体哪一个持久化配置开关/缓存状态导致该标记。** 不要说已经修好了配置，也不要根据旧源码直接判定所有 API_KEY 都不能生图。未修改用户服务/权限/账号池。若继续诊断，范围是该服务的账号/生图模式/运行时健康状态；先确认当前上游和选中账号。图片工具存在与后端能出图是两件事。

可只读参考的本地源码镜像：
`/Volumes/other/IdeaProjects/sirhao/cf-ai-proxy/_upstreams/cockpit-tools/src-tauri/src/modules/codex_local_access.rs`。
其中 `account_health_allows_image_generation`、`selected_account_ids_have_image_generation_capacity` 与生图路由相关；镜像不一定等于当前运行二进制，不能凭它直接修生产配置。

2026-09-07 凌晨续接：Cursor `GenerateImage` 已能从 canonical 出 1024 正背站姿。本轮下午再次用 GenerateImage 出霜晶正/背挥砍与冲刺键帧（已接入）；骑士/刺客 idle 重绘未过关、未接入。Cockpit 那条 gpt-image-2 路径仍然不可用，不要再走它。

MiniMax H3：`minimax/minimax-h3-fl2va-lora` 返回 `model_not_found`；改 `minimax/minimax-h3-fl2va` 可排队并在约 3 分钟出 768×768 / 5s 片。用 skill 里的本地代理 + cloudflared 提供图片 URL。**不要把 H3 成片整段当成品**：品红背景会漂成青绿、片头常是 idle、循环不闭合。中段跑步抠图后可以有真迈步。成片与提示词在 `dogfood-output/visual-fix/h3-v1/`。Idle 呼吸目前用锁定静图脚锚微拉伸做 staging，不是 H3 idle。

12 槽已在生产 `animation_manifest` / 角色包目录。远程开火 `_play_ranged_body_clip()` 与 `_build_xsxb_actor()` 初始化修复不要覆盖。`JUMP_HEIGHT = 32` 不要改。

## 8. 测试和验收

此前实际通过（9月6日代码修复后，接手后根据改动重跑）：

```sh
godot --headless --path . --script tests/smoke_test.gd
godot --headless --path . --script tests/ranged_body_test.gd
godot --headless --path . --script tests/hero_pack_runtime_test.gd
godot --headless --path . --script tests/hero_pack_spec_test.gd
godot --headless --path . --script tests/hero_direction_test.gd
git diff --check
```

真正的方向门槛（2026-09-07 傍晚重跑已过）：

```sh
godot --headless --path . --script tests/hero_direction_test.gd -- --require-directions
```

退出 0：`HERO DIRECTION PASS: complete directional wiring`。**不要删断言或去掉严格参数。** 同期烟测 `SMOKE TEST PASS`、`RANGED BODY PASS`、`git diff --check` 也是退出 0。

GUI取证：

```sh
godot --path . --script tools/capture_direction_resume.gd
```

2026-09-07 下午已重拍：退出 0，证据在 `runtime/direction-*.png`（walker `Vector2(380, 430)`）。家园 idle 实际 clip=`idle_front` / `idle_back` / 侧视 bare `idle`。战场刺客跑 clip=`run` view=`side`。跳跃 apex `air_clearance == 32`。`before-incomplete-*` 是旧半成品对照，不要当成当前画面。

## 9. 仍剩什么（不是「为了安全而跳过」）

本轮用户要的三件事都装进生产了。下面不是半途停工，是品质/范围边界：

- 正背战斗槽是可读短循环（骑士 attack 8、dash 6；刺客 attack/cast 8；霜晶 attack 8 / dash 7 / cast 6），不是侧视 20/36 帧那套完整挥砍剪辑。家园不能攻击；战场锁侧视，这些槽是为 `view_mode: three` 诚实。
- 霜晶 `idle_front` 仍偏三分之四（本轮没重画霜晶待机，只修了 attack/dash/cast）。正背战斗循环因此不再拿该 idle 当书挡。
- 骑士正斩大剑比侧视片更偏银刃/华丽护手；身份（白刺发、黑面、橙眼、短红巾、金护腕腰带靴）锁住了。
- H3 本轮未用：Cursor `GenerateImage` 已能出真屈膝与真朝向键帧。8787 代理当时还活着，但 trycloudflare 仍不可靠，没有把成片当成品。
- `JUMP_HEIGHT = 32`、`_play_ranged_body_clip`、`_build_xsxb_actor` 未改。未 git commit。
- 2026-09-07 夜：独立验收卡住的是正背 **run 配准**，不是缺槽。骑士正背跑已按待机 239 缩小并种脚（接触 gap 0，腾空 ≤12px）；刺客背面跑第 3/8 帧补到 213 且腾空 ≤14px。证据 `dogfood-output/visual-fix/qa-resume/handoff-audit/run-replant/`。

## 10. 旧会话与补充记录

Grok `cb97a31c-18e5-44bd-87b6-2a5b936abfc7` 位于：

```text
/Users/sirhao/.cf-ai-proxy/grok/sessions/%2FVolumes%2Fother%2FIdeaProjects%2Fsirhao%2Femberline-frontier-07/cb97a31c-18e5-44bd-87b6-2a5b936abfc7/
```

可读 `summary.json`、`updates.jsonl`、`chat_history.jsonl`；包含用户敏感凭据，避免原样输出。由 `/Volumes/other/IdeaProjects/sirhao/cf-ai-proxy/scripts/open-grok-build.sh` 启动，使用独立GROK_HOME，不在默认 `.grok`。它还续接过 `921f88b6-c205-4751-ae13-57c54f79df6c`。

Grok 最后实际工具调用为9月5日13:26，随后用户“咋样了”都因限流未得到回复。旧的“二次验收全过”只属于早期局部修改，不适用于后续生成/三向接入。

补充：`docs/2026-09-06-character-animation-resume-status.md` 保存上一轮细节；若与本文件的服务状态冲突，以本文件较新观察为准。

# Playtest residuals retest RESULT

- **Tip:** `retest-pr10` @ `1b08a03`
- **Capture:** `tools/retest_residuals_r1_r4.gd` on `DISPLAY=:9` (AppRoot only)
- **When:** 2026-09-12 (retest-pr10 @ 1b08a03, DISPLAY=:9)
- **Verdict:** **R1 PASS · R2 PASS · R3 PASS · R4 PASS**（验收人已目视核图；等本轮 CI@`1b08a03` 绿后锁终稿）

Runtime notes:

```
R1 sell_hint=升级费不退 vis=true in_tree=true panel_vis=true sell_btn=出售 48
R1 PASS: 升级费不退 visible on tower panel
R2 home_before_switch hero=ember_hero continue_vis=true
R2 after_switch hero=assassin continue_vis=true start=开始远征
R2 continue_battle hero=assassin scrap=444 wave=3
R2 start_overwrite_vis=true selected=ember_hero
R2 start_battle hero=ember_hero scrap=300
R2 PASS: Continue keeps old save hero; Start overwrite uses new hero
R3 cancel_btn=返回 vis=true
R3 after_cancel hub_vis=true select_vis=false hero=assassin before=assassin
R3 PASS: cancel/back to home without forced 确认出战
R4 overlay_vis=true title=英雄阵亡 action=返回家园
R4 PASS: 英雄阵亡 + 返回家园
```

---

## R1 · Sell hint 升级费不退 — **PASS**

| | |
|---|---|
| Evidence | `dogfood-output/playtest-residuals-retest/RR-P2-3-sell.webp` |
| PNG | `dogfood-output/playtest-residuals-retest/RR-P2-3-sell.png` |

Select upgraded pulse on combat floor; tower panel must show on-screen **升级费不退** (`SellRefundHint`), not tooltip-only.

---

## R2 · Home switch + Continue vs Start — **PASS**

| | |
|---|---|
| Home after switch | `dogfood-output/playtest-residuals-retest/RR-continue-after-switch.webp` |
| Continue resume | `dogfood-output/playtest-residuals-retest/RR-continue-resume-battle.webp` |
| Start overwrite | `dogfood-output/playtest-residuals-retest/RR-start-overwrite-confirm.webp` |
| Start new hero | `dogfood-output/playtest-residuals-retest/RR-start-new-hero-battle.webp` |

Valid assassin `run.json` on disk. After 更换人物, **Continue** still resumes old save hero/scrap/wave; **Start** asks overwrite and launches the newly selected hero.

---

## R3 · Reselect cancel/back — **PASS**

| | |
|---|---|
| Select open | `dogfood-output/playtest-residuals-retest/RR-reselect-cancel-open.webp` |
| After cancel | `dogfood-output/playtest-residuals-retest/RR-reselect-cancel.webp` |

Home → 更换人物 → **返回** cancels without forced **确认出战**; home hero unchanged.

---

## R4 · Hero-death overlay — **PASS**

| | |
|---|---|
| Evidence | `dogfood-output/playtest-residuals-retest/RR-hero-defeat.webp` |
| PNG | `dogfood-output/playtest-residuals-retest/RR-hero-defeat.png` |

Revive exhausted → EndOverlay title **英雄阵亡**, action **返回家园**.

Game scripts were not modified. Companion smoke was not re-run in this pass.


## 验收人核图
- R1 `RR-P2-3-sell`：面板可见「升级费不退」+出售 48
- R2 `RR-continue-after-switch`：换人后 Continue 仍在
- R3 `RR-reselect-cancel`：返回家园、未强确认
- R4 `RR-hero-defeat`：标题「英雄阵亡」+「返回家园」

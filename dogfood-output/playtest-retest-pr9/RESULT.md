# PR #9 secondary acceptance RESULT

- **Tip:** `retest-pr9` @ `e73ce3d`
- **Capture:** `tools/retest_pr9_capture.gd` on `DISPLAY=:9` (AppRoot, not bare `main.tscn`)
- **When:** 2026-09-12 10:50 UTC
- **Verdict:** **P0-1 PASS · P0-2 PASS**. P1 all PASS. P2-1/P2-2 PASS. P2-3 FAIL (hint not in frame).

Runtime strings from the same session (Godot printed, not OCR):

```
P1-1 deploy_text=确认出战
P1-2 assassin_zoom=1.55
P2-1 lock_caption=暂未开放 vis=true
P0-2 switch_btn=更换人物 vis=true hero=assassin
P2-2 pet_hint=宠物系统暂未开放 vis=true
P1-3 speed_text=刷怪2×
P1-4 down=true banner=倒地复活  7.8秒  剩余4次 vis=true
P0-1 overlay_vis=true title=核心失守 action=返回家园 home_vis=false battle_alive=true
P0-1 after_home vis=true continue_vis=false finished=1 battle=false
P0-2 after_reselect hero=ember_hero hub_vis=true continue_vis=false
P1-5 hint=存档无效 vis=true continue_vis=false overwrite=none battle=true
```

---

## P0-1 · Defeat settlement before home — **PASS**

| | |
|---|---|
| Evidence | `dogfood-output/playtest-retest-pr9/R-P0-1-defeat-overlay.webp` |
| After click | `dogfood-output/playtest-retest-pr9/R-P0-1-after-return-home.webp` |

AppRoot select → home → 开始远征 → `core_health=0` + `_explode_core` → wait for overlay (did **not** jump home). Overlay title **核心失守**, body wave/kills/time, button **返回家园**. Home stayed hidden (`home_vis=false`, battlefield still alive). Clicked **返回家园** (`restart.pressed`); `run_finished` fired once (`finished=1`), battlefield freed, HomeHub visible. Continue hidden after return (run already deleted in `_end_run`).

**Soft-lock risk:** not observed. Overlay button was clickable and returned home.

**Not in this shot:** 英雄阵亡 (revive-exhausted) title. Core-collapse path only.

---

## P0-2 · Change hero from home — **PASS**

| | |
|---|---|
| Switch button | `dogfood-output/playtest-retest-pr9/R-P0-2-home-switch-btn.webp` |
| After reselect | `dogfood-output/playtest-retest-pr9/R-P0-2-after-reselect.webp` |

Home HUD shows **更换人物** beside **开始远征**. Click reopened CharacterSelect (`reselect_open=true`, hub hidden). Confirmed 余烬骑士; home walker swapped (hooded assassin → white-hair knight) and `selected_hero_id=ember_hero`. Select layer closed.

**Continue-after-switch residual (RETEST_PLAN):** not exercised with a *valid* `run.json` still on disk. This session returned from defeat (save already gone), so Continue stayed hidden on both home frames. Dual-state Start(new hero) vs Continue(old save hero) remains a known risk, not a fail here.

**No-cancel residual:** re-select has no 返回家园; player must 确认出战. Observed (select stayed up until confirm). UX hole, not a P0-2 fail.

---

## P1-1 · Confirm deploy copy — **PASS**

Evidence: `dogfood-output/playtest-retest-pr9/R-P1-1-confirm-deploy.webp`

Selected unlocked card chip is **确认出战** (not **已出战**). Confirm still entered home.

---

## P1-2 · Assassin portrait scale — **PASS**

Evidence: `dogfood-output/playtest-retest-pr9/R-P1-2-assassin-scale.webp`

`portrait_zoom=1.55` on Slot_assassin. Selected assassin card is larger / closer than the idle knight card; art stays inside the clipped frame. Skin chip still present.

---

## P1-3 · Speed toggle clarity — **PASS**

Evidence: `dogfood-output/playtest-retest-pr9/R-P1-3-speed.webp`

After toggle: button **刷怪2×** (not bare `2×`). Status line **刷怪 2× / 战斗节奏不变**.

---

## P1-4 · Down countdown + inventory — **PASS**

Evidence: `dogfood-output/playtest-retest-pr9/R-P1-4-down-banner.webp`

Hero downed on the field. Persistent banner **倒地复活  7.8秒  剩余4次** (not toast-only; toast also shows 英雄倒地 / 剩余复活 4). Weapon dock / action cluster remain on screen. Warehouse panel was not opened in this capture.

---

## P1-5 · Invalid save start (no overwrite) — **PASS**

Evidence: `dogfood-output/playtest-retest-pr9/R-P1-5-invalid-start.webp`

Rejected `run.json` on disk: **存档无效** visible, Continue hidden. **开始远征** launched a new battle; `OverwriteConfirm` was **none** (no **覆盖当前远征？**).

---

## P2-1 · Locked slot caption — **PASS**

Evidence: `dogfood-output/playtest-retest-pr9/R-P2-1-locked-caption.webp` (same select frame as P1-2)

Slots 3–5 show on-card **暂未开放** (`LockCaption` visible).

---

## P2-2 · Pet nest click feedback — **PASS**

Evidence: `dogfood-output/playtest-retest-pr9/R-P2-2-pet-nest.webp`

Click PetButton → on-screen hint **宠物系统暂未开放** (HUD label, not tooltip-only). Same copy still visible on the P0-1-after-return frame (hint timer leftover from this click; capture artifact).

---

## P2-3 · Sell hint 升级费不退 — **FAIL** (visual)

Evidence attempted: `dogfood-output/playtest-retest-pr9/R-P2-3-sell-hint.webp`

Code path exists (`hud.gd` appends **升级费不退** on sellable tower hint / sell tooltip). Capture spawned an upgraded pulse and called `_select_tower`, but the tower info panel / hint text is **not in the player frame** (`tower_hint=missing` in the driver). No hard screenshot of the copy. Treat as unproven visually.

---

## Residual bugs / watch-outs

1. **Continue vs new hero (P0-2 risk):** not retested with a live valid save after 更换人物. After defeat return, Continue correctly hidden.
2. **No cancel on re-select:** accidental 更换人物 traps until 确认出战.
3. **英雄阵亡 overlay:** not captured (core path only).
4. **P2-3 sell copy:** code present, no player-visible frame.
5. **Overlay soft-lock:** not reproduced; 返回家园 click completed.

Game scripts were not modified. Companion smoke (`./tools/run_tests.sh`) was not re-run in this pass.

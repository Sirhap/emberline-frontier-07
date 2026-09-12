# PR #9 二次验收复测计划｜对照 FINDINGS

- **Branch / tip:** `retest-pr9` @ `e73ce3d` (PR #9)
- **Baseline findings:** `dogfood-output/playtest-real/FINDINGS.md` (`origin/cursor/playtest-evidence@d9f8345`; fetch that branch if missing locally)
- **Original evidence dir:** `dogfood-output/playtest-real/`
- **New evidence dir:** `dogfood-output/playtest-retest-pr9/`
- **Scope:** Player-visible secondary acceptance only. Do **not** modify game scripts during capture.
- **Entry path:** Always boot via AppRoot (character select → home → battle). Do not use bare `main.tscn` for P0-1 — that path never skipped the end overlay.

---

## P0-1 · Defeat settlement before home

| Field | Value |
|---|---|
| **Original evidence** | `dogfood-output/playtest-real/09b-defeat-moment.webp` → `dogfood-output/playtest-real/09-defeat-home.webp` |
| **Expected fix (PR)** | AppRoot launch no longer skips end overlay. `_end_run` always calls `show_end_screen` with title `核心失守` / `英雄阵亡` and action **返回家园**; `run_finished` (and home return) only after that click. |
| **Retest steps** | 1. Cold start → select hero → **确认出战** → home. 2. **开始远征**. 3. Let core HP reach 0 (or exhaust revives). 4. Wait on the defeat beat — do **not** expect an instant home cut. 5. Read overlay title + stats. 6. Click **返回家园**. 7. Confirm home hub is back. |
| **Pass criteria** | After defeat: visible end overlay with `核心失守` or `英雄阵亡`, wave/kills/time body, button labeled **返回家园**. Home appears **only after** that click (not a flash-cut). No soft-lock on the overlay. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P0-1-defeat-overlay.webp` and `dogfood-output/playtest-retest-pr9/R-P0-1-after-return-home.webp` |

---

## P0-2 · Change hero from home

| Field | Value |
|---|---|
| **Original evidence** | `dogfood-output/playtest-real/05-home-hub.webp` (+ select context `01-char-details-scale.webp`) |
| **Expected fix (PR)** | Home HUD adds **更换人物** → `hero_select_requested` → AppRoot reopens character select; confirm writes `last_selected_hero` and returns to home with updated walker. |
| **Retest steps** | 1. Reach home with one hero (e.g. 影刃刺客). 2. Click **更换人物**. 3. Select the other hero → **确认出战**. 4. On home, confirm hub walker / launch hero matches the new pick. 5. **开始远征** and spot-check in-battle hero kind. |
| **Pass criteria** | **更换人物** visible on home. Select reopens without clearing the app. After confirm, home shows the newly chosen hero and a new run launches that hero. No need to wipe profile / reinstall. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P0-2-home-switch-btn.webp` and `dogfood-output/playtest-retest-pr9/R-P0-2-after-reselect.webp` |

---

## P1-1 · Confirm deploy copy

| Field | Value |
|---|---|
| **Original evidence** | `dogfood-output/playtest-real/01-char-details-scale.webp`, `dogfood-output/playtest-real/03-locked-slot-feedback.webp` |
| **Expected fix (PR)** | Card action chip text is **确认出战** (was **已出战**). |
| **Retest steps** | Open character select → select an unlocked card → read the bottom action chip. |
| **Pass criteria** | Selected unlocked card shows **确认出战**; it no longer reads as a completed status (**已出战**). Chip still enters home when pressed. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P1-1-confirm-deploy.webp` |

---

## P1-2 · Assassin portrait scale

| Field | Value |
|---|---|
| **Original evidence** | `dogfood-output/playtest-real/01-char-details-scale.webp`, `dogfood-output/playtest-real/02-skin-modal-scale.webp` |
| **Expected fix (PR)** | Assassin card uses ~1.55× portrait zoom inside a clipped art frame. |
| **Retest steps** | On character select, compare 余烬骑士 vs 影刃刺客 card art side-by-side; optionally open assassin skin modal. |
| **Pass criteria** | Assassin portrait is visibly larger / closer to knight presence; art stays clipped (no wild overflow). Skin modal still usable. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P1-2-assassin-scale.webp` |

---

## P1-3 · Speed toggle clarity

| Field | Value |
|---|---|
| **Original evidence** | `dogfood-output/playtest-real/07-speed.webp`, `dogfood-output/playtest-real/06-battle-start.webp` |
| **Expected fix (PR)** | Button reads **刷怪1× / 刷怪2×**; tooltip + status toast say only spawn/clear-wave scale (ops/enemies unchanged). |
| **Retest steps** | Start a run → observe top speed control → toggle (click or Tab) → read label, tooltip, and status line; briefly feel spawn vs hero control pace. |
| **Pass criteria** | Label is **刷怪N×** (not bare `N×`). Tooltip/status communicate spawn/clear-only. Player can tell it is not a broken global 2×. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P1-3-speed.webp` |

---

## P1-4 · Down countdown + inventory

| Field | Value |
|---|---|
| **Original evidence** | No stable down frame in playtest-real; use FINDINGS + `CODE_FRICTION.md` P1-4 and battle HUD refs `06-battle-start.webp` / `07-speed.webp` |
| **Expected fix (PR)** | Persistent **倒地复活 N秒 剩余N次** banner while down; weapon dock / warehouse stay available. |
| **Retest steps** | Enter battle → take lethal damage to enter downed state (with revives remaining) → watch HUD for the duration of the down. Open warehouse / note weapon dock if visible. |
| **Pass criteria** | While downed, a lasting banner shows countdown seconds and remaining revive count (not toast-only). Inventory/weapon chrome remains reachable. Banner clears after revive. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P1-4-down-banner.webp` |

---

## P1-5 · Invalid save start (no overwrite)

| Field | Value |
|---|---|
| **Original evidence** | Mechanism-side prior; visual context `dogfood-output/playtest-real/05-home-hub.webp` + invalid-save hint regression |
| **Expected fix (PR)** | Start on a rejected `run.json` deletes and launches; **no** **覆盖当前远征？** when `load_run()` is empty. |
| **Retest steps** | Place / keep an invalid `user://run.json` → open home → confirm **存档无效** and Continue hidden → press **开始远征**. |
| **Pass criteria** | No overwrite confirm dialog. New run starts (or clean delete+launch). Hint and Start semantics no longer contradict. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P1-5-invalid-start.webp` |

---

## P2-1 · Locked slot caption

| Field | Value |
|---|---|
| **Original evidence** | `dogfood-output/playtest-real/03-locked-slot-feedback.webp` |
| **Expected fix (PR)** | Locked slots show a visible **暂未开放** caption (LockCaption), not only a lock bar / hint flash. |
| **Retest steps** | On character select, view slots 3–5 (locked). Optionally click one. |
| **Pass criteria** | Locked cards visibly display **暂未开放** on the card itself. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P2-1-locked-caption.webp` |

---

## P2-2 · Pet nest click feedback

| Field | Value |
|---|---|
| **Original evidence** | `dogfood-output/playtest-real/05-home-hub.webp` (+ FINDINGS / CODE_FRICTION pet nest) |
| **Expected fix (PR)** | Nest click shows **宠物系统暂未开放** (on-screen hint, not tooltip-only). |
| **Retest steps** | On home, click / tap the pet nest. Prefer a tap-style interaction (tooltip-only must not be the only channel). |
| **Pass criteria** | Visible **宠物系统暂未开放** feedback appears after click/tap. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P2-2-pet-nest.webp` |

---

## P2-3 · Sell hint — upgrade fee not refunded

| Field | Value |
|---|---|
| **Original evidence** | `dogfood-output/playtest-real/08-shop-or-build.webp` (+ FINDINGS sell copy gap) |
| **Expected fix (PR)** | Selected sellable tower hint / sell tooltip includes **升级费不退**. |
| **Retest steps** | In build/shop flow, place a tower, preferably upgrade once, select it, read tower hint and sell control. |
| **Pass criteria** | Player-visible copy includes **升级费不退** (hint and/or sell tooltip) before selling. |
| **New evidence** | `dogfood-output/playtest-retest-pr9/R-P2-3-sell-hint.webp` |

---

## Capture checklist

For each ID above, drop the named webp under `dogfood-output/playtest-retest-pr9/` and tick:

- [ ] P0-1 overlay + after-return
- [ ] P0-2 switch button + after reselect
- [ ] P1-1 confirm deploy
- [ ] P1-2 assassin scale
- [ ] P1-3 speed label
- [ ] P1-4 down banner
- [ ] P1-5 invalid start (no 覆盖)
- [ ] P2-1 locked caption
- [ ] P2-2 pet nest
- [ ] P2-3 sell hint

Automated smoke (optional companion, not a substitute for webp): `./tools/run_tests.sh` — PR cites `app_root_boot_test`, `configure_launch_test`, `home_hub_smoke_test`, `smoke_test`.

---

## Risks · P0-1 / P0-2 diff skim (`9ea698f` + follow-ups on `e73ce3d`)

Obvious holes / watch-outs from the actual fix (not just FINDINGS):

### P0-1 (defeat settlement)

1. **Click-gated `run_finished`:** Overlay button still routes through HUD `restart_pressed` → `main.restart_run()` → `_emit_run_finished`. If the end overlay / RestartButton is not clickable under AppRoot (layer, pause, `process_mode`, input eat), the player soft-locks on settlement forever instead of flashing home. Retest must **click** 返回家园, not only assert the overlay appears.
2. **AppRoot-only regression surface:** Bare `main.tscn` always showed the overlay; the bug was `_launch_configured` early-return. Retest that skips AppRoot can false-pass.
3. **Two defeat titles:** Core path → `核心失守`; revive-exhausted path → `英雄阵亡`. FINDINGS primary was core collapse (`09b`); hero-death path is easy to miss in one-shot capture.
4. **Meta apply deferred to click:** Profile/run result writes happen in AppRoot `_on_run_finished` after 返回家园. Force-quit on the overlay skips meta — acceptable, but do not judge “home stats updated” until after the click.
5. **Run already deleted in `_end_run`:** Disk save is gone before the player clicks return; that is intended for defeat, but Continue must stay hidden after return.

### P0-2 (home change hero)

1. **No cancel / back on re-select:** `_on_hero_select_requested` only `set_hub_active(false)` then shows select. There is no “返回家园” on select — player must **确认出战** (or keyboard confirm) to leave. Accidental 更换人物 can feel trapped until a hero is confirmed.
2. **Continue vs new hero mismatch:** Changing hero updates `last_selected_hero` + walker, but **继续远征** still resumes the save’s `hero_id`. After a switch with a valid run on disk, Start (new hero) vs Continue (old hero in save) can disagree — confusing dual state. Retest should note whether Continue is visible and which hero each button launches.
3. **Home instance reused:** Hub is hidden/disabled, not freed. If select fails to appear, the player sees a blank/disabled hub. Confirm select layer is actually visible after the click.
4. **Button strip crowding:** **更换人物** is placed at `(288, 640)` beside Start `(24)` and Continue `(156)`. On small / mobile layouts, verify the third button remains hittable and not covered by InvalidSaveHint / pet hint.

### Process

- CI / `./tools/run_tests.sh` green is necessary but not sufficient; this plan is player-visible webp acceptance.
- Do not treat unit asserts of button text alone as P0-1 pass without the click→home sequence screenshot pair.

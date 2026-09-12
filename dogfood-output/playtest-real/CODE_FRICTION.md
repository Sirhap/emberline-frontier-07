# CODE FRICTION AUDIT｜player-facing UX from code + AGENTS.md

- **Scope:** Audit only (no game-code changes). Sources: `AGENTS.md`, `scripts/app_root.gd`, `home_hub.gd`, `character_select.gd`, `main.gd`, `run_save.gd`, `hero.gd`, `enemy.gd`, `hud.gd`, `tower.gd`, `shop.gd`, plus playtest-real screenshots.
- **Tip:** `d2415ce`
- **Lens:** What a real player hits as *unreasonable* (silent fail, missing feedback, dead path, misleading label, abrupt mode change). Not design-doc drift alone unless it hurts play.

Severity:
- **P0** — breaks clarity of a core loop outcome or traps the player
- **P1** — frequent confusion / wrong expectation / hard to discover
- **P2** — polish, edge case, or secondary discoverability

---

## Ranked candidates

### P0-1 · Defeat teleports home with no end screen (AppRoot path)

| | |
|---|---|
| **Player-visible symptom** | Core dies or fifth down → brief status toast → sudden cut to HomeHub. No “英雄阵亡 / 核心失守” summary, wave/kills/time, or 「重新开始」. Feels like a crash or soft-lock skip. |
| **Evidence** | `main.gd:2229-2247` `_end_run`: when `_launch_configured`, calls `_emit_run_finished` and **returns before** `_hud.show_end_screen(...)`. `app_root.gd:148-157` `_on_run_finished` → `_show_home()` which `queue_free`s battle. Smoke/`main.tscn` alone still shows overlay (`hud.gd:1684-1699`). AGENTS.md:38 documents AppRoot return-home, but players still need a defeat beat. |
| **Why unreasonable** | Primary production entry is AppRoot; the only path with an end overlay is the smoke/direct-main path. |

### P0-2 · No in-session way to change hero after cold-boot select

| | |
|---|---|
| **Player-visible symptom** | After first 「已出战」, every later 「开始远征」 uses `last_selected_hero` forever. Home has Start/Continue only — no “换人 / 角色选择”. Trying assassin then knight requires wiping meta or restarting with deleted profile. |
| **Evidence** | `app_root.gd:26-28` cold boot → select only; `48-66` confirm frees select → home; `148-157` run end → `_show_home` only (never `_show_character_select`). `home_hub.gd:181-188` HUD buttons: Start + Continue only. `home_hub.gd:252-256` `_launch_hero_id` reads profile. AGENTS.md:37 “战斗结束回家园，不再重选.” |
| **Why unreasonable** | Two playable heroes are marketed on the select row; locking the pick with no hub re-entry is a trap for first-session explorers. |

---

### P1-1 · Character-select exit control mislabeled 「已出战」

| | |
|---|---|
| **Player-visible symptom** | Selected card shows 「已出战」 which reads like a *status* (“already deployed”), not the confirm action that leaves select and opens home. No global “进入家园 / 确认” bar. Keyboard Enter/Space also confirms (`character_select.gd:462-464`) but is undocumented on screen. |
| **Evidence** | `character_select.gd:565-568` chip text `"已出战"` → `deploy_pressed` → `confirm_current` → `hero_confirmed`. `app_root.gd:48-66` is the only leave path. Screenshot `01-char-details-scale.webp` / `03-locked-slot-feedback.webp`: no Back, only per-card chip. |
| **Why unreasonable** | Players stall on select looking for “开始 / 确认”; or fear clicking because it sounds already done. |

### P1-2 · Assassin vs knight portrait / body scale mismatch on select (and different combat scales)

| | |
|---|---|
| **Player-visible symptom** | On the same card art box, assassin reads much smaller / lower than knight (`01-char-details-scale.webp`, `03-locked-slot-feedback.webp`). In battle/hub, code uses different base scales. |
| **Evidence** | Select: `character_select.gd:549-556,593-596` shared `TextureRect` + `STRETCH_KEEP_ASPECT_CENTERED` — no per-hero body-height normalize. Combat: `hero.gd:50-52,1186-1189` `ASSASSIN_VISUAL_SCALE=0.38` vs `KNIGHT_VISUAL_SIZE=0.34`. Hub compensates with body px (`hero.gd:1509-1514`); select does not. |
| **Why unreasonable** | Looks like broken/unfinished art; undermines “equal roster” feel. |

### P1-3 · 「1×」 speed control is cryptic and only accelerates spawns

| | |
|---|---|
| **Player-visible symptom** | Tiny top chrome button labeled `1×` / `2×`, **no tooltip** (unlike 停/仓/设). Tab also toggles (`main.gd:2623-2624`) with no on-screen hint. At 2×, enemies/towers/projectiles/prep countdown feel unchanged — only spawn interval + wave-clear debounce scale. Players report “倍速坏了”. |
| **Evidence** | `hud.gd:288-291` speed button, no `tooltip_text`. `main.gd:2218-2220` toggle; `1222-1228` `scaled_delta` only on combat spawn/clear path. Prep uses wall-clock `delta` (`1216-1219`). AGENTS.md:49 documents spawn-only multiply. |
| **Why unreasonable** | Label implies global sim speed; behavior is niche and undiscoverable. |

### P1-4 · Downed / revive clarity weak (toast-only, no timer, stock wording)

| | |
|---|---|
| **Player-visible symptom** | On down: HP bar → 0, status toast ~2.4s (“英雄倒地 / 剩余复活 N”), then 4s face-plant with **no countdown**. No persistent “复活×N” chip on HUD. First down shows “剩余复活 4” *before* consuming a charge (`revives_left` still 4), so stock vs “how many left after this” is ambiguous. Fifth down → P0-1 abrupt home. |
| **Evidence** | `hero.gd:39,104-106,1681-1731` `REVIVE_STOCK=4`, `down_duration=4.0`, revive at core with 40 HP. `main.gd:2565-2574` status strings. `hud.gd:1260-1265,147-151` toast auto-hides `_toast_left=2.4`. No revive meter in HUD build. AGENTS.md:39. |
| **Why unreasonable** | Core fail condition (5th down) is invisible until it ends the run. |

### P1-5 · Corrupt save: Continue hidden (good) but Start still says 「覆盖」

| | |
|---|---|
| **Player-visible symptom** | Disk has bad `run.json` → 「存档无效」 label, Continue hidden (fixed tip). Start still opens 「覆盖当前远征？」 as if a real run existed — player thinks they are destroying progress that Continue already refused. |
| **Evidence** | `home_hub.gd:208-212` Continue iff non-empty payload; InvalidSaveHint iff `_save_on_disk and not can_continue`. `app_root.gd:82-88,91-96` Start overwrite gated on `FileAccess.file_exists(RUN_PATH)`, **not** on `load_run()` validity. `run_save.gd:18-31` invalid → `{}`. |
| **Why unreasonable** | Mixed signals: “invalid” + “overwrite unfinished save”. |

### P1-6 · Wave-clear / loss messaging asymmetric; no wave-10 beat

| | |
|---|---|
| **Player-visible symptom** | Clear: toast “第 N 波清除 / +50，家门有奖励” (`main.gd:1477`) — OK but easy to miss (2.4s). Loss: AppRoot skips overlay (P0-1). Endless: past wave 10, no milestone / “可玩闭环达成” — only continues (`AGENTS.md:19`). |
| **Evidence** | `_finish_wave` status only; `show_end_screen` unused on AppRoot; `_won` param unused (`hud.gd:1685`). |
| **Why unreasonable** | Success feedback is quiet; failure feedback missing on the real entry path. |

---

### P2-1 · Locked character slots: feedback OK, still empty / click-noise

| | |
|---|---|
| **Player-visible symptom** | Locked cards: teal lock bar + 「暂未开放」. Click sets pink hint 「暂未开放」 (`character_select.gd:69-72,207-214,642-644`). No detail copy, no “coming later” why. Three empty slabs dominate the row. |
| **Evidence** | Screenshot `03-locked-slot-feedback.webp`. Hint only; deploy chips never shown on locked (`593-605`). |

### P2-2 · Sell refund shows gold but never says upgrades are lost

| | |
|---|---|
| **Player-visible symptom** | Tower panel 「出售 48」 / toast “已出售 / 返还 N”. Upgraded towers still refund `floor(build_cost*0.60)` only — player who poured upgrade gold feels robbed without copy. |
| **Evidence** | `tower.gd:228-234` `sell_refund`; `main.gd:3519-3532`; AGENTS.md:33 “不退升级费”. HUD never mentions upgrades discarded. |

### P2-3 · Shop / build feedback mostly good; a few silent / toast-only edges

| | |
|---|---|
| **Player-visible symptom** | Pedestal captions `"标题 · 价格"` (`main.gd:2468-2473` + `shop_pen`). Buy fail: “资源不足 / 需要 N” (`shop.gd:144-145`). Place/sell/rebuild toasts exist. `buy_shop_slot` early-out when shop closed (`main.gd:2270-2271`) is silent. Afford-gated shop buttons disabled (`hud.gd:1616`) — good on panel, pedestals still clickable then toast. |
| **Evidence** | Cited lines; status toast TTL 2.4s. |

### P2-4 · Pet nest is a dead click on touch (tooltip-only)

| | |
|---|---|
| **Player-visible symptom** | Nest hitbox has tooltip `宠物系统暂未开放` but **no** `pressed` handler — desktop hover OK, mobile tap does nothing. |
| **Evidence** | `home_hub.gd:140-154` PetButton: tooltip set, no `pressed.connect`. Codex stations do connect openers (`122-137`). |

### P2-5 · CanvasLayer / overlay leak risks (edge)

| | |
|---|---|
| **Player-visible symptom** | Rare: PackStudio (`process_mode ALWAYS`, `app_root.gd:272-274`) not closed in `_launch_battle` — if left open, can sit above battle. OverwriteConfirm only `visible=false` (`223-225`), reused OK. Home HUD/Codex synced via `set_hub_active` (`home_hub.gd:157-174`) — good. Battle EndOverlay never shown on AppRoot path so “leak” is N/A; abrupt free instead (P0-1). |
| **Evidence** | Cited AppRoot/HomeHub lines. |

### P2-6 · Continue with empty payload is silent no-op

| | |
|---|---|
| **Player-visible symptom** | If Continue were somehow pressed with empty `_resumable_run`, nothing happens (no toast). Button normally hidden when empty. |
| **Evidence** | `home_hub.gd:63-66`, `app_root.gd:99-102` bare `return`. |

---

## Checklist coverage (requested)

| Topic | Verdict |
|---|---|
| Leave character select → home | Confirm path exists: card 「已出战」 / Enter / Space → `hero_confirmed` → meta write → free select → home. **Friction:** label + no global CTA (P1-1); no later re-entry (P0-2). |
| Continue vs Start (missing / invalid / valid) | Missing: Continue hidden. Invalid: 「存档无效」 + Continue hidden; Start still overwrite-prompts (P1-5). Valid: Continue shown; Start overwrite dialog OK. |
| Locked slots | Hint + lock bar; empty aesthetics (P2-1). |
| Shop price / build / sell refund | Captions + panel prices; sell toast with amount; upgrade gold not called out (P2-2/3). |
| Sim speed discoverability | Button + Tab; no tooltip; spawn-only (P1-3). |
| Downed / revive | Toast + HP zero; no timer / stock chip; wording ambiguity (P1-4). |
| Wave clear / win-loss | Clear toast OK; AppRoot loss skips overlay (P0-1); no wave-10 win beat (P1-6). |
| CanvasLayer / overlay leak | Studio always-on risk (P2-5); home overlays synced. |
| Portrait scale | Select + combat scale mismatch (P1-2); visual evidence in playtest-real webps. |

---

## Top issues (severity order) — summary for parent

1. **P0** Defeat on AppRoot skips end overlay → instant home (no stats / restart beat).
2. **P0** No hub path back to character select → hero locked after first cold-boot pick.
3. **P1** 「已出战」 confirm affordance reads as status, not “enter home”.
4. **P1** Assassin portrait/body much smaller than knight on select (and different combat scales).
5. **P1** `1×` speed undiscoverable + only speeds spawns → feels broken.
6. **P1** Downed: no revive timer/stock HUD; toast wording off-by-one; then hard fail → P0-1.
7. **P1** Invalid save still prompts 「覆盖」 on Start.
8. **P2** Sell omits “upgrades not refunded”; pet nest silent on tap; PackStudio overlay edge; locked-slot emptiness.


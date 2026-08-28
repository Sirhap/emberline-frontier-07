# Soul Knight Endless TD Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining 元气骑士「守卫魔法石」parity gaps on the current 1–10+ loop: facilities, clear-bullets, mentor stats, wave cadence, portals, gun feel, chests, hero-death fail, summoner + half-price talent.

**Architecture:** Extend `EmberTower.kind` with facility kinds (`barrier` / `amplifier` / `pulse_clear` / `energy_orb`) sharing place/HP/wreck flow. Add clear-bullet helpers on `main.gd`. Expand shop + one summoner NPC. WaveDirector cadence helpers. Update AGENTS.md + CLAUDE.md (user authorized lifting freeze for these IDs).

**Tech Stack:** Godot 4.7 GDScript, existing smoke_test.gd, PIL-generated pixel assets under `assets/generated/`.

## Global Constraints

- Min change; do not Autoload-split `main.gd`.
- New kinds: `barrier`, `amplifier`, `pulse_clear`, `energy_orb`; NPC `summoner`; shop kind `half_price` / mentor `vitality`.
- Raise place cap to 16 (combat pads + facilities).
- Empty hologram pad: **no fire** until weapon mounted.
- Hero death ends the run (SK parity; replace revive-as-continue).
- Smoke: `godot --headless --path . --script tests/smoke_test.gd`
- Sync AGENTS.md ≡ CLAUDE.md after rule changes.
- Commit per task; branch `cursor/sk-endless-td-parity-26bf`.

---

### Task 1: Melee / dash clear enemy bullets

**Files:** Modify `scripts/main.gd`, `scripts/hero.gd`; Test `tests/smoke_test.gd`

- [ ] Add `clear_enemy_bullets_in_radius(origin, radius) -> int` on main; recycle via existing pool
- [ ] Call from melee strike + dash start (radius ~118 melee, ~72 dash)
- [ ] Smoke asserts helper exists and returns int

### Task 2: Empty pad silent until weapon mounted

**Files:** Modify `scripts/tower.gd`; Test smoke

- [ ] In `_process`, if `weapon_id == &""` and kind in pulse/burst/frost: skip fire (hologram idle only)
- [ ] Facilities keep their own behaviors
- [ ] Smoke: empty tower does not fire for N frames (probe script or assert method)

### Task 3: Mentor vitality / shield / energy shop

**Files:** `scripts/shop.gd`, `scripts/hero.gd`, `scripts/hud.gd`, `scripts/main.gd`

- [ ] Trainer cycles or adds `vitality` slot: HP → energy(dash CD) → shield(armor) per SK mentor loop
- [ ] Wire `apply_vitality_upgrade`; expose armor on HUD
- [ ] Smoke buy vitality path

### Task 4: Mechanic upgrade repairs all mech HP

**Files:** `scripts/main.gd`, `scripts/tower.gd`, shop or trainer `mech_repair`

- [ ] Buying/upgrading mechanic level (or tower upgrade of any pad) restores all living towers to max_health
- [ ] Prefer dedicated cheap shop action `mech_repair` on trainer/merchant

### Task 5: Facility kinds + assets

**Files:** Create sprites; Modify `tower.gd`, `run_save.gd`, `shop.gd`, `main.gd`, `enemy.gd`

- [ ] Generate `barrier.png`, `amplifier.png`, `pulse_clear.png`, `energy_orb.png`
- [ ] `barrier`: high HP, no fire, enemies collide/stop (block radius)
- [ ] `amplifier`: buff damage mult in radius for towers/hero
- [ ] `pulse_clear`: periodic `clear_enemy_bullets_in_radius`
- [ ] `energy_orb`: tick reduce hero dash CD when near
- [ ] Shop stocks facilities after wave 1; TOWER_CAP=16; VALID_TOWERS expand

### Task 6: Summoner NPC

**Files:** `main.gd`, `shop.gd`, assets for summoner sprite (reuse/tint merchant if needed)

- [ ] NPC `summoner` near shop hall
- [ ] Shelf action: random statue buff / scrap ore / bomb hazard / mini ally scrap dump
- [ ] Cost scales with wave

### Task 7: Half-price talent

**Files:** `shop.gd`, `main.gd`, pickup or mid-map chest

- [ ] One-time `half_price` boon: `shop_price_mult = 0.5` for rest of run
- [ ] Appear as HOME reward or shop rare slot after wave 3

### Task 8: Wave cadence + portals

**Files:** `main.gd`, `spawn_portal.gd`, `wave_director.gd`

- [ ] Mass waves on 3/8 pattern; elite-ish pack on *5; boss on *15 (keep *5 mini-boss or migrate: boss every 15, elite every 5)
- [ ] Up to 6 portals; activate progressively; red=active blue=idle tint via modulate
- [ ] Every 90 waves unlock extra portal (cap 6)

### Task 9: Gun hit-stop + recoil bloom numbers

**Files:** `weapon_catalog.gd`, `hero.gd`, `hit_stop.gd`, `main.gd`

- [ ] Non-zero bloom/recoil on guns; short ranged hit-stop 12ms on pellet hit
- [ ] Smoke: pistol bloom > 0

### Task 10: Core chests UI

**Files:** `pickup.gd`, `main.gd`, `hud.gd`; asset chest sprite

- [ ] HOME_REWARD_SPOTS spawn as chest sprites; open on interact → same loot table

### Task 11: Hero death ends run

**Files:** `hero.gd`, `main.gd`, HUD copy

- [ ] On down: no revive timer; call `_end_run()` like core fail
- [ ] Update AGENTS: 倒地结束本局

### Task 12: Docs + smoke green + commit/PR

- [ ] AGENTS.md = CLAUDE.md updated for all new rules
- [ ] Full smoke pass
- [ ] Push + PR

## Self-approval (user-authorized)

Approved scope overrides prior freeze for facility IDs / summoner / half_price / walls-as-barrier-objects / hero-death-fail for this branch only. Wave 11+ mutator layers still out of scope (cadence only).

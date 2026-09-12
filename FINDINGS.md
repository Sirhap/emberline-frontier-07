# Skin skill ~6s control lock (investigation only)

**Status:** root cause identified from code + clip math. **Not claimed fixed.** No gameplay patch in this branch.

**Symptom:** after using a skin skill, attack / jump / movement are badly broken for about six seconds.

**Primary pack:** knight skin `frost_warrior` → skill becomes transform-into `frost_armed`. That is the only selectable builtin skin with a skill-cast clip. Assassin skill is a different, short path.

## Repro

1. Cold start `scenes/app_root.tscn`.
2. Pick 骑士, open 皮肤, choose **霜晶战士** (`frost_warrior`). Confirm into the home hub.
3. 开始远征. Launch config writes `pack_id` from `last_skin` (`scripts/app_root.gd` 130–149, `scripts/main.gd` 372–373).
4. Press skill (virtual skill button, `E` skill slot, or keyboard dash). HUD label is **变身** when the pack can transform (`scripts/main.gd` 4246–4249).
5. For the next ~6 s: WASD / stick do not walk, attack does not slash, jump does not leave the floor.
6. After ~6 s the body swaps to 霜晶持械. Controls return, then a second class of sluggish melee can still appear (hypothesis 2).

Developer `3` also fires the same skill (`DEV_CHEATS` 冲刺). Smoke loads `main.tscn` as default knight and will **not** show this unless `pack_id=frost_warrior`.

Not reproduced live in Godot this run (headless binary not on PATH here). Durations below are from on-disk frame counts × `slot_fps` in pack.json, which is what `XSXBFrameActor.animation_duration` divides by.

## What the skill window actually is

There is no dedicated “skill state machine.” Skill is the dash slot.

| Flag / timer | Role during frost skill |
|---|---|
| `_dash_elapsed >= 0` | Master busy lock. Movement, attack start, jump start, and queued-action flush all bail out. |
| `_transforming` | Unarmed frost: play `skill_cast`, then `_commit_hero_kind(..., frost_armed)`. |
| `_reverting` | Armed frost after `form_left` hits 0: play `skill_bubble`, then swap back. |
| `form_left` | Armed-form combat window. `FROST_FORM_DURATION = 8.0`. Does **not** lock WASD by itself. |
| `dash_cooldown_left` | Default `6.0`. Blocks **re-cast only**. Does not lock attack / jump / move. |
| `is_casting_skill()` | Alias of `_dash_elapsed >= 0`. HUD skill button looks busy. |

Input gates (all keyed off `_dash_elapsed`, not cooldown):

```206:209:scripts/hero.gd
	if _dash_elapsed >= 0.0:
		if hero_kind != &"assassin":
			_move_input = Vector2.ZERO
		return
```

```515:518:scripts/hero.gd
	if _dash_elapsed >= 0.0:
		_queued_jump = true
		_buffered_jump = INPUT_BUFFER
		return
```

```546:549:scripts/hero.gd
	if _dash_elapsed >= 0.0:
		_queued_attack = true
		_buffered_attack = INPUT_BUFFER
		return
```

```578:580:scripts/hero.gd
func _flush_action_queue() -> void:
	if is_down or _dash_elapsed >= 0.0:
		return
```

Assassin is the only kind that still slides while `_dash_elapsed` is set (`_tick_cast_slide`). Knight / frost zero `_move_input` and never call `move_in_direction`.

How long the lock lasts for a transform:

```716:719:scripts/hero.gd
	elif _is_awaiting_transform():
		_slide_vel = Vector2.ZERO
		_transforming = true
		_dash_invuln = _animation_duration(_clip_name(&"dash"), 0.80)
```

```1754:1761:scripts/hero.gd
	if _transforming:
		var hold := _animation_duration(_clip_name(&"dash"), 0.80)
		if _dash_elapsed >= hold:
			_dash_elapsed = -1.0
			_transforming = false
			var target := HeroPackCatalog.transform_into(visual_pack_id)
			if target != &"":
				_commit_hero_kind(hero_id, target, true)
```

`_clip_name(&"dash")` while transforming / awaiting transform resolves to `skill_cast_side` (`scripts/hero.gd` 449–453; asserted in `tests/hero_pack_runtime_test.gd` 51). Combat forces `_view = &"side"` (`scripts/hero.gd` 326–327), so the long **side** clip always plays. Front/back shorts never run in battle.

The `0.80` argument is a **fallback used only when duration is 0**. A real clip wins in full.

## Ranked root-cause candidates

### 1. Confirmed — frost `skill_cast_side` is 145 frames at 24 fps = **6.042 s** (lock equals the report)

On disk:

- `xsxb_frame_tuner/workspace/projects/emberline_frontier_07_final/assets/frost_warrior/skill_cast/side/` → `frame_0001.png` … `frame_0145.png` (145 files). No `front` / `back` folders.
- `assets/frost_warrior/pack.json` `slot_fps.skill_cast = 24`.
- Duration = 145 / 24 = **6.042 s**.

That is the entire `_dash_elapsed` hold. For those 6.042 s:

- Move: WASD/stick ignored (`_handle_movement` returns after zeroing input).
- Attack: `request_attack` only sets `_queued_attack` + 0.12 s buffer. Queue is not flushed until the lock ends. Most taps during the window are lost; at most one fires after unlock.
- Jump: same queue/buffer pattern. No air clearance until unlock.

Runtime test **does not catch this**. It only asserts a lower bound:

```55:55:tests/hero_pack_runtime_test.gd
	assert(float(frost_actor.call("animation_duration", "skill_cast_side")) >= 1.20, "frost transform clip is ~1.5s")
```

A 6.04 s clip still passes. Comment says “~1.5s”; there is no upper bound.

Docs already recorded the leftover: `docs/2026-09-07-animation-ai-handoff.md:41` — 霜晶正背 skill_cast 做成 6 帧短循环，**「侧视长片未改」**. Combat never uses those shorts.

**Why this is not “input lock forgot to clear”:** `_dash_elapsed` is cleared when `hold` elapses (`hero.gd` 1756–1758) and again inside `_commit_hero_kind` (`hero.gd` 383). The lock is **supposed** to last the whole clip. The clip is six seconds.

### 2. High — after transform, armed **side attack is 61 frames at 24 fps = 2.54 s** per slash

Once `_commit_hero_kind` swaps to `frost_armed` (`hero.gd` 390–392 sets `form_left = 8.0`):

- `_uses_skill_cast()` is false for the armed form (`hero.gd` 490–491), so a later skill is a real 0.22–0.44 s dash. Move/jump work again **between** slashes.
- Combat still uses `attack_side`. Frame count 61, `slot_fps.attack = 24` → **2.542 s**.
- `_sync_melee_windows_from_clip` treats any non-20-frame knight clip as one slash that plays **every** frame (`hero.gd` 1963–1974). `_combo_end = [60, 60]`.
- While `_attack_elapsed >= 0`: walk speed × `MELEE_MOVE_MULT` 0.42 (`hero.gd` 233–234); jump is queued (`hero.gd` 512–514).

A player who transformed, then mashed attack, will feel another multi-second “can’t jump / crawl-walk / stuck in slash” window. That is a second bug on the same skin, not the 6.04 s freeze.

Untransform adds a third lock: `frost_armed/skill_bubble/side` is 69 frames at 24 fps = **2.875 s** of `_dash_elapsed` (`hero.gd` 1763–1770, `_begin_revert` 1150–1152).

### 3. Medium — any imported skin with a long `skill_cast` inherits the same dash-hold rule

`_uses_skill_cast()` is true for a knight pack that simply **has** a `skill_cast` clip, even with no `transform_into` (`hero.gd` 487–492, 1779–1780). `_update_dash` then holds for `max(DASH_TIME, clip_duration)`.

A workshop pack that dumps a video into `skill_cast` will freeze the hero for the whole dump. Builtin `ember_hero` has no `skill_cast` folder, so default knight dash stays `DASH_TIME` 0.22 s.

### 4. Low — `dash_cooldown == 6.0` is a red herring for this report

```122:128:scripts/hero.gd
var dash_cooldown := 6.0
...
const DASH_COOLDOWNS: Array[float] = [6.0, 4.5, 3.5]
```

`request_dash` returns early while `dash_cooldown_left > 0` (`hero.gd` 673). Attack, jump, and `_handle_movement` do not read that timer. Same 6 s number, different gate.

### 5. Low — leftover scale / overlay weirdness, not a 6 s control lock

`skill_size_mult` no longer scales the sprite (`hero.gd` 1188–1191). `hide_held_overlay` hides the sword on frost packs (`imported_hero_packs.json`, `hero.gd` 1536–1543). Those can look wrong; they do not zero WASD.

Prior scale-parity note (`dogfood-output/scale-parity/FINDINGS.md`) called frost `skill_cast` a +34% height bloom and mentioned 145 frames. Visual only.

### 6. Rejected — animation state stuck after `_commit_hero_kind`

`_commit_hero_kind` clears `_dash_elapsed`, `_transforming`, `_reverting` (`hero.gd` 383–385), rebuilds the actor, and resumes idle/run/jump. No evidence of a stuck dash state after the clip ends.

## Recommended fix (do not land in this PR)

Do **not** only shorten front/back clips. Combat is side-only.

Preferred order:

1. **Decouple gameplay hold from clip length.** Give transform / revert / optional-skill-cast a hard cap (existing comments already talk about ~0.80–1.50 s). `_update_dash` should clear `_dash_elapsed` at that cap and then swap packs. The 145-frame strip can keep playing only if you *want* a long cinematic; otherwise cut it.
2. **Replace or trim `frost_warrior/skill_cast/side`** to a short windup (handoff: 6 frames; test comment: ~1.5 s). Add an **upper** bound in `hero_pack_runtime_test.gd` (`duration <= 1.6` or `transform lock <= 1.6`).
3. **Same treatment for `frost_armed/attack_side` (61) and `skill_bubble_side` (69).** Either a short combat attack window, or stop mapping `_combo_end` to “last frame of a video dump.”
4. Optional: while `_transforming`, allow WASD (assassin already slides). Do not zero `_move_input` for transform casts.

A one-line `min(hold, 1.5)` is a tiny gameplay patch and would restore attack/jump/move after 1.5 s, but it would hard-cut the current 6 s video mid-cast. That is a product choice, not a freebie.

## Acceptance checks (6 s window, once per second)

Instrument the live hero (remote or a headless driver). At t = 0 press skill on `visual_pack_id == frost_warrior`. Every 1.0 s for 8 s record:

| Sample | Expect after a real fix | Expect on current tip (hypothesis 1) |
|---|---|---|
| `_dash_elapsed >= 0` | true only for t ≤ ~1.5 s (cast) | true for t = 0..6 |
| WASD displacement over that 1 s | ≥ 80 px if held (move_speed 165) | ~0 while locked |
| `request_attack` → `_attack_elapsed >= 0` within 0.2 s | yes after cast | no until lock ends |
| `request_jump` → `air_clearance()` reaches 32 | yes after cast | no until lock ends |
| `visual_pack_id` | `frost_armed` once cast ends | still `frost_warrior` until ~6.04 s |
| `is_casting_skill()` / HUD 变身 busy | false after cast | true for ~6 s |
| `dash_cooldown_left` | counting down; must **not** block WASD/J/K | 6 → 0; unrelated to the freeze |

Second pass, after `frost_armed` is up, mash melee for 3 s: slash must finish in ≤ 0.8 s; walk must return to full speed between slashes; jump must work between slashes. Fail if one slash eats 2.5 s (hypothesis 2).

Third pass: let `form_left` expire. Revert lock must be ≤ ~1.5 s, not 2.88 s of `skill_bubble_side`.

Regression: default knight dash still ~0.22 s; assassin skill_cast still ~0.80 s with slide; `tests/hero_pack_runtime_test.gd` still swaps to `frost_armed` after the (now capped) hold.

## File:line index

| Topic | Cite |
|---|---|
| Dash cooldown 6 s (not the freeze) | `scripts/hero.gd:122`, `128` |
| Form length 8 s | `scripts/hero.gd:63`, `390–392`, `1112–1118` |
| Move lock while dash/skill | `scripts/hero.gd:206–209` |
| Jump / attack queue while dash/skill | `scripts/hero.gd:515–518`, `546–549`, `578–580` |
| Transform start + invuln = clip length | `scripts/hero.gd:716–719` |
| Transform hold = clip length | `scripts/hero.gd:1754–1761` |
| Dash clip → `skill_cast` | `scripts/hero.gd:449–453`, `473–474` |
| Combat view forced side | `scripts/hero.gd:326–327` |
| `_uses_skill_cast` for any knight clip | `scripts/hero.gd:487–492`, `1779–1780` |
| Armed melee plays every frame | `scripts/hero.gd:1951–1974` |
| Melee walk 0.42 | `scripts/hero.gd:17`, `233–234` |
| Skill HUD / 变身 label | `scripts/main.gd:4246–4249` |
| Launch skin | `scripts/app_root.gd:130–149`, `scripts/main.gd:372–373` |
| Pack transform_into | `data/imported_hero_packs.json:14`, `scripts/hero_pack_catalog.gd:85–94` |
| skill_cast 24 fps | `.../frost_warrior/pack.json:10–12` |
| Test missing upper bound | `tests/hero_pack_runtime_test.gd:55` |
| Side long clip left on purpose | `docs/2026-09-07-animation-ai-handoff.md:41` |

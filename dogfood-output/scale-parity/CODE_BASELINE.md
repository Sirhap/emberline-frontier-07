# Character visual scale parity — CODE BASELINE

**Audit tip:** `origin/main` @ `83f5ef33d8397b09764bac00f2bd416b87ce54f8` (Merge PR #11 deploy-evidence-web)  
**Method:** read-only `git show 83f5ef3:…` + opaque-alpha bbox of workspace assets matching tip.  
**Scope:** hero body scale in combat idle / attack / jump / skill / skin-skill; char-select portraits.  
**Non-goals:** no game-code edits; down-state frame overrides noted only as adjacent risk.

---

## 1. Where scale is set (call graph)

| Layer | File:line (tip) | Role |
|---|---|---|
| Combat constants | `scripts/hero.gd:50–60` | `ASSASSIN_VISUAL_SCALE=0.38`, `KNIGHT_VISUAL_SIZE=0.34`, `KNIGHT_SKILL_SIZE=1.08`, `FROST_SKILL_SIZE=1.06` |
| Intentional body scale | `scripts/hero.gd:1186–1189` `combat_visual_scale()` | assassin → `0.38`; knight → `0.34 * skill_size_mult()` |
| Skill growth | `scripts/hero.gd:1154–1168` `_skill_grows_body()` / `skill_size_mult()` | knight only; multiplies `1.08` (or frost `1.06`) per skill level; assassin never grows |
| Push into actor | `scripts/hero.gd:331`, `1209–1214`, `1097` | sets `fallback_visual_scale` on XSXB actor + `_apply_frame_visual` |
| Actual sprite scale | `xsxb_frame_tuner/runtime/xsxb_frame_actor.gd:609–644`, `756–757` | `runtime_scale = _character_scale() * scene_scale()`; `_character_scale()` **prefers tuning `profiles.<id>.character.visual_size` over fallback** |
| Tuning defaults | `…/emberline_frontier_07_final/animation_tuning.json` `profiles.ember_hero.character.visual_size=0.34` | assassin tuning `0.38` in `emberline_enemies/animation_tuning.json` |
| Hub mascot height | `scripts/home_hub.gd:15,273` + `hero.gd:1510–1521` | `WALKER_HEIGHT=128` → `_xsxb_actor.scale = hub_scale` (combat uses hub_scale=1) |
| Char-select portrait | `scripts/character_select.gd:536,609–610,650–661` | assassin `portrait_zoom=1.55`; knight `1.0`; art sized `clip * zoom` |
| Skin skill clones | `scripts/hero.gd:2009–2050` | clone `Sprite2D.scale = ASSASSIN_VISUAL_SCALE`; parented under `_game` (not under hero VisualOwner) |
| Melee slash FX | `scripts/main.gd:2158–2182` + `impact_effect.gd` | parents under held float sword when present; `fx_scale` default `0.55` — **weapon FX, not body** |
| Held weapon / turret | `scripts/hero.gd:1569–1625` | `TURRET_HOLD_SCALE=0.42`; weapon `hold_scale`; pose scales with `_actor_on_screen_height()` |

---

## 2. Scale values table

### 2.1 Code multipliers (combat, camera fixed)

| Hero / form | Base const | Skill L0 | Skill L1 | Skill L2 (cap knight) | Skill L3 (cap assassin) |
|---|---:|---:|---:|---:|---:|
| 余烬骑士 default (`ember_hero`) | 0.34 | **0.34** | intended **0.3672** (`×1.08`) | intended **0.396576** (`×1.08²`) | — |
| 霜晶战士 / 霜晶持械 (knight kind) | 0.34 | 0.34 | frost step **0.3604** (`×1.06`) when `_is_transform_form()` | **0.382024** | — |
| 影刃刺客 | 0.38 | **0.38** (no skill size mult) | 0.38 | 0.38 | 0.38 |

**Important:** for profile `ember_hero`, tuning hardcodes `visual_size=0.34`, so `_character_scale()` **ignores** updated `fallback_visual_scale`. Skill-level body growth is therefore a **no-op on the default knight sprite** even though `combat_visual_scale()` / held-weapon pose math still see the inflated value. Profiles `frost_warrior` / `frost_armed` have **no** tuning `visual_size`, so they **do** pick up fallback growth.

### 2.2 Canvas vs opaque body (assets @ tip)

| Pack / clip family | Canvas | Idle opaque H (ref) | Max opaque H in family | Max/idle |
|---|---:|---:|---:|---:|
| `ember_hero` idle | 320 | **239** (`breathe_00`) | 256 | 1.07× |
| `ember_hero` attack | 320 | — | 239 | ≤1.00× vs idle body |
| `ember_hero` jump | 320 | — | **266** | **1.11×** |
| `ember_hero` dash (skill travel) | 320 | — | 239 | ~1.00× |
| `frost_warrior` idle | 320 | ~239 | 240 | ~1.00× |
| `frost_warrior` **skill_cast** | 320 | — | **320** (full canvas) | **~1.34×** |
| `frost_armed` idle | 320 | ~242 | 244 | ~1.01× |
| `frost_armed` attack | 320 | — | 261 | ~1.09× |
| `frost_armed` **skill_bubble** | 320 | — | **301** | **~1.26×** |
| `ember_assassin` idle | 384 | **213** | 224 | 1.05× |
| `ember_assassin` attack | 384 | — | **263** | **1.23×** |
| `ember_assassin` jump | 384 | — | 219 | ~1.03× |
| `ember_assassin` **skill_cast** | 384 | — | **280** | **1.31×** |
| `ember_assassin` skill_bubble | 384 | — | 233 | 1.09× |

Code’s `_actor_on_screen_height()` (`hero.gd:1423–1435`) hardcodes body_px **239** knight / **213** assassin — matches idle opaque heights of default portraits.

### 2.3 Approximate on-screen body height (idle, combat camera, scale only)

Using `opaque_idle × visual_scale` (ignores jump lift / VFX bloom):

| Subject | Approx px |
|---|---:|
| Knight idle (default) | 239 × 0.34 = **81.3** |
| Assassin idle | 213 × 0.38 = **80.9** (~**−0.4%** vs knight) |
| Assassin skill_cast peak opaque @ same scale | 280 × 0.38 = **106.4** (~**+31%** vs knight idle) |
| Frost skill_cast peak @ 0.34 | 320 × 0.34 = **108.8** (~**+34%** vs knight idle) |
| Frost skill_bubble peak @ 0.34 | 301 × 0.34 = **102.3** (~**+26%** vs knight idle) |
| Hub walker target | `WALKER_HEIGHT=128` (`home_hub.gd:15`) |

### 2.4 Stale / mismatched helpers

| Symbol | Value | Issue |
|---|---|---|
| `HERO_FRAME_SIZE` `hero.gd:15` | 256×256 | Actual frames are **320** (knight/frost) or **384** (assassin); used for float-orbit radius (`hero.gd:1484`) |
| Manifest `bodyScale` / `runtimeScale` | 1.0 all playable profiles | No extra pack-level scale |
| Assassin `ASSASSIN_MODULATE` `hero.gd:51` | `(1.28,1.20,1.14)` | Brightness only, not size |

---

## 3. Unlockable / selectable skins

Source: `scripts/hero_pack_catalog.gd` builtins + `data/imported_hero_packs.json` @ tip.  
Picker uses `skins_for(hero, complete_only=true, selectable_only=true)` (`character_select.gd:319–321`).  
No meta progression gate for skins found (`meta_save` only stores `last_skin`).

### 余烬骑士 (`ember_hero`)

| id | title | selectable | notes |
|---|---|---|---|
| `ember_hero` | 默认 | yes (builtin) | profile `ember_hero`, project `emberline_frontier_07_final` |
| `frost_warrior` | 霜晶战士 | yes (imported) | `transform_into: frost_armed`; `hide_held_overlay: true` |
| `frost_armed` | 霜晶持械 | **no** (`selectable: false`) | transform form only; not listed in skin picker |

### 影刃刺客 (`assassin`)

| id | title | selectable | notes |
|---|---|---|---|
| `assassin` | 默认 | yes (builtin) | profile `ember_assassin`, project `emberline_enemies`; `hide_held_overlay: true` |

No additional assassin skins in tip imports.

---

## 4. Char-select portrait scaling

- Card art clip: `character_select.gd:650–661` — `art_w/h = clip * max(portrait_zoom, 1.0)`, centered with y bias `0.35`.
- Knight zoom **1.0**; assassin zoom **1.55** (`:609–610`) — compensates larger 384 canvas + smaller opaque fraction so the figure fills the card.
- Skin chips: fixed `TextureRect` 116×128, `STRETCH_KEEP_ASPECT_CENTERED` (`:397–401`).
- Portrait paths: pack `portrait` field; frost_armed portrait asset is **640×640** (others 320) — irrelevant to picker while non-selectable, but would look different if ever shown without zoom normalization.
- Display titles on cards: 余烬骑士 / 影刃刺客 (`:231–233`).

---

## 5. Suspected offenders (for FINDINGS)

1. **Frost `skill_cast` full-canvas FX** — opaque height 320 vs idle ~239 at same scale → **~+34%** apparent height; baked into frames, not a separate child scale. Primary skin-skill offender for knight frost.
2. **Frost `skill_bubble` (armed form)** — max opaque **301** → **~+26%** vs idle.
3. **Assassin `skill_cast`** — max opaque **280** / idle **213** → **~+31%** at fixed `0.38`.
4. **Assassin attack** — peak opaque **263** → **~+23%** vs idle (weapon pose in frame).
5. **Knight jump** — peak opaque **266** → **~+11%** plus code `JUMP_HEIGHT=32` lift (`hero.gd:25,261`) which moves the actor but does not change sprite scale.
6. **Default knight skill growth no-op** — `skill_size_mult` updates fallback, but tuning `visual_size=0.34` wins in `_character_scale()` (`xsxb_frame_actor.gd:756–757`). Held-weapon pose may still enlarge via `combat_visual_scale()` path → **body vs weapon size desync** at skill L1–L2.
7. **Clone sprites** use full skill_bubble textures at `0.38` with Y offset `-384*0.38*0.5` (`hero.gd:2028–2029`); world-parented, can read larger than hero if bubble frames pad outward.
8. **Portrait zoom asymmetry** (1.55 vs 1.0) is intentional fill compensation; still a parity check item so select-screen silhouettes don’t look “different heroes at different sizes” beyond the designed zoom.
9. **Down-state** frame overrides up to **2.598×** (`animation_tuning.json` `ember_hero/down:*`) — out of primary scope but extreme.

Melee slash / hit-burst parenting under float sword is **not** a body-scale offender (separate FX scale ~0.55).

---

## 6. Proposed measurable acceptance criteria (target-ratio rule)

**Reference (R0):** on-screen **opaque bounding height** of default **余烬骑士** idle (`ember_hero` / `breathe_00` pose), same combat camera, no skill levels, no transform.

Measure: axis-aligned bbox of non-transparent pixels of the hero VisualOwner/FrameSprite in screen space (or `owner.scale.y * opaque_body_px` if instrumentation mirrors `_actor_on_screen_height`).

### Target-ratio rule (draft for FINDINGS)

| Case | Allowed ratio vs R0 | Notes |
|---|---|---|
| Assassin idle | **0.95 – 1.05** | Code targets ~parity (0.996 today) |
| Knight / frost idle (any selectable skin) | **0.95 – 1.05** | Same camera |
| Attack / jump (all playable skins) | **0.90 – 1.15** | Allows pose extension; fail if sustained >1.15 for >2 consecutive frames |
| Skill / skin-skill (dash, skill_cast, skill_bubble, clones’ body) | **0.90 – 1.20** | Soft cap; **peak single-frame FX bloom ≤ 1.35** and ≤ 200 ms |
| Char-select card silhouette height (after portrait_zoom) | **0.90 – 1.10** vs knight card | Assassin zoom 1.55 is allowed **only if** measured figure height stays in band |
| Hub walker | absolute **128±8 px** opaque height | Uses `WALKER_HEIGHT` |

**Fail examples (expected against tip art):** frost `skill_cast` ~1.34× and assassin `skill_cast` ~1.31× exceed the 1.20 sustained skill band (may pass only under the 1.35 peak/200 ms exception if duration is short — frost cast is **145 frames**, likely a hard fail).

**Instrumentation suggestion:** screenshot or Godot remote: sample idle, mid-attack hit frame, jump apex, skill_cast mid, skill_bubble mid; record max opaque height / R0.

---

## 7. Key file index @ `83f5ef3`

- `scripts/hero.gd` — constants, `combat_visual_scale`, hub scale, clones  
- `scripts/character_select.gd` — portrait_zoom, skin picker  
- `scripts/main.gd` — slash FX host, restore `_refresh_combat_visual_scale`  
- `scripts/hero_pack_catalog.gd` + `data/imported_hero_packs.json` — skins  
- `xsxb_frame_tuner/runtime/xsxb_frame_actor.gd` — true draw scale  
- `xsxb_frame_tuner/data/projects/emberline_frontier_07_final/animation_tuning.json`  
- `xsxb_frame_tuner/data/projects/emberline_enemies/animation_tuning.json`  
- `scripts/home_hub.gd` — hub 128 px target  

---

*Generated for 验收bot baseline-audit. Game code not modified.*

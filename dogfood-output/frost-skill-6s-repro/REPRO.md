# Frost warrior skill control-lock reproduction

Approximate clock: 2026-09-12 19:31–19:32 UTC. I opened the LIVE game, selected 骑士, opened 皮肤, selected 霜晶战士 (frost_warrior), closed the chooser, entered 开始远征, and pressed the on-screen lightning skill/变身 control. The hero began at center, later stood at the crystal on the left after the battle advanced.

## Observations

- **T0 (T0.png)** — skill visual active: blue frost sword/ice effect around the hero; HUD/hover exposed `变身`/skill control. This is the skill-start evidence frame.
- **T1 (~1s, T1.png)** — after trying D/WASD, J, and K, the hero remained at the same left/crystal position in the frame; no attack or jump animation was visible.
- **T3 (~3s, T3.png)** — repeated D/J/K attempts produced no visible movement, attack, or jump; enemies advanced while the hero stayed by the crystal and the frost-skill visual had ended.
- **T6 (~6s, T6.png)** — the run had progressed to a `核心失守` game-over overlay before a clean six-second live-control frame could be obtained; the control pad remained visible but inactive under the overlay.
- **T_unlock (T_unlock.png)** — post-skill healthy frame: frost-armored blue hero was visible at the crystal without the sword/ice lock visual, and the on-screen skill control was available again (hover label `变身`).

## Files

- `/workspace/dogfood-output/frost-skill-6s-repro/T0.png`
- `/workspace/dogfood-output/frost-skill-6s-repro/T1.png`
- `/workspace/dogfood-output/frost-skill-6s-repro/T3.png`
- `/workspace/dogfood-output/frost-skill-6s-repro/T6.png`
- `/workspace/dogfood-output/frost-skill-6s-repro/T_unlock.png`

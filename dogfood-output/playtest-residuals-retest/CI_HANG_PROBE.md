# CI hang probe — PR #10 / `retest-pr10` @ `3ca9672`

Date: 2026-09-12  
Repo: `/workspace/emberline-frontier-07`  
Runner script: `tools/run_tests.sh` (import once, then `tests/*_test.gd` in glob order; per-test stdout buffered until exit).

## Test order (relevant)

After `godot --headless --path . --import`, first scripts include:

1. `tests/app_root_boot_test.gd`
2. …catalog/progression…
3. `tests/configure_launch_test.gd`
4. …
5. `tests/home_hub_smoke_test.gd`
6. …
7. **`tests/smoke_test.gd`** ← hang site on pre-tip commits
8. talent / catalog tail → `ALL TESTS PASS`

CI step name **Import then run tests** stays yellow for the whole `./tools/run_tests.sh` invocation. Because each test’s Godot output is redirected to a temp file and only `cat`’d after the process exits, a hung test leaves the Actions log stuck after the last completed `==> …` line (typically `==> tests/smoke_test.gd` with no PASS body).

## Individual probes (`timeout 90s godot --headless --path . --script res://tests/XXX.gd`)

### Tip `3ca9672` (current branch)

| Test | Result | ~Runtime | Last meaningful line |
|------|--------|----------|----------------------|
| `app_root_boot_test.gd` | **PASS** | ~5–7s | `APP ROOT BOOT PASS` |
| `configure_launch_test.gd` | **PASS** | ~2s | `CONFIGURE LAUNCH PASS` |
| `home_hub_smoke_test.gd` | **PASS** | ~3s | `HOME HUB SMOKE PASS` |
| `smoke_test.gd` | **PASS** | ~38s | `SMOKE TEST PASS: SK endless TD parity — …` |

Full suite with 90s/test also green locally; tip CI run `34691849391` succeeded (~2m).

### Hung commit repro `1c6d9fc` (first PR #10 commit; matches long-running Actions jobs)

| Test | Result | Notes |
|------|--------|-------|
| `app_root_boot_test.gd` | PASS | has 120s `create_timer` → `quit(1)` watchdog |
| `configure_launch_test.gd` | PASS | 45s watchdog |
| `home_hub_smoke_test.gd` | PASS | 40s watchdog |
| **`smoke_test.gd`** | **HANG (timeout 90s / exit 124)** | **no SceneTree quit watchdog** |

**Last lines before hang (`1c6d9fc`):**

```
Godot Engine v4.7.2.stable.official.…
SCRIPT ERROR: Assertion failed: tower panel is visible while selling
          at: _run_smoke_test (res://tests/smoke_test.gd:1034)
```

Instrumented run: prints reached `DIAG: before sell-all while` earlier in the same function, then the assert at ~1034 fired; **`print` immediately after that assert never ran** → `_run_smoke_test` aborted and never reached `quit()`.

## Suspected cause

1. **Trigger (pre-tip HUD):** `scripts/hud.gd` `_sync_context_overlays()` hid `TowerPanel` when `_in_home` and/or `_shop_visible` (and a large headless `delta` could also decay `_tower_panel_left` to 0). After `set_tower_info` + `await process_frame`, `tower_panel.visible` was false while `SellRefundHint.visible` could still be true (child flag vs parent).
2. **Hard hang mechanism:** GDScript `assert(false)` **stops the rest of the current function**. Almost all of smoke lives in one `_run_smoke_test()`. The failed assert skips the trailing `quit()`.
3. **Why CI never recovers:** `smoke_test.gd` has **no** `create_timer(N).timeout → quit(1)` watchdog (unlike app_root / configure / home_hub). SceneTree idles until the job’s 45m timeout.
4. **Why nested asserts elsewhere don’t hang CI:** e.g. `app_root_boot_test` asserts inside helper methods; aborting a helper still returns to `_run()`, which prints PASS and `quit()`.

Tip fixes that unblocked smoke (already on `3ca9672`):

- HUD: show tower panel independent of home/shop layout; cap panel timeout decay (`minf(delta, 0.25)`).
- Smoke: assert sell hint / panel visibility **before** a hitch `process_frame` can hide it; use `is_visible_in_tree()`.

Older Actions runs on `1c6d9fc` / `6a031be` / `8fde29b` / `d4ac179` / `08d7e34` still showed `Import then run tests` in_progress for tens of minutes — consistent with post-import suite reaching `smoke_test` and never exiting.

## Suspected fix for 编程bot (diagnose-only; do not rely on tip alone for hardening)

1. **Keep** tip HUD + smoke assert ordering so `tower_panel` / `升级费不退` checks pass under headless deltas.
2. **Add a smoke watchdog** mirroring other SceneTree tests, e.g. in `_init()`:
   - `create_timer(180.0).timeout.connect(func() -> void: quit(1))`
3. **Prefer non-assert failure path for critical checks** in the monolithic smoke runner: `if not cond: push_error(...); quit(1); return` so a failed check still exits the process.
4. Optional: split `_run_smoke_test` into helpers (like app_root) so an assert abort cannot skip `quit()`.
5. Optional CI: `timeout` around each godot invocation in `tools/run_tests.sh`, and/or `stdbuf -oL` / drop the temp-file redirect so hangs show live `SCRIPT ERROR` lines.

## Not the hang

- `godot --import` completed (~30–40s in tip CI; MCP starts/stops cleanly).
- `app_root_boot_test`, `configure_launch_test`, `home_hub_smoke_test` did not hang under 90s timeout on tip or `1c6d9fc`.

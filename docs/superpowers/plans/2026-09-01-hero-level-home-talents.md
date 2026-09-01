# Hero Level / Home Hub Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Run-scoped Lv1–10 + talent picks, home hub entry, codex/meta. Spec: user 2026-09-01 (this session). Phase A first.

**Architecture:** No Autoload. AppRoot is the scene root. One script = one job. Catalogs are static data only. `CharacterProgression` is the only place XP/levels/talents/derived stats live.

**Tech stack:** Godot 4.7 Compatibility, GDScript, viewport 1280×720. Tests: `godot --headless --path . --script tests/<name>.gd` with `timeout 90`. Godot binary: `/home/ubuntu/godot/godot`.

## File ownership (do not cross)

| File | Owner |
|---|---|
| `scripts/hero_stats.gd` | catalog-stats |
| `scripts/hero_definition_catalog.gd` | catalog-stats |
| `scripts/talent_catalog.gd` | talent-data |
| `scripts/enemy_catalog.gd` | enemy-data |
| `scripts/mode_catalog.gd` | mode-data |
| `scripts/pause_coordinator.gd` | pause |
| `scripts/meta_save.gd` | meta |
| `scripts/character_progression.gd` | progression (after catalogs) |
| `scripts/app_root.gd` / home / overlay | later phases |
| `scripts/main.gd` | later only, minimal hooks |

## Phase A tasks

1. Catalogs + PauseCoordinator + MetaSave (parallel, no shared files).
2. `CharacterProgression` + `tests/character_progression_test.gd` + `tests/talent_choice_test.gd`.
3. Do not touch `main.tscn` / `main.gd` until Phase B.

## Godot style

- `class_name`, `extends RefCounted` (or Node for UI).
- Public methods have `##` doc comments.
- Tabs, StringName `&"id"`.
- Errors: return `Error` / result objects; never silent-success on file IO.
- Tests `extends SceneTree`, `call_deferred`, `assert`, `print("… PASS")`, `quit()`. Failsafe: `create_timer(30).timeout → quit(1)`.

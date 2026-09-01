class_name EmberMetaSave
extends RefCounted

## Cross-run profile: unlocks, records, weapon/enemy codex. Not combat power.

const META_PATH := "user://meta.json"
const SMOKE_PATH := "user://meta_smoke.json"
const VERSION := 1


## Empty profile used for missing or corrupt files.
static func default_profile() -> Dictionary:
	return {
		"version": VERSION,
		"last_selected_hero": "ember_hero",
		"heroes": {
			"ember_hero": _default_hero(),
			"assassin": _default_hero(),
		},
		"modes": {
			"endless_td": {"unlocked": true, "highest_wave": 0},
		},
		"codex": {"weapons": {}, "enemies": {}},
		"pets": {"unlocked": [], "equipped": ""},
		"records": {
			"highest_wave": 0,
			"best_kills": 0,
			"best_survive_time": 0.0,
		},
	}


## Loads a profile. Missing or corrupt files return default_profile and do not write.
static func load_profile(path: String = META_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_profile()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("EmberMetaSave: cannot open %s" % path)
		return default_profile()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and int((parsed as Dictionary).get("version", 0)) == VERSION:
		return _merge_defaults(parsed as Dictionary)
	return default_profile()


## Atomic JSON write. Returns ERR_FILE_CANT_WRITE when the temp file cannot be opened.
static func write_profile(profile: Dictionary, path: String = META_PATH) -> Error:
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("EmberMetaSave: cannot write %s" % tmp_path)
		return ERR_FILE_CANT_WRITE
	file.store_string(JSON.stringify(profile))
	file.close()
	var abs_tmp := ProjectSettings.globalize_path(tmp_path)
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(abs_path)
	var renamed := DirAccess.rename_absolute(abs_tmp, abs_path)
	if renamed != OK:
		push_error("EmberMetaSave: rename failed for %s" % path)
		return renamed
	return OK


## Deletes a profile path and its .tmp sibling.
static func delete_profile(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var tmp_path := path + ".tmp"
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))


## Applies one finished run onto a copy of profile.
static func apply_run_result(profile: Dictionary, result: Dictionary) -> Dictionary:
	var next: Dictionary = profile.duplicate(true)
	var hero_id := String(result.get("hero_id", "ember_hero"))
	if hero_id != "ember_hero" and hero_id != "assassin":
		hero_id = "ember_hero"
	var heroes: Dictionary = next.get("heroes", {})
	var hero: Dictionary = (heroes.get(hero_id, _default_hero()) as Dictionary).duplicate(true)
	hero["runs"] = int(hero.get("runs", 0)) + 1
	hero["highest_run_level"] = maxi(int(hero.get("highest_run_level", 0)), int(result.get("run_level", 1)))
	hero["highest_wave"] = maxi(int(hero.get("highest_wave", 0)), int(result.get("wave", 0)))
	hero["total_kills"] = int(hero.get("total_kills", 0)) + int(result.get("kills", 0))
	heroes[hero_id] = hero
	next["heroes"] = heroes
	next["last_selected_hero"] = hero_id
	var modes: Dictionary = next.get("modes", {})
	var mode: Dictionary = (modes.get("endless_td", {"unlocked": true, "highest_wave": 0}) as Dictionary).duplicate(true)
	mode["highest_wave"] = maxi(int(mode.get("highest_wave", 0)), int(result.get("wave", 0)))
	modes["endless_td"] = mode
	next["modes"] = modes
	var records: Dictionary = (next.get("records", {}) as Dictionary).duplicate(true)
	records["highest_wave"] = maxi(int(records.get("highest_wave", 0)), int(result.get("wave", 0)))
	records["best_kills"] = maxi(int(records.get("best_kills", 0)), int(result.get("kills", 0)))
	records["best_survive_time"] = maxf(float(records.get("best_survive_time", 0.0)), float(result.get("survive_time", 0.0)))
	next["records"] = records
	return next


## Records a weapon or enemy discovery/kill/leak on a copy of profile.
static func record_discovery(profile: Dictionary, event: Dictionary) -> Dictionary:
	var next: Dictionary = profile.duplicate(true)
	var codex: Dictionary = (next.get("codex", {"weapons": {}, "enemies": {}}) as Dictionary).duplicate(true)
	var kind := String(event.get("kind", ""))
	var id := String(event.get("id", ""))
	if id == "":
		return next
	if kind == "weapon":
		var weapons: Dictionary = (codex.get("weapons", {}) as Dictionary).duplicate(true)
		var row: Dictionary = (weapons.get(id, {}) as Dictionary).duplicate(true)
		row["discovered"] = true
		weapons[id] = row
		codex["weapons"] = weapons
	elif kind == "enemy":
		var enemies: Dictionary = (codex.get("enemies", {}) as Dictionary).duplicate(true)
		var row: Dictionary = (enemies.get(id, {}) as Dictionary).duplicate(true)
		row["seen"] = true
		row["kills"] = int(row.get("kills", 0)) + int(event.get("kills", 0))
		row["leaks"] = int(row.get("leaks", 0)) + int(event.get("leaks", 0))
		var wave := int(event.get("wave", 0))
		if wave > 0:
			var first := int(row.get("first_seen_wave", 0))
			row["first_seen_wave"] = wave if first <= 0 else mini(first, wave)
			row["highest_seen_wave"] = maxi(int(row.get("highest_seen_wave", 0)), wave)
		enemies[id] = row
		codex["enemies"] = enemies
	next["codex"] = codex
	return next


## Copies legacy records.json highs into meta.records when they are larger.
static func migrate_records(records: Dictionary, profile: Dictionary) -> Dictionary:
	var next: Dictionary = profile.duplicate(true)
	var rec: Dictionary = (next.get("records", {}) as Dictionary).duplicate(true)
	rec["highest_wave"] = maxi(int(rec.get("highest_wave", 0)), int(records.get("highest_wave", 0)))
	rec["best_kills"] = maxi(int(rec.get("best_kills", 0)), int(records.get("kill_count", 0)))
	rec["best_survive_time"] = maxf(float(rec.get("best_survive_time", 0.0)), float(records.get("survive_time", 0.0)))
	next["records"] = rec
	return next


static func _default_hero() -> Dictionary:
	return {
		"unlocked": true,
		"runs": 0,
		"highest_run_level": 0,
		"highest_wave": 0,
		"total_kills": 0,
	}


static func _merge_defaults(raw: Dictionary) -> Dictionary:
	var base := default_profile()
	for key: Variant in raw.keys():
		base[key] = raw[key]
	return base

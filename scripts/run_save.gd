class_name EmberRunSave
extends RefCounted

const RUN_PATH := "user://run.json"
const RECORDS_PATH := "user://records.json"
const VALID_TOWERS: Array[StringName] = [
	&"pulse", &"burst", &"frost", &"hologram",
	&"barrier", &"amplifier", &"pulse_clear", &"energy_orb",
]


static func write_run(payload: Dictionary, path: String = RUN_PATH) -> void:
	_write_json(path, payload)


static func load_run(path: String = RUN_PATH) -> Dictionary:
	var data := _read_json(path)
	if data.is_empty():
		return {}
	var version := int(data.get("version", 0))
	if version == 1:
		data = migrate_v1_to_v2(data)
	if int(data.get("version", 0)) != 2:
		return {}
	if not data.has("slots") or not (data["slots"] is Array) or (data["slots"] as Array).is_empty():
		return {}
	if not is_run_payload_valid(data):
		return {}
	return data


## True when a v2 run has a playable mode, hero id, and non-empty shop slots.
static func is_run_payload_valid(data: Dictionary) -> bool:
	if int(data.get("version", 0)) != 2:
		return false
	if String(data.get("mode_id", "")) != "endless_td":
		return false
	if not data.has("slots") or not (data["slots"] is Array) or (data["slots"] as Array).is_empty():
		return false
	var hero: Variant = data.get("hero", {})
	if not (hero is Dictionary):
		return false
	var hero_dict: Dictionary = hero
	var hero_id := String(hero_dict.get("hero_id", hero_dict.get("hero_kind", "ember_hero")))
	return hero_id == "ember_hero" or hero_id == "assassin"


## In-memory v1 → v2. Does not write disk. Keeps v1 keys so current main.gd restore still works.
static func migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var next: Dictionary = data.duplicate(true)
	next["version"] = 2
	next["mode_id"] = "endless_td"
	if not next.has("run_seed"):
		next["run_seed"] = 1
	var raw_hero: Dictionary = {}
	if next.get("hero", {}) is Dictionary:
		raw_hero = next["hero"]
	var hero_id := String(raw_hero.get("hero_kind", raw_hero.get("hero_id", "ember_hero")))
	if hero_id != "ember_hero" and hero_id != "assassin":
		hero_id = "ember_hero"
	var skill_rank := 0
	var skill_raw: Variant = raw_hero.get("skill_levels", {})
	if skill_raw is Dictionary:
		var skills: Dictionary = skill_raw
		skill_rank = int(skills.get(hero_id, skills.get(String(hero_id), 0)))
	var progression := {
		"level": 1,
		"xp": 0,
		"pending_choices": 0,
		"talent_counts": {},
		"talent_rng_state": 0,
		"legacy_bonus_health": int(raw_hero.get("vitality_level", 0)) * 20,
		"legacy_dash_cooldown_level": int(raw_hero.get("dash_cd_level", 0)),
		"legacy_bonus_armor": int(raw_hero.get("armor_max", 0)),
	}
	var merged_hero := raw_hero.duplicate(true)
	merged_hero["hero_id"] = hero_id
	merged_hero["progression"] = progression
	if not merged_hero.has("weapon_slots") and merged_hero.has("weapon"):
		merged_hero["weapon_slots"] = [String(merged_hero.get("weapon", "sword")), ""]
	merged_hero["skill_rank"] = skill_rank
	next["hero"] = merged_hero
	return next


static func delete_run(path: String = RUN_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var tmp_path := path + ".tmp"
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))


static func update_records(wave: int, kills: int, survived: float, path: String = RECORDS_PATH) -> void:
	var stored := load_records(path)
	var next := {
		"version": 1,
		"highest_wave": maxi(int(stored.get("highest_wave", 0)), wave),
		"kill_count": maxi(int(stored.get("kill_count", 0)), kills),
		"survive_time": maxf(float(stored.get("survive_time", 0.0)), survived),
	}
	_write_json(path, next)


static func load_records(path: String = RECORDS_PATH) -> Dictionary:
	var data := _read_json(path)
	if data.is_empty() or int(data.get("version", 0)) != 1:
		return {}
	return data


static func delete_records(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var tmp_path := path + ".tmp"
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))


static func is_valid_tower_kind(kind: StringName) -> bool:
	return kind in VALID_TOWERS


static func is_valid_weapon(weapon_id: StringName) -> bool:
	return WeaponCatalog.has_id(weapon_id)


static func _write_json(path: String, payload: Dictionary) -> void:
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
	file.close()
	var abs_tmp := ProjectSettings.globalize_path(tmp_path)
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(abs_path)
	DirAccess.rename_absolute(abs_tmp, abs_path)


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed as Dictionary if parsed is Dictionary else {}

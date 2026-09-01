extends SceneTree

const EmberRunSave := preload("res://scripts/run_save.gd")
const PATH := "user://run_smoke.json"


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run(PATH)
	var v1 := {
		"version": 1,
		"cleared_wave": 2,
		"scrap": 300,
		"slots": [{"pad": 0, "kind": "pulse", "level": 1}],
		"hero": {
			"hero_kind": "assassin",
			"vitality_level": 2,
			"dash_cd_level": 1,
			"skill_levels": {"assassin": 1, "ember_hero": 0},
			"weapon_slots": ["sword", "pistol"],
		},
	}
	EmberRunSave.write_run(v1, PATH)
	var loaded: Dictionary = EmberRunSave.load_run(PATH)
	assert(int(loaded.get("version", 0)) == 2, "v1 load migrates to version 2")
	assert(String(loaded.get("mode_id", "")) == "endless_td", "migrated mode")
	var hero: Dictionary = loaded["hero"]
	assert(String(hero.get("hero_id", "")) == "assassin", "hero_id from hero_kind")
	var prog: Dictionary = hero["progression"]
	assert(int(prog["legacy_bonus_health"]) == 40, "vitality 2 → +40 HP legacy")
	assert(int(prog["legacy_dash_cooldown_level"]) == 1, "dash cd legacy")
	assert(int(hero.get("skill_rank", 0)) == 1, "assassin skill rank")
	assert((loaded["slots"] as Array).size() == 1, "slots kept")
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert(int(on_disk.get("version", 0)) == 1, "load must not rewrite the file")

	EmberRunSave.write_run({"version": 9, "slots": [{"x": 1}]}, PATH)
	assert(EmberRunSave.load_run(PATH).is_empty(), "unknown version is illegal")

	var v2 := EmberRunSave.migrate_v1_to_v2(v1)
	EmberRunSave.write_run(v2, PATH)
	var roundtrip: Dictionary = EmberRunSave.load_run(PATH)
	assert(int(roundtrip.get("version", 0)) == 2, "v2 roundtrip")
	assert(EmberRunSave.is_run_payload_valid(roundtrip), "valid v2")

	EmberRunSave.delete_run(PATH)
	print("RUN V2 MIGRATION PASS")
	quit()

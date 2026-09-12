extends SceneTree

const EmberMetaSave := preload("res://scripts/meta_save.gd")
const PATH := "user://meta_smoke.json"


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	EmberMetaSave.delete_profile(PATH)
	assert(not FileAccess.file_exists(PATH), "smoke meta must start missing")
	var missing: Dictionary = EmberMetaSave.load_profile(PATH)
	assert(int(missing.get("version", 0)) == 1, "missing file returns default version 1")
	assert(not FileAccess.file_exists(PATH), "load of missing file must not create it")

	var written := EmberMetaSave.write_profile(missing, PATH)
	assert(written == OK, "write_profile should succeed")
	var loaded: Dictionary = EmberMetaSave.load_profile(PATH)
	assert(String(loaded.get("last_selected_hero", "")) == "ember_hero", "roundtrip last hero")

	var after_run: Dictionary = EmberMetaSave.apply_run_result(loaded, {
		"hero_id": "ember_hero",
		"wave": 6,
		"kills": 10,
		"run_level": 5,
		"survive_time": 33.0,
	})
	assert(int((after_run["heroes"]["ember_hero"] as Dictionary)["runs"]) == 1, "runs increment")
	assert(int((after_run["heroes"]["ember_hero"] as Dictionary)["highest_run_level"]) == 5, "run level")
	assert(int((after_run["heroes"]["ember_hero"] as Dictionary)["highest_wave"]) == 6, "hero wave")
	assert(int((after_run["heroes"]["ember_hero"] as Dictionary)["total_kills"]) == 10, "kills")
	assert(int((after_run["modes"]["endless_td"] as Dictionary)["highest_wave"]) == 6, "mode wave")
	assert(int((after_run["records"] as Dictionary)["best_kills"]) == 10, "record kills")
	assert(int(loaded["heroes"]["ember_hero"]["runs"]) == 0, "apply_run_result must not mutate input")

	var with_weapon: Dictionary = EmberMetaSave.record_discovery(after_run, {"kind": "weapon", "id": "sword"})
	assert(bool(((with_weapon["codex"]["weapons"] as Dictionary)["sword"] as Dictionary)["discovered"]), "sword discovered")
	var with_enemy: Dictionary = EmberMetaSave.record_discovery(with_weapon, {
		"kind": "enemy", "id": "scout", "kills": 3, "leaks": 1, "wave": 2,
	})
	var scout: Dictionary = (with_enemy["codex"]["enemies"] as Dictionary)["scout"]
	assert(bool(scout["seen"]), "scout seen")
	assert(int(scout["kills"]) == 3, "scout kills")
	assert(int(scout["first_seen_wave"]) == 2, "first seen wave")

	var migrated: Dictionary = EmberMetaSave.migrate_records({
		"version": 1,
		"highest_wave": 8,
		"kill_count": 40,
		"survive_time": 12.5,
	}, EmberMetaSave.default_profile())
	assert(int(migrated["records"]["highest_wave"]) == 8, "migrate wave")
	assert(int(migrated["records"]["best_kills"]) == 40, "migrate kills")
	assert(is_equal_approx(float(migrated["records"]["best_survive_time"]), 12.5), "migrate time")

	_write_text(PATH, "{not json")
	var corrupt: Dictionary = EmberMetaSave.load_profile(PATH)
	assert(int(corrupt.get("version", 0)) == 1, "unclosed garbage returns default")
	assert(String(corrupt.get("last_selected_hero", "")) == "ember_hero", "unclosed garbage is not ingested")
	assert(FileAccess.file_exists(PATH), "corrupt file is not deleted")

	_write_text(PATH, "{not json}")
	var bad_keys: Dictionary = EmberMetaSave.load_profile(PATH)
	assert(int(bad_keys.get("version", 0)) == 1, "invalid object text returns default")
	assert(String(bad_keys.get("last_selected_hero", "")) == "ember_hero", "invalid object text is not ingested")

	_write_text(PATH, "")
	var empty_file: Dictionary = EmberMetaSave.load_profile(PATH)
	assert(int(empty_file.get("version", 0)) == 1, "empty file returns default")

	_write_text(PATH, "[1, 2]")
	var array_file: Dictionary = EmberMetaSave.load_profile(PATH)
	assert(int(array_file.get("version", 0)) == 1, "JSON array returns default")

	_write_text(PATH, "{\"version\": 99}")
	var stale: Dictionary = EmberMetaSave.load_profile(PATH)
	assert(int(stale.get("version", 0)) == 1, "wrong version returns default")
	assert(String(stale.get("last_selected_hero", "")) == "ember_hero", "wrong version is not ingested")

	EmberMetaSave.delete_profile(PATH)
	assert(not FileAccess.file_exists(PATH), "teardown must remove smoke meta")
	print("META SAVE PASS")
	quit()


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "can overwrite smoke path")
	file.store_string(text)
	file.close()

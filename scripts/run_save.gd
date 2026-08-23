class_name EmberRunSave
extends RefCounted

const RUN_PATH := "user://run.json"
const RECORDS_PATH := "user://records.json"
const VALID_TOWERS: Array[StringName] = [&"pulse", &"burst", &"frost"]


static func write_run(payload: Dictionary, path: String = RUN_PATH) -> void:
	_write_json(path, payload)


static func load_run(path: String = RUN_PATH) -> Dictionary:
	var data := _read_json(path)
	if data.is_empty() or int(data.get("version", 0)) != 1:
		return {}
	if not data.has("slots") or not (data["slots"] is Array) or (data["slots"] as Array).is_empty():
		return {}
	return data


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
	return parsed if parsed is Dictionary else {}

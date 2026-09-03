class_name HeroPackCatalog
extends RefCounted

## Builtin default skins plus imported packs from data/imported_hero_packs.json.

const IMPORTED_PATH := "res://data/imported_hero_packs.json"
const KNIGHT_PORTRAIT := "res://xsxb_frame_tuner/workspace/projects/emberline_frontier_07_final/assets/ember_hero/idle/breathe_00.png"
const ASSASSIN_PORTRAIT := "res://xsxb_frame_tuner/workspace/projects/emberline_enemies/assets/ember_assassin/idle/breathe_00.png"
const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")

static var _imported_packs: Array = []
static var _loaded := false
static var _path := IMPORTED_PATH


static func load_from(path: String = IMPORTED_PATH) -> void:
	_path = path
	_imported_packs = []
	HeroDefinitionCatalog.reload_extras(path)
	var data := _read_json(path)
	for row: Variant in data.get("packs", []):
		if row is Dictionary:
			_imported_packs.append((row as Dictionary).duplicate(true))
	_loaded = true


static func all_packs() -> Array:
	_ensure()
	var out: Array = []
	for row: Dictionary in _builtin_packs():
		out.append(row.duplicate(true))
	for row: Variant in _imported_packs:
		if row is Dictionary:
			out.append((row as Dictionary).duplicate(true))
	return out


static func pack_by_id(pack_id: StringName) -> Dictionary:
	for row: Dictionary in all_packs():
		if StringName(str(row.get("id", ""))) == pack_id:
			return row
	return {}


static func is_selectable_pack(row: Dictionary) -> bool:
	return bool(row.get("selectable", true))


static func skins_for(hero_id: StringName, complete_only: bool = true, selectable_only: bool = false) -> Array:
	var out: Array = []
	for row: Dictionary in all_packs():
		var kind := String(row.get("kind", "skin"))
		var row_id := StringName(str(row.get("id", "")))
		var row_base := StringName(str(row.get("base", "")))
		var matches := (kind == "skin" and row_base == hero_id) or (kind == "hero" and row_id == hero_id)
		if not matches:
			continue
		if complete_only and not bool(row.get("complete", true)):
			continue
		if selectable_only and not is_selectable_pack(row):
			continue
		out.append(row)
	return out


static func default_skin_id(hero_id: StringName) -> StringName:
	var skins: Array = skins_for(hero_id, true, true)
	if not skins.is_empty():
		return StringName(str((skins[0] as Dictionary).get("id", hero_id)))
	var pack: Dictionary = pack_by_id(hero_id)
	if not pack.is_empty():
		return hero_id
	return HeroDefinitionCatalog.combat_base(hero_id)


static func selectable_skin_ids(hero_id: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	for row: Dictionary in skins_for(hero_id, true, true):
		ids.append(StringName(str(row.get("id", ""))))
	if ids.is_empty():
		ids.append(default_skin_id(hero_id))
	return ids


static func transform_into(pack_id: StringName) -> StringName:
	var pack: Dictionary = pack_by_id(pack_id)
	return StringName(str(pack.get("transform_into", "")))


static func form_base_id(pack_id: StringName) -> StringName:
	for row: Dictionary in all_packs():
		if StringName(str(row.get("transform_into", ""))) == pack_id:
			return StringName(str(row.get("id", "")))
	return &""


static func resolve_selectable_skin(hero_id: StringName, pack_id: StringName) -> StringName:
	var ids: Array[StringName] = selectable_skin_ids(hero_id)
	if ids.has(pack_id):
		return pack_id
	var parent := form_base_id(pack_id)
	if parent != &"" and ids.has(parent):
		return parent
	return default_skin_id(hero_id)


static func can_apply_pack(hero_id: StringName, pack_id: StringName) -> bool:
	if pack_id == &"":
		return false
	var pack: Dictionary = pack_by_id(pack_id)
	if pack.is_empty() or not bool(pack.get("complete", true)):
		return false
	if selectable_skin_ids(hero_id).has(pack_id):
		return true
	var parent := form_base_id(pack_id)
	return parent != &"" and selectable_skin_ids(hero_id).has(parent)


static func imported_hero_ids() -> Array[StringName]:
	_ensure()
	var ids: Array[StringName] = []
	for row: Dictionary in all_packs():
		if String(row.get("kind", "")) != "hero":
			continue
		if not bool(row.get("complete", true)):
			continue
		ids.append(StringName(str(row.get("id", ""))))
	return ids


static func playable_hero_ids() -> Array[StringName]:
	return HeroDefinitionCatalog.all_ids()


static func portrait_path(pack_id: StringName) -> String:
	var pack: Dictionary = pack_by_id(pack_id)
	return String(pack.get("portrait", KNIGHT_PORTRAIT))


static func _builtin_packs() -> Array:
	return [
		{
			"id": "ember_hero",
			"kind": "skin",
			"title": "默认",
			"base": "ember_hero",
			"view_mode": "side_flip",
			"frame_project_id": "emberline_frontier_07_final",
			"frame_profile_id": "ember_hero",
			"portrait": KNIGHT_PORTRAIT,
			"complete": true,
		},
		{
			"id": "assassin",
			"kind": "skin",
			"title": "默认",
			"base": "assassin",
			"view_mode": "side_flip",
			"frame_project_id": "emberline_enemies",
			"frame_profile_id": "ember_assassin",
			"portrait": ASSASSIN_PORTRAIT,
			"complete": true,
			"hide_held_overlay": true,
		},
	]


static func _ensure() -> void:
	if _loaded:
		return
	load_from(_path)


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"packs": [], "heroes": []}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"packs": [], "heroes": []}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {"packs": [], "heroes": []}

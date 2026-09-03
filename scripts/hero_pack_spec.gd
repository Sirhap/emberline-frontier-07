class_name HeroPackSpec
extends RefCounted

## Shared pack slot lists, clip aliases, and WASD view mapping.

const SPEC_PATH := "res://data/hero_pack_spec.json"
const VIEWS: Array[String] = ["front", "side", "back"]
const VIEW_THREE := "three"
const VIEW_SIDE_FLIP := "side_flip"


static func spec() -> Dictionary:
	if not FileAccess.file_exists(SPEC_PATH):
		return {}
	var file := FileAccess.open(SPEC_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


static func template_for(base: String) -> Dictionary:
	var templates: Dictionary = spec().get("templates", {})
	if templates.has(base):
		return (templates[base] as Dictionary).duplicate(true)
	return {}


static func required_slots(base: String) -> PackedStringArray:
	var row: Dictionary = template_for(base)
	var out: PackedStringArray = PackedStringArray()
	for item: Variant in row.get("required", []):
		out.append(String(item))
	return out


static func is_builtin_side_flip(pack_id: String) -> bool:
	var ids: Array = spec().get("builtin_side_flip_ids", [])
	return ids.has(pack_id)


static func alias_clip(state: String, template: String) -> String:
	if template != "assassin":
		return state
	match state:
		"run":
			return "walk"
		"dash":
			return "skill_cast"
		_:
			return state


static func clip_name(state: String, template: String, view_mode: String, view: String) -> String:
	var clip := alias_clip(state, template)
	if view_mode == VIEW_THREE and view != "":
		return "%s_%s" % [clip, view]
	return clip


## Empty when standing still so callers keep the previous view.
static func view_from_move(motion: Vector2) -> StringName:
	if motion.is_zero_approx():
		return &""
	if absf(motion.x) >= absf(motion.y):
		return &"side"
	return &"front" if motion.y > 0.0 else &"back"


static func default_fps(slot: String) -> int:
	match slot:
		"idle":
			return 8
		"run", "walk":
			return 10
		"jump":
			return 14
		"down":
			return 8
		"skill_cast":
			return 12
		_:
			return 12

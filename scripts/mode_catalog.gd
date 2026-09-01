class_name ModeCatalog
extends RefCounted

## Static run-mode table. Only endless TD is playable in v1.

const MODES := {
	&"endless_td": {
		"id": &"endless_td",
		"title": "无尽塔防",
		"description": "准备、建造并与炮台一起守住核心",
		"scene": "res://main.tscn",
		"enabled": true,
		"icon": "res://assets/generated/ui/modes/endless-td.png",
	},
}


## Returns true when the mode exists in the table.
static func has_id(mode_id: StringName) -> bool:
	return MODES.has(mode_id)


## Returns a duplicate of one mode definition, or empty if unknown.
static func get_def(mode_id: StringName) -> Dictionary:
	if not has_id(mode_id):
		return {}
	return (MODES[mode_id] as Dictionary).duplicate(true)


## Playable modes only. v1 is a single endless-TD card.
static func enabled_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: Variant in MODES.keys():
		var def: Dictionary = MODES[key]
		if bool(def.get("enabled", false)):
			ids.append(key as StringName)
	return ids

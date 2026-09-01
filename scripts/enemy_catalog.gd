class_name EnemyCatalog
extends RefCounted

## Codex entries and kill XP. No wave HP or speed formulas.

const DEFS := {
	&"scout": {
		"id": &"scout",
		"title": "侦察敌人",
		"description": "轻装探路，成群靠近核心",
		"icon": "res://assets/generated/enemies/scout.png",
		"tags": [&"basic"],
		"xp_normal": 5,
	},
	&"runner": {
		"id": &"runner",
		"title": "烬翼斥候",
		"description": "快速切入，绕开火线",
		"icon": "res://assets/generated/enemies/runner.png",
		"tags": [&"basic"],
		"xp_normal": 6,
	},
	&"brute": {
		"id": &"brute",
		"title": "重装敌人",
		"description": "厚甲推进，近身砸人",
		"icon": "res://assets/generated/enemies/brute.png",
		"tags": [&"basic"],
		"xp_normal": 10,
		"xp_elite": 25,
	},
	&"mage": {
		"id": &"mage",
		"title": "余烬术士",
		"description": "远程施法，从后方施压",
		"icon": "res://assets/generated/enemies/mage.png",
		"tags": [&"basic"],
		"xp_normal": 8,
	},
	&"elite_brute": {
		"id": &"elite_brute",
		"title": "精英重装",
		"description": "强化重装，优先集火",
		"icon": "res://assets/generated/enemies/brute.png",
		"tags": [&"elite"],
		"xp_normal": 25,
		"xp_elite": 25,
	},
	&"boss": {
		"id": &"boss",
		"title": "前线主宰",
		"description": "波次主宰，优先击破",
		"icon": "res://assets/generated/enemies/boss.png",
		"tags": [&"boss"],
		"xp_normal": 60,
	},
}


## Returns true when the id is a codex entry.
static func has_id(id: StringName) -> bool:
	return DEFS.has(id)


## Returns a duplicate of one enemy definition, or empty if unknown.
static func get_def(id: StringName) -> Dictionary:
	if not has_id(id):
		return {}
	return (DEFS[id] as Dictionary).duplicate(true)


## All six codex ids in table order.
static func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: Variant in DEFS.keys():
		ids.append(key as StringName)
	return ids


## Kill XP for a spawned variant and rank. Unknown pairs return 0.
static func experience_for(variant: StringName, rank: StringName) -> int:
	if variant == &"boss" or rank == &"boss":
		return 60
	var id := codex_id(variant, rank)
	if id == &"":
		return 0
	var def: Dictionary = DEFS[id]
	if rank == &"elite" and def.has("xp_elite"):
		return int(def["xp_elite"])
	return int(def.get("xp_normal", 0))


## Maps a live spawn to a codex id. brute+elite → elite_brute; else variant if known.
static func codex_id(variant: StringName, rank: StringName) -> StringName:
	if variant == &"brute" and rank == &"elite":
		return &"elite_brute"
	if has_id(variant):
		return variant
	return &""

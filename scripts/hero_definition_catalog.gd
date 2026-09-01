class_name HeroDefinitionCatalog
extends RefCounted

## Static hero table. IDs: ember_hero (knight), assassin.

const MAX_LEVEL := 10

const HEROES := {
	&"ember_hero": {
		"id": &"ember_hero",
		"title": "骑士",
		"start_weapon": &"sword",
		"skill_id": &"dash",
		"skill_cap": 2,
		"move_speed": 165.0,
		"base_health": 120,
		"health_per_level": 10,
		"base_attack": 100,
		"attack_per_level": 2,
		"base_defense": 2,
		"defense_levels": [4, 7, 10],
		"base_armor": 2,
		"armor_levels": [5, 9],
	},
	&"assassin": {
		"id": &"assassin",
		"title": "刺客",
		"start_weapon": &"sword",
		"skill_id": &"clones",
		"skill_cap": 3,
		"move_speed": 175.0,
		"base_health": 105,
		"health_per_level": 8,
		"base_attack": 105,
		"attack_per_level": 3,
		"base_defense": 1,
		"defense_levels": [5, 9],
		"base_armor": 1,
		"armor_levels": [4, 7, 10],
	},
}


## True when the hero exists in the table.
static func has_id(hero_id: StringName) -> bool:
	return HEROES.has(hero_id)


## Duplicate of one hero definition, or empty if unknown.
static func get_def(hero_id: StringName) -> Dictionary:
	if not has_id(hero_id):
		return {}
	return (HEROES[hero_id] as Dictionary).duplicate(true)


## Combat numbers at a clamped level 1..10. Unknown id → empty dict.
static func stats_at_level(hero_id: StringName, level: int) -> Dictionary:
	var def: Dictionary = get_def(hero_id)
	if def.is_empty():
		return {}
	var lv: int = clampi(level, 1, MAX_LEVEL)
	var steps: int = lv - 1
	return {
		"max_health": int(def["base_health"]) + int(def["health_per_level"]) * steps,
		"attack_power": int(def["base_attack"]) + int(def["attack_per_level"]) * steps,
		"defense": int(def["base_defense"]) + _bonus_count(def["defense_levels"], lv),
		"armor_capacity": int(def["base_armor"]) + _bonus_count(def["armor_levels"], lv),
		"move_speed": float(def["move_speed"]),
	}


## Every registered hero id.
static func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: Variant in HEROES.keys():
		ids.append(key as StringName)
	return ids


## XP needed to leave this level. 40 + 20*(level-1) for 1..9; 0 at 10.
static func xp_to_next(level: int) -> int:
	if level < 1 or level >= MAX_LEVEL:
		return 0
	return 40 + 20 * (level - 1)


## Highest playable hero level.
static func max_level() -> int:
	return MAX_LEVEL


static func _bonus_count(levels: Variant, level: int) -> int:
	var n := 0
	for lv: Variant in levels as Array:
		if level >= int(lv):
			n += 1
	return n

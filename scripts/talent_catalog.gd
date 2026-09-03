class_name TalentCatalog
extends RefCounted

const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")

## Static talent table. Common rows apply to every hero; exclusive rows list hero_ids.

const TALENTS := {
	&"force_training": {
		"id": &"force_training",
		"title": "火力训练",
		"description": "全部伤害 +8%",
		"category": &"offense",
		"hero_ids": [],
		"max_stacks": 3,
		"icon": "res://assets/generated/ui/talents/force-training.png",
	},
	&"rapid_trigger": {
		"id": &"rapid_trigger",
		"title": "迅捷扳机",
		"description": "远程武器冷却 ×0.92",
		"category": &"offense",
		"hero_ids": [],
		"max_stacks": 3,
		"icon": "res://assets/generated/ui/talents/rapid-trigger.png",
	},
	&"blade_training": {
		"id": &"blade_training",
		"title": "刃术训练",
		"description": "近战与分身近战伤害 +10%",
		"category": &"offense",
		"hero_ids": [],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/blade-training.png",
	},
	&"tempered_body": {
		"id": &"tempered_body",
		"title": "淬炼体魄",
		"description": "最大生命 +15",
		"category": &"defense",
		"hero_ids": [],
		"max_stacks": 3,
		"icon": "res://assets/generated/ui/talents/tempered-body.png",
	},
	&"composite_armor": {
		"id": &"composite_armor",
		"title": "复合护甲",
		"description": "护甲上限 +1",
		"category": &"defense",
		"hero_ids": [],
		"max_stacks": 3,
		"icon": "res://assets/generated/ui/talents/composite-armor.png",
	},
	&"defensive_posture": {
		"id": &"defensive_posture",
		"title": "防御姿态",
		"description": "防御 +1",
		"category": &"defense",
		"hero_ids": [],
		"max_stacks": 3,
		"icon": "res://assets/generated/ui/talents/defensive-posture.png",
	},
	&"swift_step": {
		"id": &"swift_step",
		"title": "迅步",
		"description": "移动速度 +5%",
		"category": &"utility",
		"hero_ids": [],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/swift-step.png",
	},
	&"energy_loop": {
		"id": &"energy_loop",
		"title": "能量回路",
		"description": "技能与冲刺冷却 ×0.90",
		"category": &"utility",
		"hero_ids": [],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/energy-loop.png",
	},
	&"field_medic": {
		"id": &"field_medic",
		"title": "战地医护",
		"description": "清波回复最大生命 8%",
		"category": &"utility",
		"hero_ids": [],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/field-medic.png",
	},
	&"scavenger": {
		"id": &"scavenger",
		"title": "拾荒者",
		"description": "击杀废料 +10%，按次向下取整",
		"category": &"utility",
		"hero_ids": [],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/scavenger.png",
	},
	&"knight_counterfire": {
		"id": &"knight_counterfire",
		"title": "骑士反击",
		"description": "消耗护甲时清除 64px 内敌方子弹",
		"category": &"defense",
		"hero_ids": [&"ember_hero"],
		"max_stacks": 1,
		"icon": "res://assets/generated/ui/talents/knight-counterfire.png",
	},
	&"knight_overdrive": {
		"id": &"knight_overdrive",
		"title": "过载突击",
		"description": "冲刺后 2 秒内下次命中伤害每层 +25%",
		"category": &"offense",
		"hero_ids": [&"ember_hero"],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/knight-overdrive.png",
	},
	&"knight_dash_guard": {
		"id": &"knight_dash_guard",
		"title": "冲刺守护",
		"description": "冲刺无敌时间 +0.08 秒",
		"category": &"utility",
		"hero_ids": [&"ember_hero"],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/knight-dash-guard.png",
	},
	&"shadow_edge": {
		"id": &"shadow_edge",
		"title": "影刃",
		"description": "分身伤害 +15%",
		"category": &"offense",
		"hero_ids": [&"assassin"],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/shadow-edge.png",
	},
	&"shadow_duration": {
		"id": &"shadow_duration",
		"title": "延影",
		"description": "分身持续时间 +0.8 秒",
		"category": &"utility",
		"hero_ids": [&"assassin"],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/shadow-duration.png",
	},
	&"shadow_haste": {
		"id": &"shadow_haste",
		"title": "影步急促",
		"description": "分身技能冷却 ×0.88",
		"category": &"utility",
		"hero_ids": [&"assassin"],
		"max_stacks": 2,
		"icon": "res://assets/generated/ui/talents/shadow-haste.png",
	},
}


## Returns true when the talent exists in the table.
static func has_id(id: StringName) -> bool:
	return TALENTS.has(id)


## Returns a duplicate of one talent definition, or empty if unknown.
static func get_def(id: StringName) -> Dictionary:
	if not has_id(id):
		return {}
	return (TALENTS[id] as Dictionary).duplicate(true)


## Every talent id in the table.
static func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: Variant in TALENTS.keys():
		ids.append(key as StringName)
	return ids


## Common talents plus exclusives for this hero, not the other hero.
static func ids_for_hero(hero_id: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: Variant in TALENTS.keys():
		var def: Dictionary = TALENTS[key]
		if is_hero_allowed(def, hero_id):
			ids.append(key as StringName)
	return ids


## Talent defs in this category that this hero can still stack.
static func pool_for(hero_id: StringName, category: StringName, counts: Dictionary) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for key: Variant in TALENTS.keys():
		var def: Dictionary = TALENTS[key]
		if def["category"] != category:
			continue
		if not is_hero_allowed(def, hero_id):
			continue
		var talent_id: StringName = def["id"]
		if int(counts.get(talent_id, 0)) < int(def["max_stacks"]):
			pool.append(def.duplicate(true))
	return pool


## Empty hero_ids means every hero; otherwise the id must be listed.
static func is_hero_allowed(def: Dictionary, hero_id: StringName) -> bool:
	var allowed: Array = def.get("hero_ids", [])
	if allowed.is_empty():
		return true
	if allowed.has(hero_id):
		return true
	return allowed.has(HeroDefinitionCatalog.combat_base(hero_id))

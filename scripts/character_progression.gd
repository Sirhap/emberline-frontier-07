class_name CharacterProgression
extends RefCounted

## Run-scoped Lv1–10 XP, talent picks, and derived HeroStats. Catalogs stay static.

signal level_changed(level: int)
signal choices_ready(choices: Array, pending_count: int)
signal stats_changed(stats: HeroStats)

const _CATEGORIES: Array[StringName] = [&"offense", &"defense", &"utility"]

var _hero_id: StringName = &""
var _level: int = 1
var _xp: int = 0
var _pending: int = 0
var _talent_counts: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _legacy_bonus_health: int = 0
var _legacy_dash_cooldown_level: int = 0
var _legacy_bonus_armor: int = 0
var _skill_rank: int = 0
var _open_choices: Array = []
var _started: bool = false


## Begins or restores a run. Unknown hero ids return ERR_INVALID_PARAMETER.
func start(hero_id: StringName, run_seed: int, restored: Dictionary = {}) -> Error:
	if not HeroDefinitionCatalog.has_id(hero_id):
		return ERR_INVALID_PARAMETER
	_hero_id = hero_id
	_started = true
	_level = clampi(int(restored.get("level", 1)), 1, HeroDefinitionCatalog.max_level())
	_xp = maxi(int(restored.get("xp", 0)), 0)
	_pending = maxi(int(restored.get("pending_choices", 0)), 0)
	_legacy_bonus_health = int(restored.get("legacy_bonus_health", 0))
	_legacy_dash_cooldown_level = int(restored.get("legacy_dash_cooldown_level", 0))
	_legacy_bonus_armor = int(restored.get("legacy_bonus_armor", 0))
	_skill_rank = int(restored.get("skill_rank", 0))
	_talent_counts = {}
	var raw_counts: Variant = restored.get("talent_counts", {})
	if raw_counts is Dictionary:
		for key: Variant in (raw_counts as Dictionary).keys():
			_talent_counts[StringName(str(key))] = int((raw_counts as Dictionary)[key])
	_open_choices = []
	_rng = RandomNumberGenerator.new()
	_rng.seed = run_seed
	if restored.has("talent_rng_state"):
		_rng.state = restored["talent_rng_state"]
	if _level >= HeroDefinitionCatalog.max_level():
		_xp = 0
	if _pending > 0:
		_roll_open_choices()
	return OK


## Grants kill XP from EnemyCatalog, levels up, and rolls a card set when pending and none is open.
func award_kill(variant: StringName, rank: StringName) -> Dictionary:
	var before: HeroStats = current_stats()
	var old_level: int = _level
	var xp_awarded: int = 0
	var max_lv: int = HeroDefinitionCatalog.max_level()
	if _started and _level < max_lv:
		xp_awarded = EnemyCatalog.experience_for(variant, rank)
		_xp += xp_awarded
		while _level < max_lv:
			var cost: int = HeroDefinitionCatalog.xp_to_next(_level)
			if cost <= 0 or _xp < cost:
				break
			_xp -= cost
			_level += 1
			_pending += 1
		if _level >= max_lv:
			_xp = 0
	if _pending > 0 and _open_choices.is_empty():
		_roll_open_choices()
	var after: HeroStats = current_stats()
	stats_changed.emit(after)
	if _level > old_level:
		level_changed.emit(_level)
	return {
		"xp_awarded": xp_awarded,
		"old_level": old_level,
		"new_level": _level,
		"levels_gained": _level - old_level,
		"pending_choices": _pending,
		"max_health_delta": after.max_health - before.max_health,
		"armor_delta": after.armor_capacity - before.armor_capacity,
	}


## Spends one pending pick on a currently offered talent id.
func choose_talent(talent_id: StringName) -> Dictionary:
	if not _is_open_choice(talent_id):
		return {
			"ok": false,
			"pending_choices": _pending,
			"error": "not in open choices",
		}
	_talent_counts[talent_id] = _count_of(talent_id) + 1
	_pending = maxi(_pending - 1, 0)
	_open_choices = []
	stats_changed.emit(current_stats())
	if _pending > 0:
		_roll_open_choices()
	return {
		"ok": true,
		"pending_choices": _pending,
		"error": "",
	}


## Wave-clear heal from current_stats.wave_heal_ratio * max_health, floored.
func apply_wave_clear() -> Dictionary:
	var stats: HeroStats = current_stats()
	var heal: int = int(floor(stats.wave_heal_ratio * float(stats.max_health)))
	return {"heal": heal}


## Base stats_at_level plus legacy bonuses and additive/multiplicative talent stacks.
func current_stats() -> HeroStats:
	var stats: HeroStats = HeroStats.defaults()
	if not _started:
		return stats
	var base: Dictionary = HeroDefinitionCatalog.stats_at_level(_hero_id, _level)
	if base.is_empty():
		return stats
	stats.max_health = int(base["max_health"]) + _legacy_bonus_health
	stats.attack_power = int(base["attack_power"])
	stats.defense = int(base["defense"])
	stats.armor_capacity = int(base["armor_capacity"]) + _legacy_bonus_armor
	stats.move_speed = float(base["move_speed"])
	stats.skill_rank = _skill_rank

	var force_training: int = _count_of(&"force_training")
	stats.all_damage_mult = 1.0 + 0.08 * float(force_training)

	var rapid_trigger: int = _count_of(&"rapid_trigger")
	stats.ranged_cooldown_mult = pow(0.92, rapid_trigger)

	var blade_training: int = _count_of(&"blade_training")
	stats.melee_damage_mult = 1.0 + 0.10 * float(blade_training)

	var tempered_body: int = _count_of(&"tempered_body")
	stats.max_health += 15 * tempered_body

	var composite_armor: int = _count_of(&"composite_armor")
	stats.armor_capacity += composite_armor

	var defensive_posture: int = _count_of(&"defensive_posture")
	stats.defense += defensive_posture

	var swift_step: int = _count_of(&"swift_step")
	stats.move_speed *= 1.0 + 0.05 * float(swift_step)

	var energy_loop: int = _count_of(&"energy_loop")
	stats.dash_cooldown_mult *= pow(0.90, energy_loop)

	var field_medic: int = _count_of(&"field_medic")
	stats.wave_heal_ratio = 0.08 * float(field_medic)

	var scavenger: int = _count_of(&"scavenger")
	stats.scrap_reward_mult = 1.0 + 0.10 * float(scavenger)

	stats.knight_counterfire = _count_of(&"knight_counterfire") >= 1
	stats.knight_overdrive_stacks = _count_of(&"knight_overdrive")

	var knight_dash_guard: int = _count_of(&"knight_dash_guard")
	stats.dash_invuln_bonus += 0.08 * float(knight_dash_guard)

	var shadow_edge: int = _count_of(&"shadow_edge")
	stats.clone_damage_mult = 1.0 + 0.15 * float(shadow_edge)

	var shadow_duration: int = _count_of(&"shadow_duration")
	stats.clone_duration_bonus += 0.8 * float(shadow_duration)

	var shadow_haste: int = _count_of(&"shadow_haste")
	stats.clone_skill_cooldown_mult *= pow(0.88, shadow_haste)

	return stats


## Persistable run fields. Derived combat numbers are not stored.
func snapshot() -> Dictionary:
	var counts := {}
	for key: Variant in _talent_counts.keys():
		counts[String(key)] = int(_talent_counts[key])
	return {
		"hero_id": String(_hero_id),
		"level": _level,
		"xp": _xp,
		"pending_choices": _pending,
		"talent_counts": counts,
		"talent_rng_state": int(_rng.state),
		"legacy_bonus_health": _legacy_bonus_health,
		"legacy_dash_cooldown_level": _legacy_dash_cooldown_level,
		"legacy_bonus_armor": _legacy_bonus_armor,
		"skill_rank": _skill_rank,
	}


func _count_of(talent_id: StringName) -> int:
	if _talent_counts.has(talent_id):
		return int(_talent_counts[talent_id])
	var as_text := String(talent_id)
	if _talent_counts.has(as_text):
		return int(_talent_counts[as_text])
	return 0


func _pool_counts() -> Dictionary:
	var counts := {}
	for key: Variant in _talent_counts.keys():
		counts[StringName(str(key))] = int(_talent_counts[key])
	return counts


func _is_open_choice(talent_id: StringName) -> bool:
	for card: Variant in _open_choices:
		if (card as Dictionary).get("id", &"") == talent_id:
			return true
	return false


func _roll_open_choices() -> void:
	_open_choices = _draw_three()
	choices_ready.emit(_open_choices.duplicate(true), _pending)


func _draw_three() -> Array:
	var chosen: Array = []
	var counts: Dictionary = _pool_counts()
	for category: StringName in _CATEGORIES:
		var pool: Array = _exclude_ids(TalentCatalog.pool_for(_hero_id, category, counts), _ids_in(chosen))
		if pool.is_empty():
			continue
		chosen.append(_pick(pool))
	if chosen.size() < 3:
		while chosen.size() < 3:
			var remaining: Array = _uncapped_for_hero(_ids_in(chosen))
			if remaining.is_empty():
				break
			chosen.append(_pick(remaining))
	if chosen.size() < 3:
		push_error("TalentCatalog: could not fill 3 choices")
		while chosen.size() < 3:
			var commons: Array = _uncapped_common(_ids_in(chosen))
			if commons.is_empty():
				break
			chosen.append(_pick(commons))
	return chosen


func _pick(pool: Array) -> Dictionary:
	var index: int = _rng.randi_range(0, pool.size() - 1)
	var picked: Dictionary = pool[index]
	return picked.duplicate(true)


func _ids_in(choices: Array) -> Dictionary:
	var ids := {}
	for card: Variant in choices:
		ids[(card as Dictionary)["id"]] = true
	return ids


func _exclude_ids(pool: Array, exclude: Dictionary) -> Array:
	var out: Array = []
	for item: Variant in pool:
		var def: Dictionary = item
		if exclude.has(def["id"]):
			continue
		out.append(def)
	return out


func _uncapped_for_hero(exclude: Dictionary) -> Array:
	var counts: Dictionary = _pool_counts()
	var out: Array = []
	for talent_id: StringName in TalentCatalog.ids_for_hero(_hero_id):
		if exclude.has(talent_id):
			continue
		var def: Dictionary = TalentCatalog.get_def(talent_id)
		if def.is_empty():
			continue
		if int(counts.get(talent_id, 0)) >= int(def["max_stacks"]):
			continue
		out.append(def)
	return out


func _uncapped_common(exclude: Dictionary) -> Array:
	var counts: Dictionary = _pool_counts()
	var out: Array = []
	for talent_id: StringName in TalentCatalog.all_ids():
		var def: Dictionary = TalentCatalog.get_def(talent_id)
		if def.is_empty():
			continue
		var allowed: Array = def.get("hero_ids", [])
		if not allowed.is_empty():
			continue
		if exclude.has(talent_id):
			continue
		if int(counts.get(talent_id, 0)) >= int(def["max_stacks"]):
			continue
		out.append(def)
	return out

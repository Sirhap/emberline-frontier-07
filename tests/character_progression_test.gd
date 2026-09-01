extends SceneTree

const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")
const EnemyCatalog := preload("res://scripts/enemy_catalog.gd")
const TalentCatalog := preload("res://scripts/talent_catalog.gd")
const HeroStats := preload("res://scripts/hero_stats.gd")
const CharacterProgression := preload("res://scripts/character_progression.gd")


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	var unknown := CharacterProgression.new()
	assert(unknown.start(&"unknown", 1) == ERR_INVALID_PARAMETER, "unknown hero should be ERR_INVALID_PARAMETER")
	assert(unknown.start(&"nope", 7) == ERR_INVALID_PARAMETER, "missing hero id should be ERR_INVALID_PARAMETER")

	var scout_xp: int = EnemyCatalog.experience_for(&"scout", &"normal")
	assert(scout_xp == 5, "scout XP is 5")

	var seven := CharacterProgression.new()
	assert(seven.start(&"ember_hero", 1) == OK, "knight start should succeed")
	var last_seven: Dictionary = _kill_scouts(seven, 7)
	var snap_seven: Dictionary = seven.snapshot()
	assert(int(snap_seven["level"]) == 1, "7 scouts stay lv1")
	assert(int(snap_seven["xp"]) == 35, "7 scouts are 35 XP")
	assert(int(snap_seven["pending_choices"]) == 0, "7 scouts grant no talent pending")
	assert(int(last_seven["new_level"]) == 1, "7th scout new_level is 1")
	assert(int(last_seven["levels_gained"]) == 0, "7th scout gains no levels")

	var eighth: Dictionary = seven.award_kill(&"scout", &"normal")
	assert(int(eighth["xp_awarded"]) == 5, "8th scout still awards 5 XP")
	assert(int(eighth["old_level"]) == 1, "8th scout starts at lv1")
	assert(int(eighth["new_level"]) == 2, "8th scout (40 XP) reaches lv2")
	assert(int(eighth["levels_gained"]) == 1, "8th scout gains one level")
	assert(int(eighth["pending_choices"]) == 1, "each level adds one pending choice")
	assert(int(seven.snapshot()["level"]) == 2, "snapshot level is 2")
	assert(int(seven.snapshot()["xp"]) == 0, "exact threshold leaves 0 XP")
	assert(int(seven.snapshot()["pending_choices"]) == 1, "snapshot pending is 1")

	var boss := CharacterProgression.new()
	boss.start(&"ember_hero", 2)
	var boss_hit: Dictionary = boss.award_kill(&"boss", &"boss")
	assert(int(boss_hit["xp_awarded"]) == 60, "boss awards 60 XP")
	assert(int(boss_hit["old_level"]) == 1)
	assert(int(boss_hit["new_level"]) == 2, "60 XP from lv1 reaches lv2 not lv3")
	assert(int(boss_hit["levels_gained"]) == 1)
	assert(int(boss_hit["pending_choices"]) == 1)
	assert(int(boss.snapshot()["xp"]) == 20, "60-40 remainder is 20")

	var piled := CharacterProgression.new()
	piled.start(&"ember_hero", 3)
	var piled_last: Dictionary = _kill_scouts(piled, 40)
	var piled_snap: Dictionary = piled.snapshot()
	assert(int(piled_snap["level"]) == 4, "200 XP from 0 reaches lv4")
	assert(int(piled_snap["xp"]) == 20, "200 XP leftover after lv4 is 20")
	assert(int(piled_snap["pending_choices"]) == 3, "three levels leave three pending, not merged")
	assert(int(piled_last["new_level"]) == 4)
	assert(int(piled_last["pending_choices"]) == 3)

	var cap := CharacterProgression.new()
	cap.start(&"ember_hero", 4, {"level": 9, "xp": 195})
	var to_ten: Dictionary = cap.award_kill(&"scout", &"normal")
	assert(int(to_ten["new_level"]) == 10, "crossing 1080 cumulative XP reaches lv10")
	assert(int(cap.snapshot()["level"]) == 10)
	assert(int(cap.snapshot()["xp"]) == 0, "lv10 visible XP is 0")
	var extra: Dictionary = cap.award_kill(&"scout", &"normal")
	assert(int(extra["xp_awarded"]) == 0, "kills at lv10 do not award visible XP")
	assert(int(extra["new_level"]) == 10)
	assert(int(extra["levels_gained"]) == 0)
	assert(int(cap.snapshot()["xp"]) == 0, "further kills keep XP at 0")
	assert(int(cap.snapshot()["level"]) == 10)

	var already_ten := CharacterProgression.new()
	already_ten.start(&"ember_hero", 5, {"level": 10, "xp": 0})
	var at_ten: Dictionary = already_ten.award_kill(&"boss", &"boss")
	assert(int(at_ten["xp_awarded"]) == 0)
	assert(int(at_ten["new_level"]) == 10)
	assert(int(already_ten.snapshot()["xp"]) == 0)

	var knight := CharacterProgression.new()
	knight.start(&"ember_hero", 6)
	var assassin := CharacterProgression.new()
	assassin.start(&"assassin", 6)
	assert(knight.current_stats().max_health == 120, "knight lv1 HP is 120")
	assert(assassin.current_stats().max_health == 105, "assassin lv1 HP is 105")
	assert(int(HeroDefinitionCatalog.stats_at_level(&"ember_hero", 1)["max_health"]) == 120)
	assert(int(HeroDefinitionCatalog.stats_at_level(&"assassin", 1)["max_health"]) == 105)

	var tempered := CharacterProgression.new()
	tempered.start(&"ember_hero", 7, {"level": 1, "talent_counts": {"tempered_body": 1}})
	assert(tempered.current_stats().max_health == 135, "tempered_body +15 on knight lv1 is 135")

	var hp_up := CharacterProgression.new()
	var hp_emits := [0]
	hp_up.stats_changed.connect(func(_stats: HeroStats) -> void: hp_emits[0] += 1)
	var lv_emits: Array = []
	hp_up.level_changed.connect(func(level: int) -> void: lv_emits.append(level))
	hp_up.start(&"ember_hero", 8)
	_kill_scouts(hp_up, 7)
	assert(lv_emits.is_empty(), "level_changed is silent while still lv1")
	var hp_delta: Dictionary = hp_up.award_kill(&"scout", &"normal")
	assert(int(hp_delta["max_health_delta"]) == 10, "knight 1→2 HP delta is +10")
	assert(int(hp_delta["armor_delta"]) == 0, "knight 1→2 armor does not change")
	assert(lv_emits == [2], "level_changed emits new level")
	assert(hp_emits[0] == 8, "award_kill always emits stats_changed")

	var armor_up := CharacterProgression.new()
	armor_up.start(&"ember_hero", 9, {"level": 4, "xp": 0})
	assert(armor_up.current_stats().armor_capacity == 2, "knight lv4 armor is 2")
	_kill_scouts(armor_up, 19)
	assert(int(armor_up.snapshot()["level"]) == 4, "95 XP is still lv4")
	var armor_hit: Dictionary = armor_up.award_kill(&"scout", &"normal")
	assert(int(armor_hit["new_level"]) == 5, "100 XP at lv4 reaches lv5")
	assert(int(armor_hit["armor_delta"]) == 1, "knight 4→5 armor capacity 2→3")
	assert(int(armor_hit["max_health_delta"]) == 10, "knight 4→5 HP +10")
	assert(armor_up.current_stats().armor_capacity == 3)

	var tower_xp := CharacterProgression.new()
	tower_xp.start(&"ember_hero", 10)
	var hero_kill: Dictionary = tower_xp.award_kill(&"scout", &"normal")
	var tower_kill: Dictionary = tower_xp.award_kill(&"scout", &"normal")
	assert(int(hero_kill["xp_awarded"]) == 5, "hero kill uses award_kill XP")
	assert(int(tower_kill["xp_awarded"]) == 5, "tower kill uses the same award_kill")
	assert(int(tower_xp.snapshot()["xp"]) == 10, "two scouts are 10 XP")

	var legacy := CharacterProgression.new()
	legacy.start(&"ember_hero", 11, {
		"legacy_bonus_health": 10,
		"legacy_bonus_armor": 2,
		"legacy_dash_cooldown_level": 1,
		"skill_rank": 2,
	})
	assert(legacy.current_stats().max_health == 130, "legacy_bonus_health stacks on base HP")
	assert(legacy.current_stats().armor_capacity == 4, "legacy_bonus_armor stacks on base armor")
	assert(legacy.current_stats().skill_rank == 2, "skill_rank is copied from restore")
	var legacy_snap: Dictionary = legacy.snapshot()
	assert(String(legacy_snap["hero_id"]) == "ember_hero")
	assert(int(legacy_snap["legacy_bonus_health"]) == 10)
	assert(int(legacy_snap["legacy_bonus_armor"]) == 2)
	assert(int(legacy_snap["legacy_dash_cooldown_level"]) == 1)
	assert(int(legacy_snap["skill_rank"]) == 2)
	assert(not legacy_snap.has("max_health"), "snapshot must not store derived max_health")
	assert(not legacy_snap.has("attack_power"), "snapshot must not store derived attack_power")
	assert(typeof(legacy_snap["talent_rng_state"]) == TYPE_INT, "talent_rng_state is int")

	var force := CharacterProgression.new()
	force.start(&"ember_hero", 12, {"talent_counts": {"force_training": 2}})
	assert(is_equal_approx(force.current_stats().all_damage_mult, 1.16), "force_training 2 stacks is +16%")
	var force_snap: Dictionary = force.snapshot()
	assert(int(force_snap["talent_counts"]["force_training"]) == 2)
	for key: Variant in force_snap["talent_counts"].keys():
		assert(typeof(key) == TYPE_STRING, "talent_counts snapshot keys are strings")

	var medic := CharacterProgression.new()
	medic.start(&"ember_hero", 13, {"talent_counts": {"field_medic": 1}})
	var heal: Dictionary = medic.apply_wave_clear()
	assert(int(heal["heal"]) == 9, "field_medic 8% of 120 floors to 9")
	assert(TalentCatalog.has_id(&"field_medic"))

	print("CHARACTER PROGRESSION PASS")
	quit()


func _kill_scouts(prog: CharacterProgression, n: int) -> Dictionary:
	var last: Dictionary = {}
	for _i in n:
		last = prog.award_kill(&"scout", &"normal")
	return last

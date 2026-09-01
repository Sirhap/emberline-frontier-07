extends SceneTree

const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")
const HeroStats := preload("res://scripts/hero_stats.gd")

const TABLE: Array[Array] = [
	[1, 120, 100, 2, 2, 105, 105, 1, 1],
	[2, 130, 102, 2, 2, 113, 108, 1, 1],
	[3, 140, 104, 2, 2, 121, 111, 1, 1],
	[4, 150, 106, 3, 2, 129, 114, 1, 2],
	[5, 160, 108, 3, 3, 137, 117, 2, 2],
	[6, 170, 110, 3, 3, 145, 120, 2, 2],
	[7, 180, 112, 4, 3, 153, 123, 2, 3],
	[8, 190, 114, 4, 3, 161, 126, 2, 3],
	[9, 200, 116, 4, 4, 169, 129, 3, 3],
	[10, 210, 118, 5, 4, 177, 132, 3, 4],
]


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	assert(HeroDefinitionCatalog.has_id(&"ember_hero"), "knight id should exist")
	assert(HeroDefinitionCatalog.has_id(&"assassin"), "assassin id should exist")
	assert(not HeroDefinitionCatalog.has_id(&"unknown"), "unknown id should not exist")
	assert(HeroDefinitionCatalog.max_level() == 10, "max level should be 10")

	var ids: Array[StringName] = HeroDefinitionCatalog.all_ids()
	assert(ids.has(&"ember_hero") and ids.has(&"assassin"), "all_ids should list both heroes")

	for row: Array in TABLE:
		var level: int = int(row[0])
		_assert_stats(&"ember_hero", level, int(row[1]), int(row[2]), int(row[3]), int(row[4]), 165.0)
		_assert_stats(&"assassin", level, int(row[5]), int(row[6]), int(row[7]), int(row[8]), 175.0)

	assert(HeroDefinitionCatalog.stats_at_level(&"nope", 1).is_empty(), "unknown id should yield empty stats")
	assert(HeroDefinitionCatalog.get_def(&"nope").is_empty(), "unknown id should yield empty def")

	var clamped_low: Dictionary = HeroDefinitionCatalog.stats_at_level(&"ember_hero", 0)
	var clamped_high: Dictionary = HeroDefinitionCatalog.stats_at_level(&"assassin", 99)
	_assert_stats(&"ember_hero", 1, int(clamped_low["max_health"]), int(clamped_low["attack_power"]), int(clamped_low["defense"]), int(clamped_low["armor_capacity"]), 165.0)
	_assert_stats(&"assassin", 10, int(clamped_high["max_health"]), int(clamped_high["attack_power"]), int(clamped_high["defense"]), int(clamped_high["armor_capacity"]), 175.0)

	var knight: Dictionary = HeroDefinitionCatalog.get_def(&"ember_hero")
	assert(knight["id"] == &"ember_hero")
	assert(knight["start_weapon"] == &"sword")
	assert(knight["skill_id"] == &"dash")
	assert(int(knight["skill_cap"]) == 2)
	assert(knight.has("defense_levels") and knight.has("armor_levels"))
	knight["title"] = "mutated"
	assert(HeroDefinitionCatalog.get_def(&"ember_hero")["title"] != "mutated", "get_def must duplicate")

	var assassin: Dictionary = HeroDefinitionCatalog.get_def(&"assassin")
	assert(assassin["id"] == &"assassin")
	assert(assassin["start_weapon"] == &"sword")
	assert(assassin["skill_id"] == &"clones")
	assert(int(assassin["skill_cap"]) == 3)

	assert(HeroDefinitionCatalog.xp_to_next(1) == 40)
	assert(HeroDefinitionCatalog.xp_to_next(2) == 60)
	assert(HeroDefinitionCatalog.xp_to_next(9) == 200)
	assert(HeroDefinitionCatalog.xp_to_next(10) == 0)
	var xp_sum := 0
	for level in range(1, 10):
		xp_sum += HeroDefinitionCatalog.xp_to_next(level)
	assert(xp_sum == 1080, "cumulative XP to reach level 10 should be 1080")

	var stats: HeroStats = HeroStats.defaults()
	assert(stats.max_health == 120)
	assert(stats.attack_power == 100)
	assert(stats.defense == 2)
	assert(stats.armor_capacity == 2)
	assert(is_equal_approx(stats.move_speed, 165.0))
	assert(is_equal_approx(stats.dash_cooldown_mult, 1.0))
	assert(is_equal_approx(stats.all_damage_mult, 1.0))
	assert(is_equal_approx(stats.melee_damage_mult, 1.0))
	assert(is_equal_approx(stats.ranged_cooldown_mult, 1.0))
	assert(is_equal_approx(stats.clone_damage_mult, 1.0))
	assert(is_equal_approx(stats.scrap_reward_mult, 1.0))
	assert(stats.clone_count_bonus == 0)
	assert(stats.knight_counterfire == false)
	assert(stats.knight_overdrive_stacks == 0)

	print("HERO DEFINITION PASS")
	quit()


func _assert_stats(hero_id: StringName, level: int, hp: int, atk: int, defense: int, armor: int, move_speed: float) -> void:
	var stats: Dictionary = HeroDefinitionCatalog.stats_at_level(hero_id, level)
	assert(not stats.is_empty(), "stats_at_level should return a row for %s lv %d" % [String(hero_id), level])
	assert(int(stats["max_health"]) == hp, "%s lv %d HP" % [String(hero_id), level])
	assert(int(stats["attack_power"]) == atk, "%s lv %d ATK" % [String(hero_id), level])
	assert(int(stats["defense"]) == defense, "%s lv %d DEF" % [String(hero_id), level])
	assert(int(stats["armor_capacity"]) == armor, "%s lv %d ARM" % [String(hero_id), level])
	assert(is_equal_approx(float(stats["move_speed"]), move_speed), "%s move_speed" % String(hero_id))

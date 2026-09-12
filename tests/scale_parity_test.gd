extends SceneTree

const EmberHero := preload("res://scripts/hero.gd")


func _init() -> void:
	create_timer(90.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	assert(is_equal_approx(EmberHero.COMBAT_VISUAL_SCALE, 0.34), "combat visual scale target is 0.34")
	assert(is_equal_approx(EmberHero.KNIGHT_VISUAL_SIZE, EmberHero.COMBAT_VISUAL_SCALE), "knight alias matches combat scale")
	assert(is_equal_approx(EmberHero.ASSASSIN_VISUAL_SCALE, EmberHero.COMBAT_VISUAL_SCALE), "assassin no longer uses 0.38")
	assert(is_equal_approx(EmberHero.KNIGHT_VISUAL_SIZE, EmberHero.ASSASSIN_VISUAL_SCALE), "knight and assassin share one visual scale")

	var assassin_tuning: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://xsxb_frame_tuner/data/projects/emberline_enemies/animation_tuning.json")
	)
	var assassin_size := float((assassin_tuning.get("values", {}) as Dictionary).get("profiles.ember_assassin.character.visual_size", 0.0))
	assert(is_equal_approx(assassin_size, EmberHero.COMBAT_VISUAL_SCALE), "assassin tuning visual_size matches combat 0.34")

	var knight_tuning: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://xsxb_frame_tuner/data/projects/emberline_frontier_07_final/animation_tuning.json")
	)
	var knight_size := float((knight_tuning.get("values", {}) as Dictionary).get("profiles.ember_hero.character.visual_size", 0.0))
	assert(is_equal_approx(knight_size, EmberHero.COMBAT_VISUAL_SCALE), "knight tuning visual_size matches combat 0.34")

	var hero := EmberHero.new()
	hero.name = "ScaleParityHero"
	root.add_child(hero)
	await process_frame
	hero.apply_hero_kind(&"ember_hero")
	hero.skill_levels[&"ember_hero"] = 0
	hero.call("_refresh_combat_visual_scale")
	assert(is_equal_approx(float(hero.call("combat_visual_scale")), EmberHero.COMBAT_VISUAL_SCALE), "idle knight combat scale")
	assert(is_equal_approx(float(hero.call("skill_size_mult")), 1.0), "skill 0 multiplier is 1")
	_assert_actor_scale(hero, "knight skill 0")

	hero.skill_levels[&"ember_hero"] = 2
	hero.call("_refresh_combat_visual_scale")
	assert(is_equal_approx(float(hero.call("skill_size_mult")), EmberHero.KNIGHT_SKILL_SIZE * EmberHero.KNIGHT_SKILL_SIZE), "knight skill_size_mult still grows for range/damage")
	assert(is_equal_approx(float(hero.call("combat_visual_scale")), EmberHero.COMBAT_VISUAL_SCALE), "knight skill does not change sprite scale")
	assert(float(hero.call("skill_range_bonus")) > 0.0, "knight skill still adds range")
	assert(int(hero.call("dash_strike_damage")) > EmberHero.DASH_DAMAGE, "knight skill still adds dash damage")
	_assert_actor_scale(hero, "knight skill 2")

	hero.apply_hero_kind(&"assassin")
	await process_frame
	hero.skill_levels[&"assassin"] = 3
	hero.call("_refresh_combat_visual_scale")
	assert(is_equal_approx(float(hero.call("combat_visual_scale")), EmberHero.COMBAT_VISUAL_SCALE), "assassin combat scale matches knight")
	assert(is_equal_approx(float(hero.call("skill_size_mult")), 1.0), "assassin skill does not grow size mult")
	_assert_actor_scale(hero, "assassin")

	hero.apply_hero_kind(&"ember_hero", &"frost_warrior")
	await process_frame
	hero.skill_levels[&"ember_hero"] = 2
	hero.call("_refresh_combat_visual_scale")
	assert(is_equal_approx(float(hero.call("combat_visual_scale")), EmberHero.COMBAT_VISUAL_SCALE), "unarmed frost stays at combat scale")
	_assert_actor_scale(hero, "frost unarmed")

	hero.has_dash = true
	hero.dash_cooldown_left = 0.0
	hero.call("request_dash")
	var frost_actor := hero.get_node_or_null("XSXBHeroActor")
	assert(frost_actor != null)
	hero.call("_update_dash", float(frost_actor.call("animation_duration", "skill_cast_side")) + 0.05)
	assert(hero.visual_pack_id == &"frost_armed", "frost skill still transforms")
	hero.skill_levels[&"ember_hero"] = 2
	hero.call("_refresh_combat_visual_scale")
	assert(is_equal_approx(float(hero.call("skill_size_mult")), EmberHero.FROST_SKILL_SIZE * EmberHero.FROST_SKILL_SIZE), "armed frost skill_size_mult grows for range/damage")
	assert(is_equal_approx(float(hero.call("combat_visual_scale")), EmberHero.COMBAT_VISUAL_SCALE), "armed frost skill does not scale the sprite")
	_assert_actor_scale(hero, "frost armed skill 2")

	hero.queue_free()
	print("SCALE PARITY PASS")
	quit()


func _assert_actor_scale(hero: Node, label: String) -> void:
	var actor := hero.get_node_or_null("XSXBHeroActor")
	assert(actor != null, "%s actor exists" % label)
	assert(is_equal_approx(float(actor.get("fallback_visual_scale")), EmberHero.COMBAT_VISUAL_SCALE), "%s fallback_visual_scale stays 0.34" % label)
	var values: Variant = actor.get("_tuning_values")
	assert(values is Dictionary, "%s actor has tuning values" % label)
	var profile := str(actor.get("frame_profile_id"))
	var tuned := float((values as Dictionary).get("profiles.%s.character.visual_size" % profile, 0.0))
	assert(is_equal_approx(tuned, EmberHero.COMBAT_VISUAL_SCALE), "%s character.visual_size stays 0.34" % label)

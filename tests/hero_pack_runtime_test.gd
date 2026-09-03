extends SceneTree

const EmberHero := preload("res://scripts/hero.gd")
const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")
const HeroPackCatalog := preload("res://scripts/hero_pack_catalog.gd")


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	var hero := EmberHero.new()
	hero.name = "PackHero"
	root.add_child(hero)
	await process_frame
	hero.apply_hero_kind(&"ember_hero")
	assert(hero.hero_kind == &"ember_hero")
	assert(hero.hero_id == &"ember_hero")
	assert(hero.visual_pack_id == &"ember_hero")
	var actor := hero.get_node_or_null("XSXBHeroActor")
	assert(actor != null, "knight actor exists")
	assert(str(actor.get("frame_profile_id")) == "ember_hero")
	assert(hero._clip_name(&"idle") == "idle")
	assert(hero._clip_name(&"run") == "run")
	hero.apply_hero_kind(&"assassin")
	await process_frame
	assert(hero.hero_kind == &"assassin")
	assert(hero.visual_pack_id == &"assassin")
	actor = hero.get_node_or_null("XSXBHeroActor")
	assert(str(actor.get("frame_profile_id")) == "ember_assassin")
	assert(hero._clip_name(&"run") == "walk")
	assert(hero._clip_name(&"dash") == "skill_cast")
	assert(hero.call("_hides_held_overlay") == true, "assassin hides the hold-sword overlay")
	hero.weapon_slots = [&"sword", &"pistol"] as Array[StringName]
	assert(hero.select_weapon_slot(1))
	await process_frame
	assert(hero.call("_hides_held_overlay") == false, "assassin still floats guns")
	var held := hero.find_child("HeldWeapon", true, false) as Sprite2D
	assert(held != null and held.visible and held.texture != null, "assassin gun overlay exists")
	assert(hero.select_weapon_slot(0))
	assert(hero.call("_hides_held_overlay") == true, "assassin melee hides overlay again")
	assert(HeroPackSpec.clip_name("idle", "assassin", "three", "front") == "idle_front")
	hero.apply_hero_kind(&"ember_hero", &"frost_warrior")
	await process_frame
	assert(hero.visual_pack_id == &"frost_warrior")
	assert(hero.get("_view_mode") == "three")
	assert(hero.get("_view") == &"side")
	assert(hero._clip_name(&"idle") == "idle_side", "combat frost stays on side")
	assert(hero._clip_name(&"dash") == "skill_cast_side", "frost skill uses skill_cast")
	assert(hero.call("_hides_held_overlay") == true, "unarmed frost hides the hold-sword overlay")
	var frost_actor := hero.get_node_or_null("XSXBHeroActor")
	assert(frost_actor != null)
	assert(float(frost_actor.call("animation_duration", "skill_cast_side")) >= 1.20, "frost transform clip is ~1.5s")
	assert(HeroPackCatalog.transform_into(&"frost_warrior") == &"frost_armed")
	assert(not HeroPackCatalog.selectable_skin_ids(&"ember_hero").has(&"frost_armed"), "armed form is hidden from picker")
	assert(HeroPackCatalog.can_apply_pack(&"ember_hero", &"frost_armed"), "combat can still apply the armed form")
	hero.has_dash = true
	hero.dash_cooldown_left = 0.0
	hero.skill_levels[&"ember_hero"] = 2
	assert(is_equal_approx(float(hero.call("skill_size_mult")), 1.0), "unarmed frost does not grow")
	hero.skill_levels[&"ember_hero"] = 0
	hero.call("request_dash")
	assert(bool(hero.get("_transforming")), "frost skill starts a transform")
	var cast_time := float(frost_actor.call("animation_duration", "skill_cast_side"))
	hero.call("_update_dash", cast_time + 0.05)
	assert(hero.visual_pack_id == &"frost_armed", "transform swaps to the armed pack")
	assert(not bool(hero.get("_transforming")))
	hero.skill_levels[&"ember_hero"] = 2
	hero.call("_refresh_combat_visual_scale")
	assert(is_equal_approx(float(hero.call("form_damage_mult")), 1.40), "armed form damage scales with skill")
	assert(is_equal_approx(float(hero.call("skill_size_mult")), EmberHero.FROST_SKILL_SIZE * EmberHero.FROST_SKILL_SIZE), "armed form grows slightly per skill")
	assert(int(hero.call("dash_strike_damage")) == EmberHero.scale_damage(EmberHero.DASH_DAMAGE, 100, 1.0, 1.0, 1.40, 1.0), "frost dash does not also take knight +12")
	hero.skill_levels[&"ember_hero"] = 0
	hero.call("_refresh_combat_visual_scale")
	hero.call("_apply_view_from_move", Vector2(0.0, 1.0))
	assert(hero.get("_view") == &"side", "combat ignores south view")
	assert(hero._clip_name(&"run") == "run_side")
	hero.call("_apply_view_from_move", Vector2(0.0, -1.0))
	assert(hero._clip_name(&"jump") == "jump_side", "combat jump stays side")
	assert(is_equal_approx(hero.form_left, EmberHero.FROST_FORM_DURATION), "armed form starts an 8s timer")
	var armed_now := hero.get_node_or_null("XSXBHeroActor")
	assert(armed_now != null)
	assert(float(armed_now.call("animation_duration", "skill_bubble_side")) >= 1.20, "untransform clip is ~1.4s")
	hero.form_left = 0.0
	hero.call("_tick_frost_form", 0.05)
	assert(bool(hero.get("_reverting")), "timer expiry starts untransform")
	assert(hero._clip_name(&"dash") == "skill_bubble_side")
	hero.call("_update_dash", float(armed_now.call("animation_duration", "skill_bubble_side")) + 0.05)
	assert(hero.visual_pack_id == &"frost_warrior", "untransform returns to unarmed frost")
	assert(not bool(hero.get("_reverting")))
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	await process_frame
	hero.form_left = 0.0
	hero.call("_tick_frost_form", 0.05)
	assert(bool(hero.get("_reverting")), "expiry starts untransform before down")
	hero.call("_start_down")
	assert(hero.visual_pack_id == &"frost_warrior", "down during untransform snaps to unarmed")
	assert(not bool(hero.get("_reverting")))
	hero.is_down = false
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	await process_frame
	hero.form_left = 0.0
	hero.set("_queued_dash", true)
	hero.set("_jump_elapsed", -1.0)
	hero.call("_flush_action_queue")
	assert(bool(hero.get("_reverting")), "queued skill after expiry untransforms")
	assert(hero._clip_name(&"dash") == "skill_bubble_side")
	hero.call("_update_dash", float(hero.get_node("XSXBHeroActor").call("animation_duration", "skill_bubble_side")) + 0.05)
	assert(hero.visual_pack_id == &"frost_warrior", "queued expiry does not keep the armed pack")
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	await process_frame
	hero.form_left = 0.0
	hero.set("_jump_elapsed", 0.10)
	hero.set("_jump_offset", -16.0)
	hero.call("_tick_frost_form", 0.05)
	assert(bool(hero.get("_reverting")), "expiry cancels jump into untransform")
	assert(float(hero.get("_jump_elapsed")) < 0.0)
	hero.call("_update_dash", 3.0)
	assert(hero.visual_pack_id == &"frost_warrior")
	hero.apply_hero_kind(&"ember_hero", &"frost_warrior")
	await process_frame
	hero.has_dash = true
	hero.dash_cooldown_left = 0.0
	hero.call("request_dash")
	assert(bool(hero.get("_transforming")), "unarmed frost skill starts transform")
	hero.call("_start_down")
	assert(hero.visual_pack_id == &"frost_warrior", "down during transform-in stays unarmed")
	assert(not bool(hero.get("_transforming")))
	hero.is_down = false
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	await process_frame
	hero.form_left = 4.0
	hero.call("_start_down")
	assert(hero.visual_pack_id == &"frost_armed", "down with form time left stays armed")
	hero.is_down = false
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	await process_frame
	assert(hero.visual_pack_id == &"frost_armed")
	assert(hero.get("_view_mode") == "three")
	assert(hero._clip_name(&"idle") == "idle_side")
	assert(hero._clip_name(&"dash") == "dash_side", "armed frost skill uses the dash clip")
	assert(hero.call("_hides_held_overlay") == true, "baked greatsword hides hold overlay")
	var armed_actor := hero.get_node_or_null("XSXBHeroActor")
	assert(armed_actor != null)
	assert(str(armed_actor.get("frame_profile_id")) == "frost_armed")
	assert(float(armed_actor.call("animation_duration", "dash_side")) > 0.0, "armed dash clip exists")
	var armed_anims: Dictionary = armed_actor.get("_animations")
	assert(int((armed_anims.get("run_side", {}) as Dictionary).get("fps", 0)) == 16, "armed run uses pack slot_fps 16")
	assert(int((armed_anims.get("attack_side", {}) as Dictionary).get("fps", 0)) == 16, "armed attack uses pack slot_fps 16")
	assert(((armed_anims.get("attack_side", {}) as Dictionary).get("frames", []) as Array).size() >= 8, "armed attack has a multi-frame slash")
	var armed_attack_n: int = ((armed_anims.get("attack_side", {}) as Dictionary).get("frames", []) as Array).size()
	var armed_combo: Array = hero.get("_combo_end")
	assert(int(armed_combo[0]) == armed_attack_n - 1, "armed slash plays every attack frame")
	assert(int(hero.get("_followup_start")) == 0, "armed follow-up replays the slash from the start")
	assert(((armed_anims.get("run_front", {}) as Dictionary).get("frames", []) as Array).size() >= 4, "armed run front is a walk cycle")
	hero.apply_hero_kind(&"ember_hero")
	await process_frame
	var default_combo: Array = hero.get("_combo_end")
	assert(int(default_combo[0]) == 6 and int(default_combo[1]) == 19, "default knight keeps the two-hit strip windows")
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	await process_frame
	hero.hub_hide_weapon = true
	hero.call("_apply_view_from_move", Vector2(0.0, 1.0))
	assert(hero.get("_view") == &"front", "home walker can face south")
	assert(hero._clip_name(&"idle") == "idle_front")
	hero.call("_apply_view_from_move", Vector2(0.0, -1.0))
	assert(hero._clip_name(&"idle") == "idle_back")
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	assert(hero.visual_pack_id == &"frost_warrior", "home walker never keeps the armed form")
	hero.queue_free()
	print("HERO PACK RUNTIME PASS")
	quit()

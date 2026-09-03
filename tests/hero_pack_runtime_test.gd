extends SceneTree

const EmberHero := preload("res://scripts/hero.gd")
const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")


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
	assert(HeroPackSpec.clip_name("idle", "assassin", "three", "front") == "idle_front")
	hero.apply_hero_kind(&"ember_hero", &"frost_warrior")
	await process_frame
	assert(hero.visual_pack_id == &"frost_warrior")
	assert(hero.get("_view_mode") == "three")
	assert(hero.get("_view") == &"side")
	assert(hero._clip_name(&"idle") == "idle_side", "combat frost stays on side")
	assert(hero._clip_name(&"dash") == "skill_cast_side", "frost skill uses skill_cast")
	var frost_actor := hero.get_node_or_null("XSXBHeroActor")
	assert(frost_actor != null)
	assert(float(frost_actor.call("animation_duration", "skill_cast_side")) >= 0.70, "frost skill_cast should last through the burst")
	hero.call("_apply_view_from_move", Vector2(0.0, 1.0))
	assert(hero.get("_view") == &"side", "combat ignores south view")
	assert(hero._clip_name(&"run") == "run_side")
	hero.call("_apply_view_from_move", Vector2(0.0, -1.0))
	assert(hero._clip_name(&"jump") == "jump_side", "combat jump stays side")
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	await process_frame
	assert(hero.visual_pack_id == &"frost_armed")
	assert(hero.get("_view_mode") == "three")
	assert(hero._clip_name(&"idle") == "idle_side")
	assert(hero._clip_name(&"dash") == "skill_cast_side", "armed frost skill uses skill_cast")
	assert(hero.call("_hides_held_overlay") == true, "baked greatsword hides hold overlay")
	var armed_actor := hero.get_node_or_null("XSXBHeroActor")
	assert(armed_actor != null)
	assert(str(armed_actor.get("frame_profile_id")) == "frost_armed")
	assert(float(armed_actor.call("animation_duration", "skill_cast_side")) >= 0.70, "armed skill_cast should last through the burst")
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
	hero.queue_free()
	print("HERO PACK RUNTIME PASS")
	quit()

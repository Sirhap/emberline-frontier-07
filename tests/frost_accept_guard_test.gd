extends SceneTree

const EmberHero := preload("res://scripts/hero.gd")


func _init() -> void:
	create_timer(20.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


## Skill commit (T1.2) keeps the hero and core alive for the 3s capture window.
func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.debug_god = false
	hero.call("_commit_hero_kind", &"ember_hero", &"frost_warrior", true)
	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	hero.position = Vector2(640.0, 336.0)
	hero.request_dash()
	assert(bool(hero.get("_transforming")), "frost skill starts transform")
	assert(bool(scene.call("is_frost_accept_guarded")), "transform-in already holds wave pressure")
	hero.call("_update_dash", EmberHero.SKILL_INPUT_LOCK_CAP + 0.05)
	assert(hero.visual_pack_id == &"frost_armed", "armed pack commits at the 1.2s unlock")
	assert(bool(hero.call("is_frost_accept_guarded")), "T1.2 opens the 3s accept guard")
	var hp_before := hero.health
	var core_before: int = int(scene.get("core_health"))
	hero.set("_hit_invuln", 0.0)
	hero.set("_dash_invuln", 0.0)
	hero.take_damage(999)
	assert(hero.health == hp_before, "hero stays alive through the 3s window")
	assert(not hero.is_down)
	var leaker := FrontierEnemy.new()
	leaker.variant = &"scout"
	leaker.max_health = 80
	leaker.core_damage = 1
	leaker.configure_seek(scene.call("core_goal") as Vector2, scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", leaker)
	await process_frame
	leaker.global_position = scene.call("core_goal") as Vector2
	leaker.set("_aggro", false)
	leaker.call("_follow_seek", 40.0)
	assert(leaker.is_active(), "leak hold keeps the enemy on the field")
	assert(int(scene.get("core_health")) == core_before, "core stays up during the 3s window")
	hero.call("_tick_frost_accept_guard", EmberHero.FROST_ACCEPT_GUARD + 0.05)
	assert(not bool(hero.call("is_frost_accept_guarded")), "guard expires after 3s")
	leaker.call("_follow_seek", 40.0)
	assert(int(scene.get("core_health")) < core_before, "core leak resumes after the capture window")
	scene.queue_free()
	await process_frame
	print("FROST ACCEPT GUARD PASS")
	quit()

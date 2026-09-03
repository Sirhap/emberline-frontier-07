extends SceneTree


func _init() -> void:
	create_timer(15.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


## Verifies that the battlefield contact path consumes armor before health.
func _run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.debug_god = false
	hero.set("_hit_invuln", 0.0)
	hero.set("_dash_invuln", 0.0)
	var hp_before_contact := hero.health
	hero.armor = 1
	hero.armor_max = 1
	scene.call("_sync_hero_armor_hud")
	var contact_probe := FrontierEnemy.new()
	contact_probe.variant = &"scout"
	contact_probe.max_health = 9999
	contact_probe.move_speed = 0.0
	contact_probe.contact_damage = 8
	contact_probe.configure_seek(hero.global_position, scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", contact_probe)
	await process_frame
	contact_probe.global_position = hero.global_position
	contact_probe.set("_aggro", true)
	contact_probe.play_attack(Vector2.LEFT)
	contact_probe.set("_attack_index", 2)
	scene.call("_process_hero_contact", 0.016)
	assert(hero.armor == 0, "contact hits consume the hero's armor charge")
	assert(int(scene.get("_hero_armor")) == 0, "contact hits consume one armor charge")
	assert(hero.health == hp_before_contact, "fully absorbed contact damage preserves health")
	scene.queue_free()
	await process_frame
	print("HERO CONTACT DAMAGE PASS")
	quit()

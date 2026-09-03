extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	hero.position = Vector2(640.0, 336.0)
	_snap(cam, hero)
	await process_frame
	await process_frame
	_save("res://dogfood-output/screenshots/fix-hud.png")

	var scout := FrontierEnemy.new()
	scout.variant = &"scout"
	scout.max_health = 9999
	scout.move_speed = 0.0
	scout.configure_seek(Vector2(720.0, 336.0), scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", scout)
	await process_frame
	await process_frame
	_save("res://dogfood-output/screenshots/fix-scale.png")

	scene.call("_play_attack")
	await create_timer(0.08).timeout
	_save("res://dogfood-output/screenshots/fix-sword-080ms.png")
	await create_timer(0.12).timeout
	_save("res://dogfood-output/screenshots/fix-sword-200ms.png")
	await create_timer(0.50).timeout

	scout.play_attack(Vector2.LEFT)
	await process_frame
	_save("res://dogfood-output/screenshots/fix-enemy-windup.png")
	await create_timer(0.22).timeout
	_save("res://dogfood-output/screenshots/fix-enemy-hit.png")
	scout.take_damage(99999, &"hero")
	await create_timer(0.16).timeout
	_save("res://dogfood-output/screenshots/fix-enemy-death.png")

	scene.call("_spawn_home_rewards")
	hero.position = Vector2(252.0, 200.0)
	_snap(cam, hero)
	await process_frame
	await process_frame
	_save("res://dogfood-output/screenshots/fix-rewards.png")

	hero.position = Vector2(320.0, -90.0)
	_snap(cam, hero)
	scene.call("_open_talk", &"merchant")
	await process_frame
	await process_frame
	_save("res://dogfood-output/screenshots/fix-shop.png")

	hero.apply_hero_kind(&"assassin")
	hero.position = Vector2(640.0, 336.0)
	_snap(cam, hero)
	await process_frame
	_save("res://dogfood-output/screenshots/fix-assassin-idle-0.png")
	await create_timer(0.85).timeout
	_save("res://dogfood-output/screenshots/fix-assassin-idle-1s.png")
	hero.down_duration = 2.0
	hero.take_damage(999)
	await create_timer(0.40).timeout
	_save("res://dogfood-output/screenshots/fix-assassin-down.png")
	await create_timer(2.0).timeout
	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	hero.request_dash()
	await create_timer(0.20).timeout
	_save("res://dogfood-output/screenshots/fix-assassin-clones.png")
	print("DOGFOOD_FIX_CAPTURE ok")
	quit()


func _snap(cam: Camera2D, hero: Node2D) -> void:
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(path)
	print(path)

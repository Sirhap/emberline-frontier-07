extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	scene.call("_toggle_dev_mode")
	scene.call("_dev_place_pulses")
	scene.call("_spawn_home_rewards")

	hero.position = Vector2(640.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-dev-field.png")

	hero.position = Vector2(320.0, -110.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-dev-merchant.png")

	hero.position = Vector2(800.0, -110.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-dev-trainer.png")

	hero.position = Vector2(40.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-dev-hall.png")

	hero.position = Vector2(640.0, 336.0)
	_snap_cam(cam, hero)
	scene.call("start_wave")
	scene.call("_dev_spawn", &"scout")
	await create_timer(0.35).timeout
	_save("res://tools/look-dev-combat.png")
	print("DEV_CAPTURE ok")
	quit()


func _snap_cam(cam: Camera2D, hero: Node2D) -> void:
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

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
	_snap_cam(cam, hero)
	scene.call("_toggle_dev_mode")
	await process_frame
	await process_frame
	_save("res://tools/look-dev-knight.png")

	scene.call("_dev_toggle_hero")
	hero.position = Vector2(640.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-dev-assassin.png")

	hero.select_weapon_slot(0)
	hero.set("_aim_dir", Vector2.RIGHT)
	hero.call("_apply_facing", 1)
	hero.request_attack()
	await scene.get_tree().create_timer(0.22).timeout
	_snap_cam(cam, hero)
	_save("res://tools/look-dev-assassin-attack.png")
	await scene.get_tree().create_timer(0.55).timeout

	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	hero.request_dash()
	await scene.get_tree().create_timer(0.38).timeout
	_snap_cam(cam, hero)
	_save("res://tools/look-dev-assassin-skill.png")

	print("DEV_HERO_QA ok")
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

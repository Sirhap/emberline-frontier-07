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
	await process_frame
	await process_frame
	_save("res://tools/look-qa-field.png")

	hero.position = Vector2(2100.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-east.png")

	hero.position = Vector2(1413.0, -200.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-ne-road.png")

	hero.position = Vector2(1600.0, 1100.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-se-road.png")

	hero.position = Vector2(1413.0, -480.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-portal-north.png")

	hero.position = Vector2(1413.0, 1320.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-portal-south.png")

	hero.position = Vector2(2100.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-portal-east.png")

	hero.position = Vector2(1413.0, 100.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-north-mouth.png")

	hero.position = Vector2(1413.0, 580.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-south-mouth.png")

	hero.position = Vector2(640.0, 600.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-south.png")

	hero.position = Vector2(568.0, 40.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-door.png")

	hero.position = Vector2(250.0, -90.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-merchant.png")

	hero.position = Vector2(320.0, -110.0)
	assert(bool(scene.call("try_talk_to_nearby_npc")), "Merchant capture requires an open stall")
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-shop-open.png")
	scene.call("_close_talk")

	hero.position = Vector2(730.0, -90.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-trainer.png")

	hero.position = Vector2(40.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-hall.png")

	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", -1)
	hero.call("_update_held_weapon")
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-sword-left.png")

	hero.position = Vector2(640.0, 336.0)
	_snap_cam(cam, hero)
	scene.call("_toggle_dev_mode")
	scene.call("_dev_fill_pads")
	await process_frame
	await process_frame
	_save("res://tools/look-qa-dev.png")

	var core: Vector2 = scene.call("core_goal") as Vector2
	var wall_boss := FrontierEnemy.new()
	wall_boss.variant = &"boss"
	wall_boss.z_index = 3
	wall_boss.configure_seek(Vector2(800.0, 80.0), core, scene)
	scene.add_child(wall_boss)
	await process_frame
	await process_frame
	wall_boss.global_position = scene.call("clamp_enemy_position", wall_boss.global_position, wall_boss.global_position, wall_boss) as Vector2
	hero.position = Vector2(800.0, 200.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-boss-wall.png")
	wall_boss.queue_free()

	var north_boss := FrontierEnemy.new()
	north_boss.variant = &"boss"
	north_boss.z_index = 3
	north_boss.configure_seek(Vector2(1308.0, -180.0), core, scene)
	scene.add_child(north_boss)
	await process_frame
	await process_frame
	north_boss.global_position = scene.call("clamp_enemy_position", north_boss.global_position, north_boss.global_position, north_boss) as Vector2
	hero.position = Vector2(1413.0, -120.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-boss-north.png")
	north_boss.queue_free()

	var east_mage := FrontierEnemy.new()
	east_mage.variant = &"mage"
	east_mage.z_index = 3
	east_mage.configure_seek(Vector2(2100.0, 230.0), core, scene)
	scene.add_child(east_mage)
	await process_frame
	await process_frame
	east_mage.global_position = scene.call("clamp_enemy_position", east_mage.global_position, east_mage.global_position, east_mage) as Vector2
	hero.position = Vector2(2000.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-mage-east.png")
	east_mage.queue_free()

	hero.apply_hero_kind(&"assassin")
	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	hero.position = Vector2(640.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-assassin.png")
	hero.request_dash()
	await scene.get_tree().create_timer(0.38).timeout
	_snap_cam(cam, hero)
	_save("res://tools/look-qa-assassin-skill.png")
	await scene.get_tree().create_timer(0.12).timeout
	_save("res://tools/look-qa-assassin-clones.png")

	print("LOOK_QA ok")
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

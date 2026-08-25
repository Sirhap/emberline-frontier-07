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

	hero.position = Vector2(2100.0, 400.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-east.png")

	hero.position = Vector2(2100.0, -200.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-ne-road.png")

	hero.position = Vector2(1600.0, 1100.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-se-road.png")

	hero.position = Vector2(1520.0, -520.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-portal-north.png")

	hero.position = Vector2(1840.0, 1484.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-portal-south.png")

	hero.position = Vector2(2344.0, 328.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-portal-east.png")

	hero.position = Vector2(1320.0, 120.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-qa-north-mouth.png")

	hero.position = Vector2(1320.0, 520.0)
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
	_snap_cam(cam, hero)
	scene.call("_toggle_dev_mode")
	scene.call("_dev_fill_pads")
	await process_frame
	await process_frame
	_save("res://tools/look-qa-dev.png")
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

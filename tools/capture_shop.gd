extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _snap(cam: Camera2D, hero: Node2D) -> void:
	if cam != null and hero != null:
		cam.position_smoothing_enabled = false
		cam.global_position = cam.get_parent().call("camera_target_for", hero.global_position)
		cam.zoom = cam.get_parent().call("camera_zoom_for", hero.global_position)

func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SHOP_SHOT %s err=%s size=%sx%s" % [path, err, image.get_width(), image.get_height()])

func _capture() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: Node2D = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	_snap(cam, hero)
	await process_frame

	hero.position = Vector2(568.0, 250.0)
	_snap(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/shop_shot_approach.png")

	hero.position = Vector2(320.0, -80.0)
	_snap(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/shop_shot_merchant.png")

	hero.position = Vector2(560.0, -90.0)
	_snap(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/shop_shot.png")

	hero.position = Vector2(800.0, -80.0)
	_snap(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/shop_shot_trainer.png")
	quit()

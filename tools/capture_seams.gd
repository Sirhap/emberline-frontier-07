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
	var shop: EmberShop = scene.get("_shop")
	hero.add_turret(&"frost")
	hero.turret_hand = true

	# South overlay seam (old y=540 cut through the original room).
	hero.position = Vector2(720.0, 540.0)
	scene.set("_place_preview_world", Vector2(720.0, 560.0))
	scene.call("_sync_place_preview")
	_snap(cam, scene, hero.position)
	await _save("res://tools/look-qa-seam-south.png")

	# East painting edge x=1280.
	hero.position = Vector2(1240.0, 336.0)
	scene.set("_place_preview_world", Vector2(1260.0, 360.0))
	scene.call("_sync_place_preview")
	_snap(cam, scene, hero.position)
	await _save("res://tools/look-qa-seam-east.png")

	# Shop door / north threshold.
	hero.position = Vector2(568.0, 40.0)
	scene.set("_place_preview_world", Vector2(INF, INF))
	scene.call("_sync_place_preview")
	_snap(cam, scene, hero.position)
	await _save("res://tools/look-qa-seam-door.png")

	# South mouth into the corridor.
	hero.position = Vector2(1413.0, 640.0)
	_snap(cam, scene, hero.position)
	await _save("res://tools/look-qa-seam-south-mouth.png")

	print("SEAM_QA ok")
	quit()


func _snap(cam: Camera2D, scene: Node, world: Vector2) -> void:
	if cam == null:
		return
	cam.zoom = Vector2.ONE
	cam.global_position = scene.call("camera_target_for", world)
	cam.reset_smoothing()
	cam.force_update_scroll()


func _save(path: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

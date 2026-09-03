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
	var shop: EmberShop = scene.get("_shop")
	if cam != null:
		cam.position_smoothing_enabled = false
	hero.position = Vector2(640.0, 400.0)
	hero.add_turret(&"frost")
	hero.turret_hand = true
	scene.set("_place_preview_world", Vector2(720.0, 400.0))
	scene.call("_sync_place_preview")
	_snap_cam(cam, scene, Vector2(640.0, 400.0))
	await process_frame
	await process_frame
	_snap_cam(cam, scene, Vector2(640.0, 400.0))
	RenderingServer.force_draw()
	await process_frame
	var cell: Vector2i = scene.call("_cell_at", Vector2(720.0, 400.0))
	var rect: Rect2 = scene.call("_cell_rect", cell)
	print("CELL %s RECT %s ZOOM %s" % [cell, rect, cam.zoom if cam else Vector2.ONE])
	_save("res://tools/look-qa-tile-align.png")
	print("TILE_ALIGN_QA ok")
	quit()


func _snap_cam(cam: Camera2D, scene: Node, world: Vector2) -> void:
	if cam == null:
		return
	cam.zoom = scene.call("camera_zoom_for", world)
	cam.global_position = scene.call("camera_target_for", world)
	cam.reset_smoothing()
	cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s size=%sx%s" % [path, err, image.get_width(), image.get_height()])

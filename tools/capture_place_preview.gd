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

	# Front battlefield, prep, nothing held, hover a buildable mid tile.
	hero.position = Vector2(640.0, 336.0)
	hero.turret_hand = false
	scene.set("_place_preview_world", Vector2(720.0, 360.0))
	scene.call("_sync_place_preview")
	_snap_cam(cam, Vector2(640.0, 336.0))
	await process_frame
	await process_frame
	_save("res://tools/look-qa-place-front-idle.png")

	# Same hover near the core dais (should stay empty even if holding later).
	scene.set("_place_preview_world", Vector2(188.0, 263.0))
	scene.call("_sync_place_preview")
	_snap_cam(cam, Vector2(280.0, 280.0))
	await process_frame
	await process_frame
	_save("res://tools/look-qa-place-front-core.png")

	# Front, holding a pulse: gold cell + tower ghost on a buildable tile.
	hero.add_turret(&"pulse")
	hero.turret_hand = true
	scene.set("_place_preview_world", Vector2(720.0, 360.0))
	scene.call("_sync_place_preview")
	_snap_cam(cam, Vector2(640.0, 336.0))
	await process_frame
	await process_frame
	_save("res://tools/look-qa-place-front-ghost.png")

	# Bottom of the original room (south expand overlay).
	scene.set("_place_preview_world", Vector2(640.0, 580.0))
	scene.call("_sync_place_preview")
	_snap_cam(cam, Vector2(640.0, 560.0))
	await process_frame
	await process_frame
	_save("res://tools/look-qa-place-front-south.png")

	# East expansion, prep, nothing held.
	hero.turret_hand = false
	hero.position = Vector2(1480.0, 336.0)
	scene.set("_place_preview_world", Vector2(1480.0, 360.0))
	scene.call("_sync_place_preview")
	_snap_cam(cam, Vector2(1480.0, 336.0))
	await process_frame
	await process_frame
	_save("res://tools/look-qa-place-east-idle.png")

	# East expansion, holding a pulse.
	hero.turret_hand = true
	scene.call("_sync_place_preview")
	await process_frame
	await process_frame
	_save("res://tools/look-qa-place-east-ghost.png")
	var ghost := scene.find_child("PlaceGhost", true, false) as Sprite2D
	var fill := scene.find_child("PlaceFill", true, false) as Polygon2D
	print("GHOST vis=%s tex=%s pos=%s" % [ghost.visible if ghost else false, ghost.texture.resource_path if ghost and ghost.texture else "", ghost.position if ghost else Vector2.ZERO])
	print("FILL vis=%s" % [fill.visible if fill else false])

	print("PLACE_PREVIEW_QA ok")
	quit()


func _snap_cam(cam: Camera2D, world: Vector2) -> void:
	if cam != null:
		cam.global_position = world
		cam.reset_smoothing()
		cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

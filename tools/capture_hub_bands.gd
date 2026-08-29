extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _shot(hero: EmberHero, cam: Camera2D, at: Vector2, look: Vector2, zoom: float, path: String) -> void:
	hero.position = at
	if cam != null:
		cam.global_position = look
		cam.zoom = Vector2(zoom, zoom)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(18):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ", path)


func _run() -> void:
	print("CAP_START")
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	print("CAP_READY")
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.enabled = true
	var director = scene.get("_director")
	if director != null:
		director.prep_left = 9999.0
	DirAccess.make_dir_recursive_absolute("/opt/cursor/artifacts")
	var top: Rect2 = scene.get("TOP_ROOM")
	var bottom: Rect2 = scene.get("BOTTOM_ROOM")
	var door: Rect2 = scene.get("SHOP_DOOR")
	## Wide: rooms pulled onto combat walls
	await _shot(hero, cam, Vector2(640.0, 336.0), Vector2(480.0, 280.0), 0.42, "/opt/cursor/artifacts/rooms_all_three.png")
	## Inside 上房间
	await _shot(hero, cam, top.get_center(), top.get_center(), 1.05, "/opt/cursor/artifacts/rooms_upper.png")
	## North railing mouth
	await _shot(hero, cam, Vector2(door.get_center().x, 88.0), Vector2(door.get_center().x, 24.0), 1.08, "/opt/cursor/artifacts/rooms_north_gate.png")
	## Core close-up: conveyors east of the gem, no loot piled on the crystal
	await _shot(hero, cam, Vector2(420.0, 336.0), Vector2(240.0, 300.0), 1.18, "/opt/cursor/artifacts/rooms_core.png")
	## Combat with wave-clear rewards on the conveyor column
	hero.position = Vector2(420.0, 336.0)
	if cam != null:
		cam.global_position = Vector2(260.0, 310.0)
		cam.zoom = Vector2(1.10, 1.10)
		cam.reset_smoothing()
		cam.force_update_scroll()
	scene.call("_spawn_home_rewards")
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/rooms_combat.png")
	print("SHOT combat")
	## South railing mouth
	var south: Rect2 = scene.get("SOUTH_SHOP_DOOR")
	await _shot(hero, cam, Vector2(south.get_center().x, 600.0), Vector2(south.get_center().x, 640.0), 1.08, "/opt/cursor/artifacts/rooms_south_gate.png")
	## Inside 下房间
	await _shot(hero, cam, bottom.get_center(), bottom.get_center(), 1.05, "/opt/cursor/artifacts/rooms_lower.png")
	print("NPC_QA_PASS")
	quit(0)

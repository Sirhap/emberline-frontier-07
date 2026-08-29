extends SceneTree

func _init() -> void:
	call_deferred("_run")


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
	## Three rooms in one shot
	hero.position = Vector2(400.0, 70.0)
	if cam != null:
		cam.global_position = Vector2(480.0, 280.0)
		cam.zoom = Vector2(0.70, 0.70)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(24):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/sk_three_rooms.png")
	print("SHOT three")
	## 上房间
	hero.position = Vector2(400.0, 70.0)
	if cam != null:
		cam.global_position = Vector2(400.0, 40.0)
		cam.zoom = Vector2(1.12, 1.12)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/sk_upper_room.png")
	print("SHOT upper")
	## 下房间
	hero.position = Vector2(480.0, 560.0)
	if cam != null:
		cam.global_position = Vector2(480.0, 560.0)
		cam.zoom = Vector2(1.12, 1.12)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/sk_lower_room.png")
	print("SHOT lower")
	## Mid + core
	hero.position = Vector2(280.0, 330.0)
	if cam != null:
		cam.global_position = Vector2(280.0, 330.0)
		cam.zoom = Vector2(1.08, 1.08)
		cam.reset_smoothing()
		cam.force_update_scroll()
	scene.call("_spawn_home_rewards")
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/sk_mid_corridor.png")
	print("SHOT mid")
	print("NPC_QA_PASS")
	quit(0)

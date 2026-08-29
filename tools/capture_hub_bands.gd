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
	## Full combat room: 上厅 / 战斗过道 / 下厅
	hero.position = Vector2(640.0, 336.0)
	if cam != null:
		cam.global_position = Vector2(520.0, 336.0)
		cam.zoom = Vector2(0.82, 0.82)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(24):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_sk_full.png")
	print("SHOT full")
	## Top hall
	hero.position = Vector2(400.0, 120.0)
	if cam != null:
		cam.global_position = Vector2(400.0, 140.0)
		cam.zoom = Vector2(1.15, 1.15)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_sk_top.png")
	print("SHOT top")
	## Mid corridor + core
	hero.position = Vector2(280.0, 320.0)
	if cam != null:
		cam.global_position = Vector2(280.0, 320.0)
		cam.zoom = Vector2(1.1, 1.1)
		cam.reset_smoothing()
		cam.force_update_scroll()
	scene.call("_spawn_home_rewards")
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_core_conveyors.png")
	print("SHOT mid")
	## Bottom hall
	hero.position = Vector2(480.0, 560.0)
	if cam != null:
		cam.global_position = Vector2(480.0, 560.0)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_sk_bottom.png")
	print("SHOT bottom")
	print("NPC_QA_PASS")
	quit(0)

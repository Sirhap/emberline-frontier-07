extends SceneTree

const OUT := "res://dogfood-output/qa"

func _init() -> void:
	call_deferred("_capture")

func _snap(scene: Node, hero: Node2D) -> void:
	var cam: Camera2D = scene.get("_camera")
	if cam != null and hero != null:
		cam.position_smoothing_enabled = false
		cam.global_position = scene.call("camera_target_for", hero.global_position)
		cam.zoom = scene.call("camera_zoom_for", hero.global_position)
		cam.reset_smoothing()
		cam.force_update_scroll()

func _save(shot_name: String) -> void:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT, shot_name]
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("QA_SHOT %s err=no-texture" % path)
		return
	var image := tex.get_image()
	if image == null:
		print("QA_SHOT %s err=no-image" % path)
		return
	var err := image.save_png(path)
	print("QA_SHOT %s err=%s %sx%s" % [path, err, image.get_width(), image.get_height()])

func _dump_merchant(scene: Node, tag: String) -> void:
	var npc: Sprite2D = scene.get("_npc_merchant")
	var keepers = scene.get("_npc_keepers")
	var keeper_n := 0
	if keepers is Array:
		keeper_n = (keepers as Array).size()
	if npc == null:
		print("QA_NPC %s missing keepers=%s" % [tag, keeper_n])
		return
	var idle: Array = npc.get_meta("idle_frames", [])
	var restock: Array = npc.get_meta("restock_frames", [])
	print("QA_NPC %s name=%s pos=%s rest=%s clip=%s job=%s shelf=%s route=%s idle=%s restock=%s keepers=%s flip=%s" % [
		tag,
		npc.name,
		npc.position,
		npc.get_meta("rest_pos", Vector2.ZERO),
		npc.get_meta("clip", &""),
		scene.get("_npc_job"),
		scene.get("_npc_job_shelf"),
		scene.get("_npc_route_i"),
		idle.size(),
		restock.size(),
		keeper_n,
		npc.flip_h,
	])

func _wait_frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	Engine.max_fps = 60
	if ClassDB.class_exists("EmberRunSave") or true:
		EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await _wait_frames(8)
	await RenderingServer.frame_post_draw
	var hero: Node2D = scene.get("_hero")
	if hero == null:
		hero = scene.get_node_or_null("HeroSlot/HeroController")
	if hero == null:
		push_error("no hero")
		quit()
		return
	hero.position = Vector2(560.0, -90.0)
	_snap(scene, hero)
	await _wait_frames(4)
	_dump_merchant(scene, "boot")

	# Wait out the prep restock at crate 0, then stand on the route.
	var hall_ready := false
	for _i in range(90):
		await process_frame
		var job: StringName = scene.get("_npc_job")
		var npc: Sprite2D = scene.get("_npc_merchant")
		if npc != null and job == &"route":
			hall_ready = true
			break
	_snap(scene, hero)
	_dump_merchant(scene, "hall")
	await _save("keepers-hall")
	print("QA_HALL_READY %s" % hall_ready)

	# Wait until he is clearly between crates (not hugging one).
	var run_ready := false
	for _i in range(240):
		await process_frame
		var npc2: Sprite2D = scene.get("_npc_merchant")
		if npc2 == null:
			continue
		var rest: Vector2 = npc2.get_meta("rest_pos", npc2.position)
		var nearest := 9999.0
		for shelf: Vector2 in [Vector2(200, -70), Vector2(320, -70), Vector2(440, -70), Vector2(740, -70), Vector2(880, -70)]:
			nearest = minf(nearest, rest.distance_to(shelf + Vector2(0, -42)))
		if scene.get("_npc_job") == &"route" and int(scene.get("_npc_route_i")) >= 1 and rest.x >= 300.0:
			run_ready = true
			break
	_snap(scene, hero)
	_dump_merchant(scene, "run")
	await _save("keepers-run")
	print("QA_RUN_READY %s" % run_ready)

	scene.call("buy_shop_slot", 0)
	var restock_ready := false
	for _i in range(180):
		await process_frame
		var npc3: Sprite2D = scene.get("_npc_merchant")
		if npc3 != null and npc3.get_meta("clip", &"idle") == &"restock":
			restock_ready = true
			# ~0.25s into 10fps clip => frame 2
			await _wait_frames(16)
			break
	_snap(scene, hero)
	_dump_merchant(scene, "restock")
	await _save("keepers-restock")
	print("QA_RESTOCK_READY %s" % restock_ready)
	print("QA_SHOTS_DONE")
	quit()

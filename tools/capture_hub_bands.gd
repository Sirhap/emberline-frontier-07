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
	var mer = scene.find_child("NpcMerchant", true, false)
	var mech = scene.find_child("NpcMechanic", true, false)
	var off = scene.find_child("NpcOfficer", true, false)
	var trn = scene.find_child("NpcTrainer", true, false)
	var sum = scene.find_child("NpcSummoner", true, false)
	print("NPCS m=%s mech=%s o=%s t=%s s=%s" % [mer != null, mech != null, off != null, trn != null, sum != null])
	assert(mer != null and mech != null and off != null and trn != null and sum != null, "five NPCs")
	assert(String(trn.get_meta("npc_folder", "")) == "mentor", "mentor folder")
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.enabled = true
		cam.zoom = Vector2(1.05, 1.05)
	var director = scene.get("_director")
	if director != null:
		director.prep_left = 9999.0
	DirAccess.make_dir_recursive_absolute("/opt/cursor/artifacts")
	DirAccess.make_dir_recursive_absolute("/workspace/emberline-qa/npc")
	hero.position = Vector2(540.0, -120.0)
	if cam != null:
		cam.global_position = Vector2(540.0, -150.0)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(20):
		await process_frame
	DirAccess.make_dir_recursive_absolute("/opt/cursor/artifacts")
	DirAccess.make_dir_recursive_absolute("/workspace/emberline-qa/npc")
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/hub_shop_hall_player.png")
	img.save_png("/workspace/emberline-qa/npc/shop-hall-five-npcs.png")
	print("SHOT hall")
	if cam != null:
		cam.global_position = Vector2(480.0, -220.0)
		cam.zoom = Vector2(1.25, 1.25)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_top_band.png")
	print("SHOT top")
	if cam != null:
		cam.global_position = Vector2(480.0, -70.0)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_bottom_band.png")
	print("SHOT bottom")
	hero.position = Vector2(280.0, 320.0)
	if cam != null:
		cam.global_position = Vector2(280.0, 320.0)
		cam.zoom = Vector2(1.15, 1.15)
		cam.reset_smoothing()
		cam.force_update_scroll()
	scene.call("_spawn_home_rewards")
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_core_conveyors.png")
	print("SHOT conveyors")
	print("NPC_QA_PASS")
	quit(0)

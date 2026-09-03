extends SceneTree

## Capture shop hall with five SK-style NPCs and two-band pedestals.
const OUT := "res://dogfood-output/qa/npc"
const ARTIFACTS := "res://dogfood-output/qa"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ARTIFACTS))
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.enabled = true
		cam.zoom = Vector2(1.05, 1.05)
	var director = scene.get("_director")
	if director != null:
		director.prep_left = 9999.0

	var merchant: Sprite2D = scene.get("_npc_merchant")
	var trainer: Sprite2D = scene.get("_npc_trainer")
	var summoner: Sprite2D = scene.get("_npc_summoner")
	var mechanic: Sprite2D = scene.get("_npc_mechanic")
	var officer: Sprite2D = scene.get("_npc_officer")
	assert(merchant != null and trainer != null and summoner != null, "core three NPCs")
	assert(mechanic != null and officer != null, "mechanic + officer")
	assert(String(merchant.get_meta("npc_folder", "")) == "merchant", "merchant folder")
	assert(String(trainer.get_meta("npc_folder", "")) == "mentor", "trainer uses mentor folder")
	assert(String(summoner.get_meta("npc_folder", "")) == "summoner", "summoner folder")
	assert(String(mechanic.get_meta("npc_folder", "")) == "mechanic", "mechanic folder")
	assert(String(officer.get_meta("npc_folder", "")) == "officer", "officer folder")
	print("NPC_FOLDERS merchant=%s mentor=%s summoner=%s mechanic=%s officer=%s" % [
		merchant.get_meta("npc_folder", ""),
		trainer.get_meta("npc_folder", ""),
		summoner.get_meta("npc_folder", ""),
		mechanic.get_meta("npc_folder", ""),
		officer.get_meta("npc_folder", ""),
	])

	hero.position = Vector2(540.0, -120.0)
	if cam != null:
		cam.global_position = Vector2(540.0, -150.0)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(10):
		await process_frame
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/shop-hall-five-npcs.png" % OUT)
	root.get_viewport().get_texture().get_image().save_png("%s/hub_shop_hall_player.png" % ARTIFACTS)
	print("SHOT shop-hall-five-npcs")

	# Top band close-up
	if cam != null:
		cam.global_position = Vector2(480.0, -220.0)
		cam.zoom = Vector2(1.25, 1.25)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(8):
		await process_frame
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/hub_top_band.png" % ARTIFACTS)
	print("SHOT hub_top_band")

	# Bottom band
	if cam != null:
		cam.global_position = Vector2(480.0, -70.0)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(8):
		await process_frame
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/hub_bottom_band.png" % ARTIFACTS)
	print("SHOT hub_bottom_band")

	# Core conveyors
	hero.position = Vector2(280.0, 320.0)
	if cam != null:
		cam.global_position = Vector2(280.0, 320.0)
		cam.zoom = Vector2(1.15, 1.15)
		cam.reset_smoothing()
		cam.force_update_scroll()
	scene.call("_spawn_home_rewards")
	for _i in range(8):
		await process_frame
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/hub_core_conveyors.png" % ARTIFACTS)
	print("SHOT hub_core_conveyors")

	print("NPC_QA_PASS")
	quit(0)

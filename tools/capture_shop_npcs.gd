extends SceneTree

## Capture shop hall with three distinct NPCs (merchant / trainer / summoner).
const OUT := "/workspace/emberline-qa/npc"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(OUT)
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
		cam.zoom = Vector2(1.15, 1.15)
	var director = scene.get("_director")
	if director != null:
		director.prep_left = 9999.0

	var merchant: Sprite2D = scene.get("_npc_merchant")
	var trainer: Sprite2D = scene.get("_npc_trainer")
	var summoner: Sprite2D = scene.get("_npc_summoner")
	assert(merchant != null and trainer != null and summoner != null, "all three NPCs must exist")
	var mf := String(merchant.get_meta("npc_folder", ""))
	var tf := String(trainer.get_meta("npc_folder", ""))
	var sf := String(summoner.get_meta("npc_folder", ""))
	print("NPC_FOLDERS merchant=%s trainer=%s summoner=%s" % [mf, tf, sf])
	assert(mf == "merchant", "merchant folder")
	assert(tf == "trainer", "trainer folder")
	assert(sf == "summoner", "summoner must use its own anim folder, not trainer")
	var mtex: Texture2D = merchant.texture
	var ttex: Texture2D = trainer.texture
	var stex: Texture2D = summoner.texture
	assert(mtex != null and ttex != null and stex != null, "npc textures")
	# Distinct textures (summoner must not share trainer idle frame_00).
	assert(stex != ttex, "summoner texture must differ from trainer")
	var midle: Array = summoner.get_meta("idle_frames", [])
	var tidle: Array = trainer.get_meta("idle_frames", [])
	assert(midle.size() >= 4 and tidle.size() >= 4, "idle frame counts")
	assert(midle[0] != tidle[0], "summoner idle frames must not be trainer frames")
	var srest: Array = summoner.get_meta("restock_frames", [])
	assert(srest.size() >= 6, "summoner restock frames generated got=%d" % srest.size())

	hero.position = Vector2(540.0, -70.0)
	if cam != null:
		cam.global_position = Vector2(540.0, -140.0)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(8):
		await process_frame
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/shop-hall-three-npcs.png" % OUT)
	print("SHOT shop-hall-three-npcs")

	# Restock flash on summoner for a second shot
	scene.call("_start_npc_restock", summoner)
	for _i in range(12):
		await process_frame
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/summoner-restock.png" % OUT)
	print("SHOT summoner-restock")
	print("NPC_QA_PASS")
	quit(0)

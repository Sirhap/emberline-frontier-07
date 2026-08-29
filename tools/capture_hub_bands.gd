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
	## Merchant hall (north)
	hero.position = Vector2(480.0, -450.0)
	if cam != null:
		cam.global_position = Vector2(480.0, -470.0)
		cam.zoom = Vector2(1.15, 1.15)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(20):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_merchant_hall.png")
	print("SHOT merchant")
	## Door between halls
	hero.position = Vector2(520.0, -300.0)
	if cam != null:
		cam.global_position = Vector2(520.0, -300.0)
		cam.zoom = Vector2(1.05, 1.05)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_link_door.png")
	print("SHOT link")
	## Mentor hall (south)
	hero.position = Vector2(520.0, -160.0)
	if cam != null:
		cam.global_position = Vector2(520.0, -160.0)
		cam.zoom = Vector2(1.15, 1.15)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_mentor_hall.png")
	print("SHOT mentor")
	## Overview both rooms
	if cam != null:
		cam.global_position = Vector2(520.0, -300.0)
		cam.zoom = Vector2(0.72, 0.72)
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in range(16):
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/opt/cursor/artifacts/hub_two_rooms.png")
	print("SHOT overview")
	## Core conveyors
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
	print("NPC_QA_PASS")
	quit(0)

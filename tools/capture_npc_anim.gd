extends SceneTree

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: Node = scene.get("_hero")
	if hero != null:
		hero.position = Vector2(560.0, -40.0)
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.global_position = Vector2(560.0, -120.0)
		cam.zoom = Vector2(1.35, 1.35)
		cam.reset_smoothing()
	scene.call("_play_npc_restock", &"merchant")
	scene.call("_play_npc_restock", &"trainer")
	await create_timer(0.25).timeout
	var image := root.get_viewport().get_texture().get_image()
	var path := "res://tools/npc_anim_shot.png"
	var err := image.save_png(path)
	print("NPC_ANIM_SHOT %s err=%s size=%sx%s" % [path, err, image.get_width(), image.get_height()])
	quit()

extends SceneTree

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	hero.position = Vector2(640.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-talk-away.png")
	hero.position = Vector2(320.0, -110.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_save("res://tools/look-talk-near.png")
	scene.call("try_talk_to_nearby_npc")
	await process_frame
	await process_frame
	_save("res://tools/look-talk-merchant.png")
	hero.position = Vector2(800.0, -110.0)
	_snap_cam(cam, hero)
	scene.call("try_talk_to_nearby_npc")
	await process_frame
	await process_frame
	_save("res://tools/look-talk-trainer.png")
	scene.call("start_wave")
	await create_timer(0.12).timeout
	_save("res://tools/look-talk-combat.png")
	print("TALK_CAPTURE done")
	quit()


func _snap_cam(cam: Camera2D, hero: Node2D) -> void:
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

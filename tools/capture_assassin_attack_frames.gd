extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.apply_hero_kind(&"assassin")
	hero.position = Vector2(640.0, 400.0)
	hero.set("_aim_dir", Vector2.RIGHT)
	hero.call("_apply_facing", 1)
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()
	await process_frame
	var actor: Node = hero.find_child("XSXBHeroActor", true, false)
	assert(actor != null)
	actor.set_process(false)
	actor.set_physics_process(false)
	for clip: String in ["idle", "attack", "attack_b", "attack_c"]:
		actor.set("_current_animation", clip)
		var frames: Array = actor.get("_animations").get(clip, {}).get("frames", [])
		for index: int in range(frames.size()):
			actor.set("_current_frame", index)
			actor.call("_apply_frame_visual")
			await process_frame
			var owner: Node2D = actor.get_node_or_null("VisualOwner") as Node2D
			var tex: Texture2D = frames[index].get("texture") as Texture2D
			var tw := 0
			var th := 0
			if tex != null:
				tw = tex.get_width()
				th = tex.get_height()
			var oy := 0.0
			var ox := 0.0
			if owner != null:
				ox = owner.position.x
				oy = owner.position.y
			print("FRAME %s:%d tex=%dx%d owner=(%.2f, %.2f) actor_y=%.2f" % [clip, index, tw, th, ox, oy, actor.position.y])
			if cam != null:
				cam.global_position = hero.global_position
				cam.reset_smoothing()
				cam.force_update_scroll()
			await process_frame
			_save("res://tools/look-assassin-%s-%d.png" % [clip, index])
	print("ASSASSIN_ATTACK_FRAMES ok")
	quit()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

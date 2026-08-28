extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	# Keep the field quiet so idle is readable.
	if scene.has_method("set"):
		scene.set("_prep_left", 99.0)
	hero.position = Vector2(640.0, 336.0)

	hero.apply_hero_kind(&"ember_hero")
	hero.equip_weapon(&"sword")
	_pose(hero)
	await _settle(hero, cam)
	_print_clip("knight", hero)
	for i: int in range(6):
		await _shot("knight-idle-%02d" % i, hero, cam)
		await create_timer(0.125).timeout

	hero.apply_hero_kind(&"assassin")
	hero.equip_weapon(&"sword")
	_pose(hero)
	await _settle(hero, cam)
	_print_clip("assassin", hero)
	for i: int in range(6):
		await _shot("assassin-idle-%02d" % i, hero, cam)
		await create_timer(0.125).timeout

	print("IDLE_LOOP_CAPTURE done")
	quit()


func _pose(hero: EmberHero) -> void:
	hero.set("_move_input", Vector2.ZERO)
	hero.set("_aim_dir", Vector2.RIGHT)
	hero.call("_apply_facing", 1)
	hero.call("_refresh_held_weapon")
	if String(hero.current_state) != "idle":
		hero.call("_set_state", &"idle")


func _settle(hero: EmberHero, cam: Camera2D) -> void:
	_pose(hero)
	_aim(hero, cam)
	await process_frame
	await process_frame
	_aim(hero, cam)
	await RenderingServer.frame_post_draw


func _aim(hero: Node2D, cam: Camera2D) -> void:
	if cam == null:
		return
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(2.4, 2.4)
	cam.global_position = hero.global_position + Vector2(0.0, -18.0)
	cam.reset_smoothing()
	cam.force_update_scroll()


func _print_clip(tag: String, hero: EmberHero) -> void:
	var actor: Node = hero.get("_xsxb_actor")
	if actor == null:
		print("CLIP %s actor=null" % tag)
		return
	var anims: Dictionary = actor.get("_animations")
	var idle: Dictionary = anims.get("idle", {}) as Dictionary
	var frames: Array = idle.get("frames", []) as Array
	var names: Array[String] = []
	for frame_value: Variant in frames:
		if frame_value is Dictionary:
			names.append(str((frame_value as Dictionary).get("name", "")))
	print("CLIP %s kind=%s state=%s idle_n=%d idle_frames=[%s] playing=%s frame=%s" % [
		tag,
		String(hero.hero_kind),
		String(hero.current_state),
		names.size(),
		", ".join(names),
		str(actor.get("_current_animation")),
		str(actor.get("_current_frame")),
	])


func _shot(shot_name: String, hero: EmberHero, cam: Camera2D) -> void:
	_pose(hero)
	_aim(hero, cam)
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("SAVED %s err=no-texture" % shot_name)
		return
	var image := tex.get_image()
	if image == null:
		print("SAVED %s err=no-image" % shot_name)
		return
	var path := "/workspace/emberline-qa/%s.png" % shot_name
	var err := image.save_png(path)
	var actor: Node = hero.get("_xsxb_actor")
	print("SAVED %s err=%s size=%sx%s clip=%s frame=%s state=%s" % [
		path,
		err,
		image.get_width(),
		image.get_height(),
		str(actor.get("_current_animation")) if actor else "",
		str(actor.get("_current_frame")) if actor else "",
		String(hero.current_state),
	])

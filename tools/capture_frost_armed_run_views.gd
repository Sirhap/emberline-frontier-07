extends SceneTree

const OUT := "res://dogfood-output/frost-armed-visual"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _combat_run()
	await _home_runs()
	quit()


func _combat_run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.zoom = Vector2(1.7, 1.7)
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", 1)
	hero.set_demo_state(&"run")
	for i in 4:
		await scene.get_tree().create_timer(0.10).timeout
		_snap(cam, hero)
		_save_tex(hero, "20-combat-run-%d" % i)
		_save("20-combat-run-%d" % i)
	print("COMBAT_RUN pack=%s clip=%s frames=%s" % [
		String(hero.visual_pack_id),
		hero._clip_name(&"run"),
		_frame_count(hero, "run_side"),
	])
	scene.queue_free()
	await process_frame


func _home_runs() -> void:
	var hub := load("res://scenes/home/home_hub.tscn").instantiate() as Node2D
	root.add_child(hub)
	await process_frame
	await process_frame
	var walker := hub.find_child("HomeWalker", true, false) as EmberHero
	if walker == null:
		print("HOME_WALKER missing")
		return
	walker.hub_hide_weapon = true
	walker.apply_hero_kind(&"ember_hero", &"frost_armed")
	walker.position = Vector2(280, 559)
	var cam := hub.find_child("Camera2D", true, false) as Camera2D
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.zoom = Vector2(1.6, 1.6)
	var views := [
		["side", Vector2(1.0, 0.0)],
		["front", Vector2(0.0, 1.0)],
		["back", Vector2(0.0, -1.0)],
	]
	for row: Array in views:
		var name: String = row[0]
		var motion: Vector2 = row[1]
		walker.call("_apply_view_from_move", motion)
		walker.set_demo_state(&"run")
		await process_frame
		for i in 4:
			await hub.get_tree().create_timer(0.12).timeout
			_snap(cam, walker)
			_save_tex(walker, "21-home-run-%s-%d" % [name, i])
			_save("21-home-run-%s-%d" % [name, i])
		print("HOME_RUN view=%s clip=%s" % [str(walker.get("_view")), walker._clip_name(&"run")])
	hub.queue_free()
	await process_frame


func _frame_count(hero: EmberHero, clip: String) -> int:
	var actor: Node = hero.get("_xsxb_actor")
	if actor == null:
		return -1
	var anims: Variant = actor.get("animations")
	if anims == null:
		return -1
	return -1


func _snap(cam: Camera2D, hero: Node2D) -> void:
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()


func _save_tex(hero: EmberHero, name: String) -> void:
	var actor: Node = hero.get("_xsxb_actor")
	if actor == null:
		print("TEX %s missing actor" % name)
		return
	var sprite := actor.get_node_or_null("VisualOwner/FrameSprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		print("TEX %s missing sprite" % name)
		return
	var image: Image = sprite.texture.get_image()
	if image == null:
		print("TEX %s null image" % name)
		return
	var err := image.save_png("%s/%s-tex.png" % [OUT, name])
	print("TEX %s clip=%s frame=%s %sx%s err=%s" % [
		name,
		str(actor.get("_current_animation")),
		str(hero.call("_actor_frame")),
		image.get_width(),
		image.get_height(),
		err,
	])


func _save(name: String) -> void:
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("SAVED %s skip viewport" % name)
		return
	var image := tex.get_image()
	if image == null:
		print("SAVED %s skip image" % name)
		return
	var err := image.save_png("%s/%s.png" % [OUT, name])
	print("SAVED %s err=%s" % [name, err])

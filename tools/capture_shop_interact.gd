extends SceneTree

const OUT := "/workspace/emberline-qa"

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
	if scene.has_method("_sync_skill_hud"):
		scene.call("_sync_skill_hud")

func _btn_dump(scene: Node, state: String) -> void:
	var btn := scene.find_child("SkillButton", true, false) as Button
	if btn == null:
		print("QA_BTN state=%s missing" % state)
		return
	var icon_path := ""
	if btn.icon != null:
		icon_path = String(btn.icon.resource_path)
		if icon_path.is_empty():
			icon_path = "ImageTexture %sx%s" % [btn.icon.get_width(), btn.icon.get_height()]
	print("QA_BTN state=%s text='%s' icon=%s expand=%s modulate=%s" % [
		state, btn.text, icon_path, btn.expand_icon, btn.modulate
	])

func _save(shot_name: String) -> Image:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT, shot_name]
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("QA_SHOT %s err=no-texture" % path)
		return null
	var image := tex.get_image()
	if image == null:
		print("QA_SHOT %s err=no-image" % path)
		return null
	var err := image.save_png(path)
	print("QA_SHOT %s err=%s %sx%s" % [path, err, image.get_width(), image.get_height()])
	return image

func _save_crop(full: Image, button: Button, shot_name: String) -> void:
	if full == null or button == null:
		return
	var r := Rect2i(Vector2i(button.position), Vector2i(button.size))
	r = r.grow(4)
	r = r.intersection(Rect2i(0, 0, full.get_width(), full.get_height()))
	if r.size.x <= 0 or r.size.y <= 0:
		print("QA_CROP skip empty")
		return
	var crop := full.get_region(r)
	crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var path := "%s/%s.png" % [OUT, shot_name]
	var err := crop.save_png(path)
	print("QA_SHOT %s err=%s %sx%s" % [path, err, crop.get_width(), crop.get_height()])

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	Engine.max_fps = 60
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: Node2D = scene.get("_hero")
	if hero == null:
		hero = scene.get_node_or_null("HeroSlot/HeroController")
	if hero == null:
		push_error("no hero")
		quit()
		return
	var skill_btn := scene.find_child("SkillButton", true, false) as Button

	hero.position = Vector2(320.0, 40.0)
	_snap(scene, hero)
	await process_frame
	await _save("shop-hall-no-keepers")

	hero.position = Vector2(320.0, -70.0)
	_snap(scene, hero)
	await process_frame
	await process_frame
	_btn_dump(scene, "counter")
	var counter_img := await _save("skill-bang-icon")
	await _save("skill-bang-counter")
	_save_crop(counter_img, skill_btn, "skill-bang-icon-crop")

	hero.position = Vector2(640.0, 336.0)
	_snap(scene, hero)
	await process_frame
	_btn_dump(scene, "far")
	await _save("hud-layout")
	await _save("skill-bang-icon-far")

	scene.call(
		"_spawn_world_pickup",
		&"weapon",
		&"pistol",
		"res://assets/generated/pickups/pistol.png",
		0.36,
		Vector2(640.0, 336.0),
		0,
		20.0
	)
	scene.call("_process_pickups")
	_snap(scene, hero)
	await process_frame
	await process_frame
	_btn_dump(scene, "loot")
	await _save("skill-bang-icon-loot")
	await _save("skill-bang-loot")
	print("QA_SHOTS_DONE")
	quit()

extends SceneTree

const OUT := "/workspace/emberline-qa/trainer-icons-hall.png"

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
	if scene.has_method("_refresh_shop_ui"):
		scene.call("_refresh_shop_ui")
	if scene.has_method("_refresh_shop_shelves"):
		scene.call("_refresh_shop_shelves")


func _wait_frames(n: int) -> void:
	for _i in range(n):
		await process_frame


func _dump_slots(scene: Node) -> void:
	var shop = scene.get("_shop")
	if shop == null:
		print("QA_SLOTS missing shop")
		return
	var slots: Array = shop.slots
	print("QA_SLOTS n=%s" % slots.size())
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		print("QA_SLOT i=%s kind=%s vendor=%s title=%s icon=%s" % [
			i,
			slot.get("kind", &""),
			slot.get("vendor", &""),
			slot.get("title", ""),
			slot.get("icon", ""),
		])
	var icons = scene.get("_shelf_icons")
	if icons is Array:
		for i in range((icons as Array).size()):
			var spr: Sprite2D = icons[i]
			var tex_path := ""
			if spr != null and spr.texture != null:
				tex_path = String(spr.texture.resource_path)
			print("QA_SHELF i=%s vis=%s tex=%s scale=%s pos=%s" % [
				i,
				spr.visible if spr != null else false,
				tex_path,
				spr.scale if spr != null else Vector2.ZERO,
				spr.position if spr != null else Vector2.ZERO,
			])


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute("/workspace/emberline-qa")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Engine.max_fps = 60
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	await RenderingServer.frame_post_draw
	var hero: Node2D = scene.get("_hero")
	if hero == null:
		hero = scene.get_node_or_null("HeroSlot/HeroController")
	if hero == null:
		push_error("no hero")
		quit()
		return
	hero.position = Vector2(560.0, -90.0)
	_snap(scene, hero)
	await _wait_frames(8)
	_snap(scene, hero)
	_dump_slots(scene)
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("QA_SHOT %s err=no-texture" % OUT)
		quit()
		return
	var image := tex.get_image()
	if image == null:
		print("QA_SHOT %s err=no-image" % OUT)
		quit()
		return
	var err := image.save_png(OUT)
	print("QA_SHOT %s err=%s %sx%s" % [OUT, err, image.get_width(), image.get_height()])
	print("QA_SHOTS_DONE")
	quit()

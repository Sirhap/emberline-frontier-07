extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	EmberRunSave.delete_run()
	DisplayServer.window_set_size(Vector2i(1600, 720))
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hud: FrontierHud = scene.get("_hud")
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.global_position = Vector2(540.0, -90.0)
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.zoom = scene.call("camera_zoom_for", hero.global_position)
		cam.global_position = scene.call("camera_target_for", hero.global_position)
		cam.reset_smoothing()
		cam.force_update_scroll()
	scene.call("_refresh_shop_ui")
	if hud.has_method("_apply_safe_area"):
		hud.call("_apply_safe_area")
	if hud.has_method("_fit_all_docks"):
		hud.call("_fit_all_docks")
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	RenderingServer.force_draw()
	var vp := root.get_viewport().get_visible_rect().size
	print("WIDE_VP %s" % vp)
	var tex := root.get_viewport().get_texture()
	var image := tex.get_image()
	image.save_png("/workspace/emberline-qa/layout-wide-hall.png")
	print("WIDE_SAVED %sx%s" % [image.get_width(), image.get_height()])
	quit()

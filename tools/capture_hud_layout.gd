extends SceneTree

const OUT := "res://dogfood-output/qa/accept-shots/live-qa/hud-toprow.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://dogfood-output/qa/accept-shots/live-qa"))
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	_print_hud(scene, "ARENA")
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var tex := root.get_viewport().get_texture()
	var img := tex.get_image()
	img.save_png(OUT)
	print("SAVED %s hero=%s cam=%s" % [OUT, hero.position, cam.global_position if cam else Vector2.ZERO])
	quit()

func _print_hud(scene: Node, tag: String) -> void:
	var names := ["TopRow", "TopLeft", "TopRight", "ScrapChip", "CoreLabel", "WarehouseButton", "FullscreenButton", "PrepCountdown"]
	for n: String in names:
		var node := scene.find_child(n, true, false) as Control
		if node == null:
			print("HUD %s %s MISSING" % [tag, n])
			continue
		var extra := ""
		if node is Label:
			extra = " text='%s'" % (node as Label).text
		elif node is Button:
			extra = " text='%s'" % (node as Button).text
		print("HUD %s %s vis=%s pos=%s size=%s glob=%s%s" % [
			tag, n, node.visible, node.position, node.size, node.global_position, extra,
		])
	var pen: Node = scene.get("_shop_pen")
	if pen != null:
		print("CAPTIONS %s in_hall=%s" % [pen.get("shelf_captions"), pen.call("_in_shop_hall")])

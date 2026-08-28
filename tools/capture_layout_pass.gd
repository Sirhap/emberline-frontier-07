extends SceneTree

const OUT := "/workspace/emberline-qa"

func _init() -> void:
	call_deferred("_run")

func _save(path: String) -> void:
	print("QA_SAVE_BEGIN %s vp=%s" % [path, root.get_viewport().get_visible_rect().size])
	RenderingServer.force_draw()
	await process_frame
	RenderingServer.force_draw()
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("QA_SHOT %s err=no-texture" % path)
		return
	var image := tex.get_image()
	if image == null:
		print("QA_SHOT %s err=no-image" % path)
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	var err := image.save_png(path)
	print("QA_SHOT %s err=%s %sx%s" % [path, err, image.get_width(), image.get_height()])

func _snap_cam(scene: Node, world: Vector2) -> void:
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.global_position = world
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.zoom = scene.call("camera_zoom_for", world)
		cam.global_position = scene.call("camera_target_for", world)
		cam.reset_smoothing()
		cam.force_update_scroll()
	if scene.has_method("_refresh_shop_ui"):
		scene.call("_refresh_shop_ui")

func _dump(scene: Node, tag: String) -> void:
	var names := [
		"SafeArea", "TopLeftDock", "TopRow", "TopRightDock", "MidLeftDock",
		"BottomLeftDock", "BottomRightDock", "WarehousePanel", "ShopPanel",
		"TowerPanel", "StatusLabel", "ShopHoldHint", "LootRow", "EndOverlay",
		"EndPanel", "MoveStick", "AttackButton",
	]
	print("LAYOUT_DUMP %s viewport=%s" % [tag, root.get_viewport().get_visible_rect().size])
	for n: String in names:
		var node := scene.find_child(n, true, false) as Control
		if node == null:
			print("LAYOUT_DUMP %s %s MISSING" % [tag, n])
			continue
		print("LAYOUT_DUMP %s %s parent=%s vis=%s anchors=(%s,%s,%s,%s) size=%s glob=%s" % [
			tag, n,
			node.get_parent().name if node.get_parent() else "?",
			node.visible,
			node.anchor_left, node.anchor_top, node.anchor_right, node.anchor_bottom,
			node.size, node.global_position,
		])
	var pen: Node = scene.get("_shop_pen")
	if pen != null:
		print("LAYOUT_DUMP %s shop_pen process=%s captions=%s hall=%s" % [
			tag, pen.is_processing(), pen.get("shelf_captions"), pen.call("_in_shop_hall"),
		])

func _run() -> void:
	print("LAYOUT_PASS_RUN")
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hud: FrontierHud = scene.get("_hud")
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")

	_snap_cam(scene, Vector2(540.0, -90.0))
	hud.update_status("家厅已开放  /  下波 东洞出怪  /  点柜台购买")
	if hud.has_method("_fit_all_docks"):
		hud.call("_fit_all_docks")
	await process_frame
	_dump(scene, "shop-hall")
	await _save("%s/layout-shop-hall.png" % OUT)

	hero.item_stash = {"scrap": 40, "heal": 1, "weapons": [&"pistol"]}
	if not bool(scene.get("_warehouse_open")):
		scene.call("_toggle_warehouse")
	hud.set_hold_hint("手持炮台：脉冲塔 x1 — 点击地砖放下")
	if hud.has_method("_fit_all_docks"):
		hud.call("_fit_all_docks")
	await process_frame
	_dump(scene, "warehouse")
	await _save("%s/layout-warehouse.png" % OUT)
	if bool(scene.get("_warehouse_open")):
		scene.call("_toggle_warehouse")
	hud.set_hold_hint("")

	_snap_cam(scene, Vector2(456.0, 336.0))
	scene.call("_spawn_tower_at", Vector2(456.0, 216.0), &"pulse", 1)
	var towers: Array = scene.get("_towers")
	if not towers.is_empty():
		scene.call("_select_tower", towers[0])
	hud.layout_for_home(false)
	if hud.has_method("_fit_all_docks"):
		hud.call("_fit_all_docks")
	await process_frame
	_dump(scene, "tower")
	await _save("%s/layout-tower-panel.png" % OUT)

	hud.clear_tower_info()
	_snap_cam(scene, Vector2(400.0, 336.0))
	hud.layout_for_home(false)
	if hud.has_method("_fit_all_docks"):
		hud.call("_fit_all_docks")
	await process_frame
	_dump(scene, "combat")
	await _save("%s/layout-combat.png" % OUT)

	DisplayServer.window_set_size(Vector2i(1600, 720))
	if hud.has_method("_apply_safe_area"):
		hud.call("_apply_safe_area")
	if hud.has_method("_fit_all_docks"):
		hud.call("_fit_all_docks")
	_snap_cam(scene, Vector2(540.0, -90.0))
	await process_frame
	_dump(scene, "wide")
	await _save("%s/layout-wide-hall.png" % OUT)

	print("LAYOUT_PASS_DONE")
	quit()

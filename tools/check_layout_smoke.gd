extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var bl_dock := scene.find_child("BottomLeftDock", true, false) as Control
	var tl_dock := scene.find_child("TopLeftDock", true, false) as Control
	var mid_dock := scene.find_child("MidLeftDock", true, false) as Control
	var warehouse_panel := scene.find_child("WarehousePanel", true, false) as Control
	var status_label := scene.find_child("StatusLabel", true, false) as Control
	var hold_hint := scene.find_child("ShopHoldHint", true, false) as Control
	var tower_panel := scene.find_child("TowerPanel", true, false) as Control
	var shop_strip := scene.find_child("ShopPanel", true, false) as Control
	var loot_row := scene.find_child("LootRow", true, false) as Control
	var end_overlay := scene.find_child("EndOverlay", true, false) as Control
	var end_center := scene.find_child("EndCenter", true, false) as Control
	assert(tl_dock != null and warehouse_panel != null and tl_dock.is_ancestor_of(warehouse_panel), "Warehouse lives in TopLeftDock")
	assert(status_label != null and tl_dock.is_ancestor_of(status_label), "Status toast lives in TopLeftDock")
	assert(hold_hint != null and tl_dock.is_ancestor_of(hold_hint), "Shop hold hint lives in TopLeftDock")
	assert(mid_dock != null and tower_panel != null and mid_dock.is_ancestor_of(tower_panel), "Tower panel lives in MidLeftDock")
	assert(shop_strip != null and is_equal_approx(shop_strip.anchor_left, 0.0) and is_equal_approx(shop_strip.anchor_right, 1.0), "Shop strip is a top-wide SafeInner band")
	assert(loot_row != null and bl_dock.is_ancestor_of(loot_row), "Pickup/discard sit above the stick in BottomLeftDock")
	assert(end_overlay != null and end_center != null and end_overlay.is_ancestor_of(end_center), "Pause/result overlay is a full-rect centered stack")
	var shop_pen: Node = scene.get("_shop_pen")
	assert(shop_pen != null and not shop_pen.is_processing(), "Shop pen must not redraw every frame")
	var north_camera_point := Vector2(1413.0, -200.0)
	var north_camera_zoom: Vector2 = scene.call("camera_zoom_for", north_camera_point)
	var north_camera_target: Vector2 = scene.call("camera_target_for", north_camera_point)
	assert(north_camera_zoom.x > 1.0, "Narrow spawn roads should use a light contextual zoom")
	assert(absf(north_camera_target.x - north_camera_point.x) < 80.0, "North-road framing should stay on the corridor")
	var shop_camera_zoom: Vector2 = scene.call("camera_zoom_for", Vector2(320.0, -110.0))
	assert(shop_camera_zoom.x > north_camera_zoom.x, "The narrower shop room should receive the tighter contextual framing")
	var shop_cam_at := Vector2(540.0, -90.0)
	var shop_target: Vector2 = scene.call("camera_target_for", shop_cam_at)
	var shop_zoom_v: Vector2 = scene.call("camera_zoom_for", shop_cam_at)
	var view := Vector2(1280.0, 720.0)
	var shelves: Array = scene.get("SHOP_SHELVES")
	assert(shelves != null and shelves.size() == 5, "Five shop shelves")
	for spot: Vector2 in shelves:
		var screen := (spot - shop_target) * shop_zoom_v.x + view * 0.5
		var price_screen := (spot + Vector2(0.0, -22.0) - shop_target) * shop_zoom_v.x + view * 0.5
		assert(screen.x > 40.0 and screen.x < 1240.0, "Shop camera must keep every counter on screen")
		assert(price_screen.y > 88.0 and price_screen.y < 520.0, "Shop prices must sit below the top chrome")
		print("SHELF screen=%s price=%s" % [screen, price_screen])
	print("LAYOUT_SMOKE_OK cam=%s zoom=%s" % [shop_target, shop_zoom_v])
	quit()

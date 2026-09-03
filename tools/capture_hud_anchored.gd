extends SceneTree

const OUT := "res://dogfood-output/qa"

func _init() -> void:
	call_deferred("_run")

func _save(path: String) -> Image:
	RenderingServer.force_draw()
	await process_frame
	await process_frame
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("QA_SHOT %s err=no-texture" % path)
		return null
	var image := tex.get_image()
	if image == null:
		print("QA_SHOT %s err=no-image" % path)
		return null
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var err := image.save_png(path)
	print("QA_SHOT %s err=%s %sx%s" % [path, err, image.get_width(), image.get_height()])
	return image

func _dump(hud: Node, tag: String) -> void:
	var names := [
		"SafeArea", "SafeInner", "TopLeftDock", "TopRow", "TopRightDock",
		"BottomLeftDock", "BottomRightDock", "ActionCluster", "MoveStick",
		"AttackButton", "JumpButton", "SkillButton", "WeaponSwitch",
		"MiniMap", "PortraitRow", "HeroSelect_ember_hero", "HeroSelect_assassin",
		"PickupButton", "TalkButton", "FullscreenButton",
	]
	print("HUD_DUMP %s viewport=%s" % [tag, root.get_viewport().get_visible_rect().size])
	for n: String in names:
		var node := hud.find_child(n, true, false) as Control
		if node == null:
			print("HUD_DUMP %s %s MISSING" % [tag, n])
			continue
		print("HUD_DUMP %s %s parent=%s preset=%s anchors=(%s,%s,%s,%s) offsets=(%s,%s,%s,%s) size=%s glob=%s" % [
			tag, n,
			node.get_parent().name if node.get_parent() else "?",
			node.anchors_preset,
			node.anchor_left, node.anchor_top, node.anchor_right, node.anchor_bottom,
			node.offset_left, node.offset_top, node.offset_right, node.offset_bottom,
			node.size, node.global_position,
		])
	print("HUD_DUMP %s apply_safe_area=%s" % [tag, hud.has_method("_apply_safe_area")])

func _crop_cluster(full: Image, hud: Node, path: String) -> void:
	if full == null:
		return
	var bl := hud.find_child("BottomLeftDock", true, false) as Control
	var br := hud.find_child("BottomRightDock", true, false) as Control
	if bl == null or br == null:
		print("QA_CROP missing docks")
		return
	var r := Rect2(bl.global_position, bl.size).merge(Rect2(br.global_position, br.size)).grow(20.0)
	var ri := Rect2i(Vector2i(r.position), Vector2i(r.size)).intersection(Rect2i(0, 0, full.get_width(), full.get_height()))
	if ri.size.x <= 0 or ri.size.y <= 0:
		print("QA_CROP empty %s" % r)
		return
	var crop := full.get_region(ri)
	var err := crop.save_png(path)
	print("QA_SHOT %s err=%s %sx%s" % [path, err, crop.get_width(), crop.get_height()])

func _run() -> void:
	print("RUN")
	Engine.max_fps = 60
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.08, 0.10, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var hud = (load("res://scripts/hud.gd") as GDScript).new()
	root.add_child(hud)
	await process_frame
	await process_frame
	print("HUD_READY")
	hud.update_stats(300, 10, 0)
	hud.set_shop_countdown(50.0)
	hud.set_skill(true, 0.0, 12.0, "冲刺", false)
	
	if hud.has_method("_fit_all_docks"):
		hud.call("_fit_all_docks")
	await process_frame
	_dump(hud, "1280")
	var full := await _save("%s/hud-anchored-1280.png" % OUT)
	_crop_cluster(full, hud, "%s/hud-anchored-cluster.png" % OUT)

	hud.set_interact(true)
	await process_frame
	var skill := hud.find_child("SkillButton", true, false) as Button
	print("QA_BTN interact text='%s' icon=%s" % [
		skill.text if skill else "?",
		skill.icon.resource_path if skill != null and skill.icon != null else "none",
	])
	await _save("%s/hud-anchored-interact.png" % OUT)

	hud.set_interact(false)
	hud.set_skill(true, 0.0, 12.0, "冲刺", false)
	DisplayServer.window_set_size(Vector2i(1600, 720))
	hud.call("_apply_safe_area")
	hud.call("_fit_all_docks")
	await process_frame
	await process_frame
	_dump(hud, "wide")
	await _save("%s/hud-anchored-wide.png" % OUT)
	print("HUD_ANCHORED_DONE")
	quit()

extends SceneTree

const OUT_DIR := "res://tools/accept-shots/live-qa"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute("/workspace/emberline-frontier-07/tools/accept-shots/live-qa")
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false

	# --- 7 + first-frame HUD: scrap chip, prep ~50 not 100, 全屏 ---
	_print_prep(scene, "START")
	_print_hud_top(scene, "FIRST")
	_aim_camera(scene, hero, cam)
	await _settle(scene, hero, cam)
	await _save("hud-first")

	# --- shop hall keepers + captions ---
	scene.set("_talking_npc", &"")
	scene.call("_refresh_shop_ui")
	hero.position = Vector2(540.0, -70.0)
	_pose(hero)
	_aim_camera(scene, hero, cam)
	await _settle(scene, hero, cam)
	await _save("shop-hall")
	_print_shop_hall(scene, hero)

	# Far click: hero at (640,336), click pistol shelf — must not buy
	hero.position = Vector2(640.0, 336.0)
	var scrap_far: int = int(scene.get("scrap"))
	var slots_far: Array = hero.weapon_slots.duplicate()
	var far_hit: bool = bool(scene.call("_try_buy_shelf", Vector2(320.0, -70.0)))
	print("FAR_CLICK hero=(640,336) click_shelf=(320,-70) hit=%s scrap=%s->%s slots=%s->%s talking=%s" % [
		far_hit, scrap_far, int(scene.get("scrap")), slots_far, hero.weapon_slots, scene.get("_talking_npc"),
	])

	# Near pistol counter, talking empty — buy must succeed without talk panel
	hero.position = Vector2(320.0, -70.0)
	scene.set("_talking_npc", &"")
	scene.call("_refresh_shop_ui")
	_pose(hero)
	_aim_camera(scene, hero, cam)
	var scrap_near: int = int(scene.get("scrap"))
	var slots_near: Array = hero.weapon_slots.duplicate()
	var shop_panel := scene.find_child("ShopPanel", true, false) as Control
	var buy_hit: bool = bool(scene.call("_try_buy_shelf", Vector2(320.0, -70.0)))
	await _settle(scene, hero, cam)
	await _save("shop-buy")
	print("BUY_PISTOL talking='%s' panel=%s hit=%s scrap=%s->%s slots=%s->%s current=%s" % [
		scene.get("_talking_npc"),
		shop_panel.visible if shop_panel else false,
		buy_hit,
		scrap_near,
		int(scene.get("scrap")),
		slots_near,
		hero.weapon_slots,
		hero.current_weapon,
	])

	# Far click while standing at shelf: click (640,336) must not buy again
	var scrap_far2: int = int(scene.get("scrap"))
	var far2: bool = bool(scene.call("_try_buy_shelf", Vector2(640.0, 336.0)))
	print("FAR_CLICK_FROM_SHELF click=(640,336) hit=%s scrap=%s->%s" % [
		far2, scrap_far2, int(scene.get("scrap")),
	])

	# --- assassin + sword, 12 frames ---
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.apply_hero_kind(&"assassin")
	hero.skill_levels[&"assassin"] = 0
	_set_loadout(hero, &"sword")
	hero.position = Vector2(640.0, 336.0)
	_pose(hero)
	_aim_camera(scene, hero, cam)
	await _settle(scene, hero, cam)
	hero.set("_attack_cooldown", 0.0)
	hero.request_attack()
	for i: int in range(12):
		_pose(hero)
		_aim_camera(scene, hero, cam)
		await process_frame
		if i == 0 or i == 5 or i == 11:
			await _save("assassin-atk-%02d" % i)
		_print_floats("assassin-sword-%02d" % i, hero)

	# --- knight skill 2, 12 frames ---
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.apply_hero_kind(&"ember_hero")
	hero.skill_levels[&"ember_hero"] = 2
	_set_loadout(hero, &"sword")
	hero.position = Vector2(640.0, 336.0)
	_pose(hero)
	_aim_camera(scene, hero, cam)
	await _settle(scene, hero, cam)
	print("KNIGHT_S2 setup floats=%d origins=%d skill=%s" % [
		hero.floating_weapon_count(),
		hero.combat_float_origins().size(),
		hero.skill_levels,
	])
	hero.set("_attack_cooldown", 0.0)
	hero.request_attack()
	for i: int in range(12):
		_pose(hero)
		_aim_camera(scene, hero, cam)
		await process_frame
		if i == 0 or i == 5 or i == 11:
			await _save("knight-s2-%02d" % i)
		_print_floats("knight-s2-%02d" % i, hero)

	# --- loot: walk-over must not vacuum; manual pick one ---
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.apply_hero_kind(&"ember_hero")
	hero.skill_levels[&"ember_hero"] = 0
	_set_loadout(hero, &"sword")
	hero.position = Vector2(640.0, 336.0)
	_pose(hero)
	var scrap_pos := Vector2(668.0, 336.0)
	var weapon_pos := Vector2(612.0, 340.0)
	scene.call(
		"_spawn_world_pickup",
		&"scrap",
		&"",
		"res://assets/generated/ui/scrap.png",
		0.50,
		scrap_pos,
		25,
		20.0
	)
	scene.call(
		"_spawn_world_pickup",
		&"weapon",
		&"pistol",
		"res://assets/generated/weapons/pistol.png",
		0.36,
		weapon_pos,
		0,
		20.0
	)
	# Walk onto both without clicking
	hero.position = Vector2(640.0, 336.0)
	scene.call("_process_pickups")
	await process_frame
	hero.position = scrap_pos
	scene.call("_process_pickups")
	await process_frame
	hero.position = weapon_pos
	scene.call("_process_pickups")
	await process_frame
	hero.position = Vector2(640.0, 336.0)
	scene.call("_process_pickups")
	_aim_camera(scene, hero, cam)
	await _settle(scene, hero, cam)
	var live_after_walk: Array = scene.get("_pickups")
	var scrap_after_walk: int = int(scene.get("scrap"))
	print("LOOT_NO_VACUUM n=%d scrap=%s targeted=%s (walk must not collect)" % [
		live_after_walk.size(),
		scrap_after_walk,
		scene.get("_targeted_pickup") != null,
	])
	await _save("loot-no-vacuum")

	# Manual pick exactly one (targeted / 拾取)
	var n_before_pick: int = (scene.get("_pickups") as Array).size()
	var scrap_before_pick: int = int(scene.get("scrap"))
	var slots_before_pick: Array = hero.weapon_slots.duplicate()
	scene.call("_collect_targeted_pickup")
	await process_frame
	await process_frame
	_aim_camera(scene, hero, cam)
	await _settle(scene, hero, cam)
	await _save("loot-pick-one")
	print("LOOT_PICK_ONE n=%s->%s scrap=%s->%s slots=%s->%s" % [
		n_before_pick,
		(scene.get("_pickups") as Array).size(),
		scrap_before_pick,
		int(scene.get("scrap")),
		slots_before_pick,
		hero.weapon_slots,
	])

	# --- mage: spawn and tick until it fires ---
	var mage := FrontierEnemy.new()
	mage.variant = &"mage"
	mage.max_health = 9999
	mage.move_speed = 0.0
	mage.contact_damage = 10
	mage.configure_seek(Vector2(720.0, 336.0), scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", mage)
	var mage_shots: Array = []
	mage.shot_fired.connect(func(_e, dir, dmg): mage_shots.append({"dir": dir, "dmg": dmg}))
	hero.position = Vector2(640.0, 336.0)
	_pose(hero)
	_aim_camera(scene, hero, cam)
	var fired := false
	for tick_i: int in range(90):
		await process_frame
		if mage_shots.size() > 0:
			fired = true
			break
	_aim_camera(scene, hero, cam)
	await _settle(scene, hero, cam)
	await _save("mage-shot")
	var bullets: Array = scene.get("_live_bullets") if scene.get("_live_bullets") != null else []
	print("MAGE_SHOT fired=%s count=%d pending=%s attacking=%s aggro=%s dist=%.1f bullets=%d shots=%s" % [
		fired,
		mage_shots.size(),
		mage.get("_shot_pending"),
		mage.get("_attacking"),
		mage.get("_aggro"),
		mage.global_position.distance_to(hero.global_position),
		bullets.size() if bullets is Array else -1,
		mage_shots,
	])

	_print_prep(scene, "END")
	print("LIVE_QA_CAPTURE ok")
	quit()


func _print_prep(scene: Node, tag: String) -> void:
	var director: Variant = scene.get("_director")
	var prep_label := scene.find_child("PrepCountdown", true, false) as Label
	var prep_left := 0.0
	var prep_dur := 0.0
	if director != null:
		prep_left = float(director.prep_left)
		prep_dur = float(director.prep_duration)
	print("PREP %s director.prep_left=%.3f prep_duration=%.3f HUD='%s'" % [
		tag, prep_left, prep_dur, prep_label.text if prep_label else "MISSING",
	])


func _print_hud_top(scene: Node, tag: String) -> void:
	var chip := scene.find_child("ScrapChip", true, false)
	var prep := scene.find_child("PrepCountdown", true, false) as Label
	var fs := scene.find_child("FullscreenButton", true, false) as Button
	var resources := ""
	if chip != null:
		var value: Variant = chip.get_meta("value_label") if chip.has_meta("value_label") else null
		if value != null and value.get("text") != null:
			resources = str(value.get("text"))
	print("HUD %s ScrapChip vis=%s value='%s' PrepCountdown='%s' vis=%s Fullscreen='%s' vis=%s scrap=%s" % [
		tag,
		chip.visible if chip is CanvasItem else false,
		resources,
		prep.text if prep else "MISSING",
		prep.visible if prep else false,
		fs.text if fs else "MISSING",
		fs.visible if fs else false,
		int(scene.get("scrap")),
	])


func _print_shop_hall(scene: Node, hero: EmberHero) -> void:
	var shop: EmberShop = scene.get("_shop")
	var shop_panel := scene.find_child("ShopPanel", true, false) as Control
	print("SHOP_HALL panel=%s talking=%s hero=%s shop_open=%s" % [
		shop_panel.visible if shop_panel else false,
		scene.get("_talking_npc"),
		hero.position,
		shop.is_open if shop else false,
	])
	var keepers: Array = []
	for child in scene.get_children():
		if not (child is Sprite2D):
			continue
		var name := String(child.name)
		if name.begins_with("Npc"):
			var tex := ""
			var sprite := child as Sprite2D
			if sprite.texture != null:
				tex = sprite.texture.resource_path.get_file()
			keepers.append("%s vis=%s pos=%s z=%s scale=%s tex=%s" % [
				name, sprite.visible, sprite.position, sprite.z_index, sprite.scale, tex,
			])
	print("KEEPERS n=%d %s" % [keepers.size(), " | ".join(keepers)])
	var shelf_vis: Array[String] = []
	for i: int in range(5):
		var shelf := scene.find_child("ShopShelf%d" % i, true, false) as Sprite2D
		shelf_vis.append("%d vis=%s tex=%s pos=%s" % [
			i,
			shelf.visible if shelf else false,
			shelf.texture.resource_path.get_file() if shelf and shelf.texture else "",
			shelf.position if shelf else Vector2.ZERO,
		])
	print("SHELVES %s" % " | ".join(shelf_vis))
	var pen: Node = scene.get("_shop_pen")
	if pen != null:
		print("CAPTIONS %s" % [pen.get("shelf_captions")])


func _print_floats(tag: String, hero: EmberHero) -> void:
	var parts: Array[String] = []
	for child in hero.get_children():
		if not (child is Sprite2D):
			continue
		var sprite := child as Sprite2D
		var name := String(sprite.name)
		if name != "HeldWeapon" and not name.begins_with("HeldOrbit"):
			continue
		var side := "center"
		if sprite.position.x < -8.0:
			side = "LEFT"
		elif sprite.position.x > 8.0:
			side = "RIGHT"
		var tex := "" if sprite.texture == null else sprite.texture.resource_path.get_file()
		parts.append("%s vis=%s side=%s local=%s z=%d tex=%s" % [
			name, sprite.visible, side, sprite.position, sprite.z_index, tex,
		])
	print("FLOAT %s count=%d origins=%d %s" % [
		tag,
		hero.floating_weapon_count(),
		hero.combat_float_origins().size(),
		" | ".join(parts),
	])


func _set_loadout(hero: EmberHero, weapon_id: StringName) -> void:
	hero.weapon_slots = [weapon_id, &""]
	hero.weapon_slot_index = 0
	hero.current_weapon = weapon_id
	hero.turret_hand = false
	hero.call("_refresh_held_weapon")


func _pose(hero: EmberHero) -> void:
	Input.warp_mouse(Vector2(1100.0, 360.0))
	hero.set("_aim_dir", Vector2.RIGHT)
	hero.call("_apply_facing", 1)
	hero.call("_refresh_held_weapon")


func _aim_camera(scene: Node, hero: Node2D, cam: Camera2D) -> void:
	if cam == null:
		return
	cam.position_smoothing_enabled = false
	var zoom := Vector2.ONE
	if scene.has_method("camera_zoom_for"):
		zoom = scene.call("camera_zoom_for", hero.position) as Vector2
	cam.zoom = zoom
	if scene.has_method("camera_target_for"):
		cam.global_position = scene.call("camera_target_for", hero.global_position) as Vector2
	else:
		cam.global_position = hero.global_position
	cam.reset_smoothing()
	cam.force_update_scroll()


func _settle(scene: Node, hero: EmberHero, cam: Camera2D) -> void:
	_pose(hero)
	_aim_camera(scene, hero, cam)
	await process_frame
	await process_frame
	_aim_camera(scene, hero, cam)
	await RenderingServer.frame_post_draw


func _save(shot_name: String) -> void:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT_DIR, shot_name]
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("SAVED %s err=no-texture" % path)
		return
	var image := tex.get_image()
	if image == null:
		print("SAVED %s err=no-image" % path)
		return
	var err := image.save_png(path)
	print("SAVED %s err=%s size=%sx%s" % [path, err, image.get_width(), image.get_height()])

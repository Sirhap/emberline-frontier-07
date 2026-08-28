extends SceneTree

const OUT_DIR := "/workspace/emberline-qa"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false

	# Confirm wave-2 mage pick before any combat.
	scene.set("current_wave", 2)
	scene.set("_spawned_in_wave", 4)
	var wave2_kind: StringName = scene.call("_pick_spawn_variant")
	scene.set("current_wave", 0)
	scene.set("_spawned_in_wave", 0)
	print("PICK_WAVE2_SLOT4 kind=%s (expect mage)" % wave2_kind)

	scene.set("current_wave", 1)
	scene.set("_spawned_in_wave", 4)
	var wave1_kind: StringName = scene.call("_pick_spawn_variant")
	scene.set("current_wave", 0)
	scene.set("_spawned_in_wave", 0)
	print("PICK_WAVE1_SLOT4 kind=%s (expect runner/scout, not mage)" % wave1_kind)

	# --- V08: north shop hall, 5 counters ---
	scene.set("_talking_npc", &"")
	scene.call("_refresh_shop_ui")
	hero.position = Vector2(540.0, -70.0)
	_pose(hero)
	_aim_camera(scene, hero, cam)
	await _settle(scene, hero, cam)
	await _save("v08-five-counters")
	_print_shop_hall(scene, hero)

	# --- V09: crop forge caption ---
	await _save_forge_crop(scene, "v09-forge-180")

	# --- V10: near-counter click buy, no ShopPanel ---
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
	await _save("v10-click-buy")
	print("BUY talking='%s' panel=%s hit=%s scrap=%s->%s slots=%s->%s current=%s status='%s'" % [
		scene.get("_talking_npc"),
		shop_panel.visible if shop_panel else false,
		buy_hit,
		scrap_near,
		int(scene.get("scrap")),
		slots_near,
		hero.weapon_slots,
		hero.current_weapon,
		_status_text(scene),
	])

	# extras
	await _copy_png("v08-five-counters.png", "shop-hall.png")
	await _copy_png("v10-click-buy.png", "shop-buy.png")

	# --- V19: real wave-2 mage if possible, else force ---
	var forced := false
	var mage: FrontierEnemy = await _spawn_wave2_mage(scene, hero, cam)
	if mage == null or not is_instance_valid(mage):
		forced = true
		mage = _force_mage(scene, hero)
		print("MAGE force-spawned at %s" % mage.global_position)
	else:
		print("MAGE wave2-spawn at %s variant=%s" % [mage.global_position, mage.variant])

	hero.position = mage.global_position + Vector2(-80.0, 0.0)
	_pose(hero)
	_aim_camera(scene, hero, cam)
	var mage_shots: Array = []
	if is_instance_valid(mage):
		mage.shot_fired.connect(func(_e, dir, dmg): mage_shots.append({"dir": dir, "dmg": dmg}))
	var fired := false
	for _tick: int in range(180):
		if is_instance_valid(mage):
			var gap := mage.global_position.distance_to(hero.global_position)
			if gap < 40.0 or gap > 130.0:
				hero.position = mage.global_position + Vector2(-80.0, 0.0)
		_aim_camera(scene, hero, cam)
		await process_frame
		if mage_shots.size() > 0:
			fired = true
			# a couple frames so the bolt is in flight
			await process_frame
			await process_frame
			break
	_aim_camera(scene, hero, cam)
	await _settle(scene, hero, cam)
	await _save("v19-mage-bolt")
	await _copy_png("v19-mage-bolt.png", "mage-shot.png")
	var bullets: Array = scene.get("_live_bullets") if scene.get("_live_bullets") != null else []
	var enemy_bolts := 0
	for bullet: Variant in bullets:
		if bullet is EnemyProjectile:
			enemy_bolts += 1
	print("MAGE_SHOT forced=%s fired=%s shots=%d pending=%s attacking=%s aggro=%s dist=%.1f bullets=%d enemy_bolts=%d pick_wave2=%s" % [
		forced,
		fired,
		mage_shots.size(),
		mage.get("_shot_pending") if is_instance_valid(mage) else "dead",
		mage.get("_attacking") if is_instance_valid(mage) else "dead",
		mage.get("_aggro") if is_instance_valid(mage) else "dead",
		mage.global_position.distance_to(hero.global_position) if is_instance_valid(mage) else -1.0,
		bullets.size() if bullets is Array else -1,
		enemy_bolts,
		wave2_kind,
	])

	print("V08_V19_CAPTURE ok forced_mage=%s wave2_pick=%s" % [forced, wave2_kind])
	quit()


func _spawn_wave2_mage(scene: Node, hero: EmberHero, cam: Camera2D) -> FrontierEnemy:
	# Jump into wave 2 combat so slot 4 is a mage via _pick_spawn_variant.
	scene.call("_on_combat_started", 2)
	print("WAVE2 started remaining=%s wave=%s" % [scene.get("_spawn_remaining"), scene.get("current_wave")])
	# Wave 2 interval ~0.82s; 5th spawn (slot 4) around 3.3s. Wait generously.
	for _i: int in range(360):
		await process_frame
		for enemy: Variant in scene.get("_enemies"):
			if enemy is FrontierEnemy and is_instance_valid(enemy) and enemy.variant == &"mage":
				print("WAVE2 found mage after ticks slot_spawned=%s" % scene.get("_spawned_in_wave"))
				return enemy as FrontierEnemy
	print("WAVE2 no mage after wait spawned=%s remaining=%s" % [
		scene.get("_spawned_in_wave"),
		scene.get("_spawn_remaining"),
	])
	return null


func _force_mage(scene: Node, hero: EmberHero) -> FrontierEnemy:
	var mage := FrontierEnemy.new()
	mage.variant = &"mage"
	mage.max_health = 9999
	mage.move_speed = 0.0
	mage.contact_damage = 10
	var start := hero.global_position + Vector2(90.0, 0.0)
	if start.y < 80.0:
		start = Vector2(720.0, 336.0)
		hero.position = Vector2(640.0, 336.0)
	mage.configure_seek(start, scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", mage)
	return mage


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
			keepers.append("%s vis=%s pos=%s tex=%s" % [name, sprite.visible, sprite.position, tex])
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


func _status_text(scene: Node) -> String:
	var status := scene.find_child("StatusLabel", true, false) as Label
	return status.text if status else ""


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
	print("SAVED %s err=%s size=%sx%s bytes_hint=%s" % [path, err, image.get_width(), image.get_height(), FileAccess.get_file_as_bytes(path).size() if err == OK else 0])


func _save_forge_crop(scene: Node, shot_name: String) -> void:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("SAVED forge err=no-texture")
		return
	var image := tex.get_image()
	if image == null:
		print("SAVED forge err=no-image")
		return
	var world := Vector2(740.0, -40.0)
	var screen: Vector2 = scene.get_viewport().get_canvas_transform() * world
	var cx := int(screen.x)
	var cy := int(screen.y)
	var w := 360
	var h := 220
	var x := clampi(cx - w / 2, 0, image.get_width() - 8)
	var y := clampi(cy - 40, 0, image.get_height() - 8)
	w = mini(w, image.get_width() - x)
	h = mini(h, image.get_height() - y)
	if w < 32 or h < 32:
		var err_full := image.save_png("%s/%s.png" % [OUT_DIR, shot_name])
		print("SAVED %s/%s.png full-fallback err=%s screen=%s" % [OUT_DIR, shot_name, err_full, screen])
		return
	var crop := image.get_region(Rect2i(x, y, w, h))
	var path := "%s/%s.png" % [OUT_DIR, shot_name]
	var err := crop.save_png(path)
	print("SAVED %s err=%s crop=%sx%s from screen=%s rect=%s" % [path, err, crop.get_width(), crop.get_height(), screen, Rect2i(x, y, w, h)])


func _copy_png(src_name: String, dest_name: String) -> void:
	var src := "%s/%s" % [OUT_DIR, src_name]
	var dest := "%s/%s" % [OUT_DIR, dest_name]
	var img := Image.new()
	if img.load(src) != OK:
		print("COPY fail load %s" % src)
		return
	var err := img.save_png(dest)
	print("COPY %s -> %s err=%s" % [src, dest, err])

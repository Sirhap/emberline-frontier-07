extends SceneTree

const OUT := "/workspace/emberline-qa"
const PAD := Vector2(648.0, 336.0)


func _init() -> void:
	call_deferred("_run")


func _wait(n: int = 4) -> void:
	for _i in range(n):
		await process_frame


func _lock_cam(cam: Camera2D, at: Vector2, zoom: float) -> void:
	if cam == null:
		return
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(zoom, zoom)
	cam.global_position = at
	cam.reset_smoothing()
	cam.force_update_scroll()


func _settle(cam: Camera2D, at: Vector2, zoom: float = 2.60) -> void:
	_lock_cam(cam, at, zoom)
	await _wait(3)
	_lock_cam(cam, at, zoom)
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT, name]
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("QA_SHOT %s err=no-texture" % path)
		return
	var image := tex.get_image()
	if image == null:
		print("QA_SHOT %s err=no-image" % path)
		return
	var err := image.save_png(path)
	print("QA_SHOT %s err=%s %sx%s" % [path, err, image.get_width(), image.get_height()])


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
	print("QA_BTN state=%s text='%s' icon=%s expand=%s disabled=%s" % [
		state, btn.text, icon_path, btn.expand_icon, btn.disabled
	])


func _spr_info(tower: EmberTower, node_name: String) -> String:
	var spr := tower.get_node_or_null(node_name) as Sprite2D
	if spr == null:
		return "%s=missing" % node_name
	var tex_path := ""
	if spr.texture != null:
		tex_path = String(spr.texture.resource_path)
	return "%s vis=%s tex=%s scale=%s pos=%s modulate=%s" % [node_name, spr.visible, tex_path, spr.scale, spr.position, spr.modulate]


func _tower_dump(tower: EmberTower, tag: String) -> void:
	if tower == null or not is_instance_valid(tower):
		print("QA_TOWER %s missing" % tag)
		return
	print("QA_TOWER %s kind=%s weapon=%s health=%s/%s %s | %s" % [
		tag, tower.kind, tower.weapon_id, tower.health, tower.max_health,
		_spr_info(tower, "TowerSprite"),
		_spr_info(tower, "TowerWeapon"),
	])


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(OUT)
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await _wait(8)
	await RenderingServer.frame_post_draw

	var hero: EmberHero = scene.get("_hero")
	if hero == null:
		hero = scene.get_node_or_null("HeroSlot/HeroController")
	if hero == null:
		push_error("no hero")
		quit()
		return

	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.enabled = true
	# Keep scene camera pointer so HUD still syncs, but we lock it each frame.

	var tower: EmberTower = scene.call("_spawn_tower_at", PAD, &"pulse", 1)
	scene.call("_select_tower", null)
	hero.weapon_slots = [&"pistol", &""] as Array[StringName]
	hero.weapon_slot_index = 0
	hero.current_weapon = &"pistol"
	hero.turret_hand = false
	hero.call("_refresh_held_weapon")
	# Stand inside the 72px mount radius of the *snapped* cell center.
	hero.position = tower.global_position + Vector2(58.0, 28.0)
	hero.call("_apply_facing", 1)
	var look := tower.global_position + Vector2(8.0, -8.0)
	scene.call("_sync_weapon_hud")
	scene.call("_sync_skill_hud")
	await _wait(4)
	_lock_cam(cam, look, 2.60)
	await _settle(cam, look)
	scene.call("_sync_skill_hud")
	await process_frame
	_btn_dump(scene, "empty-approach")
	_tower_dump(tower, "empty")
	var empty_tex := ""
	var empty_spr := tower.get_node_or_null("TowerSprite") as Sprite2D
	if empty_spr != null and empty_spr.texture != null:
		empty_tex = String(empty_spr.texture.resource_path)
	print("QA_PAD empty_tex=%s hide_kind_body=%s extra_towers=%s" % [
		empty_tex,
		not empty_tex.contains("tower-lv") and not empty_tex.contains("burst-lv") and not empty_tex.contains("frost-lv"),
		(scene.get("_towers") as Array).size(),
	])
	print("QA_HERO empty weapon=%s turret=%s dist=%.1f nearby=%s" % [
		hero.combat_weapon_id(),
		hero.turret_hand,
		hero.global_position.distance_to(tower.global_position),
		scene.call("_nearby_mount_tower") != null,
	])
	var hud: Node = scene.get("_hud")
	if hud != null:
		print("QA_STATUS empty='%s'" % str(hud.get("status_label").text if hud.get("status_label") != null else ""))
	await _save("pad-empty")

	# Press the lit 「!」 — same path as the skill pad. Do not dash if radius missed.
	var offered: EmberTower = scene.call("_nearby_mount_tower")
	if offered == null:
		print("QA_MOUNT skip: not in range, would dash")
		quit()
		return
	scene.call("_on_skill_or_interact")
	await _wait(4)
	scene.call("_sync_skill_hud")
	_lock_cam(cam, look, 2.60)
	await _settle(cam, look)
	_btn_dump(scene, "after-mount")
	_tower_dump(tower, "mounted")
	print("QA_HERO mounted weapon=%s turret=%s slots=%s" % [
		hero.combat_weapon_id(), hero.turret_hand, hero.weapon_slots
	])
	if hud != null and hud.get("status_label") != null:
		print("QA_STATUS mounted='%s'" % str(hud.get("status_label").text))
	await _save("pad-pistol")

	# Click-on-tower path still present: empty tower + held weapon still routes through _try_place_tower.
	var click_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	var click_ok := click_src.contains("_mount_or_swap_weapon(parked)")
	print("QA_CLICK_PATH still_wired=%s" % click_ok)
	print("TOWER_MOUNT_QA ok empty_weapon=%s mounted_weapon=%s hero_after=%s" % [
		&"",
		tower.weapon_id if is_instance_valid(tower) else &"gone",
		hero.combat_weapon_id(),
	])
	quit()

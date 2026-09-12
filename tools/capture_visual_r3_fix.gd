extends SceneTree

## Viewport frames for visual-accept-r3 P0/P1 (HUD leak, down pose, shop prices).

const OUT_DIR := "res://dogfood-output/visual-accept-r3-fix"


func _init() -> void:
	create_timer(50.0).timeout.connect(func() -> void:
		push_error("visual r3 capture timed out")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	EmberRunSave.delete_run()
	print("CAPTURE start")
	await _capture_battle_frames()
	await _capture_app_root_start()
	await _capture_continue_into_battle()
	print("VISUAL_R3_FIX_CAPTURE ok dir=%s" % OUT_DIR)
	quit()


func _capture_battle_frames() -> void:
	print("CAPTURE battle")
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get("_hero")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	var shelves: Array = scene.get("SHOP_SHELVES")
	var shop_spot: Vector2 = shelves[1] if shelves.size() > 1 else Vector2(420.0, -90.0)
	hero.position = shop_spot + Vector2(0.0, 18.0)
	scene.set("_talking_npc", &"")
	if scene.has_method("_refresh_shop_ui"):
		scene.call("_refresh_shop_ui")
	var shop_zoom := 1.22
	if scene.has_method("camera_zoom_for"):
		shop_zoom = (scene.call("camera_zoom_for", hero.position) as Vector2).x
	_aim_camera(cam, hero, shop_zoom)
	await process_frame
	await process_frame
	_aim_camera(cam, hero, shop_zoom)
	_save("11-shop-price")
	hero.position = Vector2(640.0, 336.0)
	_aim_camera(cam, hero, 1.0)
	if scene.has_method("start_wave"):
		scene.call("start_wave")
	await process_frame
	await process_frame
	_aim_camera(cam, hero, 1.0)
	_save("09-combat")
	hero.set("_hit_invuln", 0.0)
	hero.set("_dash_invuln", 0.0)
	hero.debug_god = false
	hero.down_duration = 4.0
	hero.health = 10
	hero.take_damage(999)
	await process_frame
	await process_frame
	_aim_camera(cam, hero, 1.0)
	_save("15-downed")
	var actor := hero.find_child("XSXBHeroActor", true, false)
	print("P1 down state=%s clip=%s frame=%s held=%s" % [
		String(hero.current_state),
		str(actor.get("_current_animation")) if actor != null else "none",
		str(actor.get("_current_frame")) if actor != null else "none",
		_held_visible(hero),
	])
	scene.queue_free()
	await process_frame


func _capture_app_root_start() -> void:
	print("CAPTURE app-root start")
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	if select == null:
		print("CAPTURE missing CharacterSelect")
		root_scene.queue_free()
		await process_frame
		return
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	if hub == null:
		print("CAPTURE missing HomeHub")
		root_scene.queue_free()
		await process_frame
		return
	hub.call("confirm_new_run")
	await process_frame
	await process_frame
	_save("05-battle-start")
	var start_btn := hub.find_child("StartButton", true, false) as Button
	print("P0 start visible_in_tree=%s hub.visible=%s" % [
		start_btn.is_visible_in_tree() if start_btn != null else "missing",
		hub.visible,
	])
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _capture_continue_into_battle() -> void:
	print("CAPTURE continue")
	EmberRunSave.delete_run()
	EmberRunSave.write_run({
		"version": 2,
		"mode_id": "endless_td",
		"run_seed": 42,
		"cleared_wave": 3,
		"scrap": 444,
		"core_health": 7,
		"run_time": 20.0,
		"defeated_count": 9,
		"hero": {
			"hero_id": "assassin",
			"hero_kind": "assassin",
			"health": 90,
			"weapon": "sword",
			"weapons": ["sword", ""],
			"position": [640.0, 336.0],
			"progression": {
				"level": 2,
				"xp": 10,
				"pending_choices": 0,
				"talent_counts": {},
				"talent_rng_state": 1,
				"legacy_bonus_health": 0,
				"legacy_dash_cooldown_level": 0,
				"legacy_bonus_armor": 0,
				"skill_rank": 0,
			},
		},
		"towers": [],
		"drop_rng_state": 1,
		"shop_rng_state": 1,
		"slots": [{
			"kind": "tower",
			"payload": "pulse",
			"cost": 80,
			"sold": false,
			"vendor": "merchant",
			"title": "脉冲塔",
		}],
		"shop": {},
	})
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	if select == null:
		print("CAPTURE continue missing select")
		root_scene.queue_free()
		await process_frame
		EmberRunSave.delete_run()
		return
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	if hub != null:
		hub.call("request_continue")
	await process_frame
	await process_frame
	_save("16-continue-into-battle")
	var start_btn := hub.find_child("StartButton", true, false) as Button if hub != null else null
	var continue_btn := hub.find_child("ContinueButton", true, false) as Button if hub != null else null
	print("P0 continue start_in_tree=%s continue_in_tree=%s" % [
		start_btn.is_visible_in_tree() if start_btn != null else "missing",
		continue_btn.is_visible_in_tree() if continue_btn != null else "missing",
	])
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _held_visible(hero: Node) -> bool:
	var held := hero.find_child("HeldWeapon", true, false) as Sprite2D
	return held != null and held.visible


func _aim_camera(cam: Camera2D, hero: Node2D, zoom: float) -> void:
	if cam == null:
		return
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(zoom, zoom)
	cam.global_position = hero.global_position
	cam.reset_smoothing()
	cam.force_update_scroll()


func _save(stem: String) -> void:
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("CAPTURE skip %s (no viewport texture)" % stem)
		return
	var image := tex.get_image()
	if image == null:
		print("CAPTURE skip %s (dummy renderer)" % stem)
		return
	var path := "%s/%s.png" % [OUT_DIR, stem]
	image.save_png(path)
	print(path)

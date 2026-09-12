extends SceneTree

## Round-3 visual acceptance: key path screenshots on main tip.
const OUT := "res://dogfood-output/visual-accept-r3"
const LIVE_RUN := "user://run.json"
const LIVE_BAK := "user://run.json.visual_bak"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_protect_run()
	EmberRunSave.delete_run()
	Engine.max_fps = 30

	await _shot_character_select()
	await _shot_home_and_start()
	await _shot_battlefield_paths()
	await _shot_continue_expedition()

	_restore_run()
	print("VISUAL ACCEPT R3 CAPTURE DONE")
	quit()


func _shot_character_select() -> void:
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await _frames(3)
	await _save_vp("01-character-select")
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "character select missing")
	select.call("select_hero", &"assassin")
	await _frames(2)
	await _save_vp("02-character-select-assassin")
	select.call("confirm_current")
	await _frames(3)
	await _save_vp("03-home-after-assassin-confirm")
	root_scene.queue_free()
	await process_frame


func _shot_home_and_start() -> void:
	EmberRunSave.delete_run()
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await _frames(2)
	var select := root_scene.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await _frames(3)
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "home hub missing")
	await _save_vp("04-home-hub")
	var start_btn := hub.find_child("StartButton", true, false) as Button
	assert(start_btn != null, "start button missing")
	start_btn.pressed.emit()
	await _frames(4)
	await _save_vp("05-battle-after-start")
	var hub_after := root_scene.find_child("HomeHub", true, false)
	if hub_after != null:
		var start_after := hub_after.find_child("StartButton", true, false) as Button
		print("LEAK_CHECK home.visible=%s start_btn.visible=%s start_btn_in_tree=%s" % [hub_after.visible, start_after.visible if start_after else null, start_after.is_visible_in_tree() if start_after else null])
	var battle := root_scene.find_child("Battlefield", true, false)
	assert(battle != null, "battlefield missing after start")
	var hero: EmberHero = root_scene.find_child("HeroController", true, false) as EmberHero
	assert(hero != null, "hero missing")
	# place / mount
	hero.equip_weapon(&"pistol")
	var pad: EmberTower = null
	for t_v: Variant in battle.get("_towers"):
		var t: EmberTower = t_v
		if t != null and t.is_hologram_pad() and t.weapon_id == &"":
			pad = t
			break
	if pad != null:
		hero.position = pad.global_position + Vector2(-40.0, 0.0)
		battle.call("_try_place_tower", pad.global_position)
		await _frames(2)
		await _save_vp("06-place-mount-pistol")
	# combat spawn
	battle.call("start_wave")
	await _frames(8)
	await _save_vp("07-combat-wave")
	# speed 2x
	battle.set("simulation_speed", 2.0)
	if battle.get("_hud") != null and battle.get("_hud").has_method("set_speed_label"):
		battle.get("_hud").call("set_speed_label", 2.0)
	await _frames(4)
	await _save_vp("08-speed-2x")
	# downed
	hero.down_duration = 2.0
	hero.set("_hit_invuln", 0.0)
	hero.set("_dash_invuln", 0.0)
	hero.take_damage(9999)
	await _frames(3)
	await _save_vp("09-hero-downed")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _shot_battlefield_paths() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await _frames(2)
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	var spots: Array = [
		["10-field-core", Vector2(220.0, 336.0)],
		["11-shop-hall", Vector2(540.0, -70.0)],
		["12-lower-room", Vector2(560.0, 760.0)],
	]
	for spot: Array in spots:
		hero.position = spot[1]
		if cam != null:
			cam.global_position = hero.global_position
			cam.zoom = scene.call("camera_zoom_for", hero.global_position) as Vector2
		await _frames(2)
		await _save_vp(String(spot[0]))
	# sell path: place pulse then select sell
	scene.set("scrap", 500)
	scene.call("_spawn_tower_at", Vector2(456.0, 280.0), &"pulse", 1)
	await _frames(2)
	var towers: Array = scene.get("_towers")
	if towers.size() > 0:
		scene.call("_select_tower", towers[towers.size() - 1])
		await _frames(1)
		await _save_vp("13-tower-selected")
		scene.call("sell_selected_tower")
		await _frames(2)
		await _save_vp("14-after-sell")
	scene.queue_free()
	await process_frame


func _shot_continue_expedition() -> void:
	EmberRunSave.delete_run()
	EmberRunSave.write_run({
		"version": 2,
		"mode_id": "endless_td",
		"run_seed": 7,
		"cleared_wave": 2,
		"scrap": 321,
		"core_health": 8,
		"run_time": 12.0,
		"defeated_count": 5,
		"hero": {
			"hero_id": "assassin",
			"hero_kind": "assassin",
			"health": 80,
			"weapon": "sword",
			"weapons": ["sword", ""],
			"position": [640.0, 336.0],
			"progression": {
				"level": 2,
				"xp": 5,
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
	await _frames(2)
	var select := root_scene.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await _frames(3)
	var hub := root_scene.find_child("HomeHub", true, false)
	var continue_btn := hub.find_child("ContinueButton", true, false) as Button
	assert(continue_btn != null and continue_btn.visible, "continue must show with run.json")
	await _save_vp("15-home-continue-visible")
	continue_btn.pressed.emit()
	await _frames(4)
	await _save_vp("16-continue-restored-battle")
	var hero := root_scene.find_child("HeroController", true, false) as EmberHero
	assert(hero != null and hero.hero_kind == &"assassin", "continue must restore assassin")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _save_vp(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("CAPTURE FAIL %s: no image" % name)
		return
	var path := "%s/%s.png" % [OUT, name]
	var err := image.save_png(path)
	print("CAPTURE %s err=%s size=%dx%d" % [name, err, image.get_width(), image.get_height()])


func _frames(n: int) -> void:
	for _i: int in range(n):
		await process_frame


func _protect_run() -> void:
	if not FileAccess.file_exists(LIVE_RUN):
		return
	var src := FileAccess.open(LIVE_RUN, FileAccess.READ)
	if src == null:
		return
	var text := src.get_as_text()
	src.close()
	var bak := FileAccess.open(LIVE_BAK, FileAccess.WRITE)
	if bak != null:
		bak.store_string(text)
		bak.close()
	EmberRunSave.delete_run()


func _restore_run() -> void:
	if not FileAccess.file_exists(LIVE_BAK):
		return
	var bak := FileAccess.open(LIVE_BAK, FileAccess.READ)
	if bak == null:
		return
	var text := bak.get_as_text()
	bak.close()
	var live := FileAccess.open(LIVE_RUN, FileAccess.WRITE)
	if live != null:
		live.store_string(text)
		live.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LIVE_BAK))

extends SceneTree

## AppRoot defeat path: core death skips end screen and returns home.
## Evidence for dogfood-output/playtest-real P0-1.

const OUT_DIR := "res://dogfood-output/playtest-real"
const LIVE_RUN := "user://run.json"
const LIVE_BAK := "user://run.json.defeat_home_bak"
const EmberRunSave := preload("res://scripts/run_save.gd")
const EmberMetaSave := preload("res://scripts/meta_save.gd")


func _init() -> void:
	create_timer(90.0).timeout.connect(func() -> void:
		push_error("capture_defeat_home timed out")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_protect_run()
	EmberRunSave.delete_run()
	Engine.max_fps = 30
	print("DEFEAT_HOME_CAPTURE start")

	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await _frames(4)

	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "CharacterSelect missing")
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await _frames(4)

	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "HomeHub missing after confirm")
	hub.call("confirm_new_run")
	await _frames(6)

	var battle := root_scene.find_child("Battlefield", true, false)
	assert(battle != null, "Battlefield missing after start")
	assert(bool(battle.get("_launch_configured")), "battle must be launch-configured via AppRoot")

	# Mid-battle context so defeat is not on a blank boot frame.
	if battle.has_method("start_wave"):
		battle.call("start_wave")
	await _frames(8)

	var hero := root_scene.find_child("HeroController", true, false)
	var cam: Camera2D = battle.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	if hero != null and cam != null:
		cam.global_position = hero.global_position

	# Force core loss → explode FX → _end_run (skips show_end_screen when configured).
	battle.set("core_health", 0)
	var hud = battle.get("_hud")
	if hud != null and hud.has_method("update_stats"):
		hud.call("update_stats", int(battle.get("scrap")), 0, int(battle.get("current_wave")))
	if hud != null and hud.has_method("update_status"):
		hud.call("update_status", "核心过载  /  水晶崩解")
	battle.call("_explode_core")
	await _frames(6)
	if cam != null and battle.has_method("core_goal"):
		cam.global_position = battle.call("core_goal") as Vector2

	# (a) Moment of defeat — expect explode FX / status, NO end overlay.
	await _save_shot("09b-defeat-moment")
	var overlay_a := root_scene.find_child("OverlayTitle", true, false) as Label
	var overlay_visible_a := overlay_a != null and overlay_a.visible and overlay_a.is_visible_in_tree()
	var status_a := root_scene.find_child("StatusLabel", true, false) as Label
	print("DEFEAT_MOMENT overlay_visible=%s overlay_text=%s status=%s battle_alive=%s" % [
		overlay_visible_a,
		overlay_a.text if overlay_a != null else "<null>",
		status_a.text if status_a != null else "<null>",
		is_instance_valid(battle),
	])

	# Wait for explode timer (~0.9s) → _end_run → run_finished → _show_home.
	var home_after: Node = null
	var waited := 0.0
	while waited < 3.5:
		await create_timer(0.1).timeout
		waited += 0.1
		home_after = root_scene.find_child("HomeHub", true, false)
		if home_after != null and bool(home_after.visible):
			var battle_gone := root_scene.find_child("Battlefield", true, false) == null
			if battle_gone or not is_instance_valid(battle):
				break

	await _frames(6)
	home_after = root_scene.find_child("HomeHub", true, false)
	assert(home_after != null, "HomeHub must return after AppRoot defeat")
	assert(bool(home_after.visible), "HomeHub must be visible after defeat")
	var battle_final := root_scene.find_child("Battlefield", true, false)
	var overlay_b := root_scene.find_child("OverlayTitle", true, false) as Label
	var start_btn := home_after.find_child("StartButton", true, false) as Button
	print("HOME_AFTER battle=%s overlay=%s start_visible=%s hub.visible=%s" % [
		battle_final != null,
		overlay_b.text if overlay_b != null and overlay_b.is_visible_in_tree() else "<none>",
		start_btn.visible if start_btn != null else false,
		home_after.visible,
	])

	# (b) Home after — primary P0-1 evidence.
	await _save_shot("09-defeat-home")

	var confirmed := (
		home_after != null
		and bool(home_after.visible)
		and battle_final == null
		and not overlay_visible_a
	)
	print("P0-1_VISUAL_CONFIRMED=%s (no end overlay at defeat; home after; battlefield freed)" % confirmed)

	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()
	_restore_run()
	print("DEFEAT_HOME_CAPTURE DONE")
	quit(0 if confirmed else 2)


func _save_shot(stem: String) -> void:
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		push_error("CAPTURE FAIL %s: no image" % stem)
		return
	var png_path := "%s/%s.png" % [OUT_DIR, stem]
	var webp_path := "%s/%s.webp" % [OUT_DIR, stem]
	var err_png := image.save_png(png_path)
	var err_webp := OK
	if image.has_method("save_webp"):
		err_webp = image.call("save_webp", webp_path, false, 0.82)
	else:
		err_webp = ERR_UNAVAILABLE
	print("CAPTURE %s png_err=%s webp_err=%s size=%dx%d" % [
		stem, err_png, err_webp, image.get_width(), image.get_height()
	])


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

extends SceneTree

## PR #9 secondary acceptance: player-visible shots. Do not edit game scripts.
const OUT := "res://dogfood-output/playtest-retest-pr9"
const EmberRunSave := preload("res://scripts/run_save.gd")
const EmberHero := preload("res://scripts/hero.gd")

var _notes: PackedStringArray = []


func _init() -> void:
	create_timer(80.0).timeout.connect(func() -> void:
		push_error("RETEST PR9 CAPTURE TIMEOUT")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	EmberRunSave.delete_run()
	Engine.max_fps = 30
	print("RETEST_PR9 start")

	await _capture_select_and_p0s()
	await _capture_invalid_save()

	EmberRunSave.delete_run()
	print("RETEST_PR9 NOTES")
	for line in _notes:
		print(line)
	print("RETEST_PR9 CAPTURE DONE")
	quit()


func _capture_select_and_p0s() -> void:
	var app: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	await _frames(4)

	var select := app.find_child("CharacterSelect", true, false)
	if select == null:
		_notes.append("FAIL P1-1: CharacterSelect missing")
		return

	select.call("select_hero", &"ember_hero")
	await _frames(3)
	await _shot("R-P1-1-confirm-deploy")
	var deploy := select.find_child("StartButton", true, false) as Button
	_notes.append("P1-1 deploy_text=%s" % (deploy.text if deploy else "missing"))

	select.call("select_hero", &"assassin")
	await _frames(3)
	await _shot("R-P1-2-assassin-scale")
	await _shot("R-P2-1-locked-caption")
	var assassin_card := select.find_child("Slot_assassin", true, false)
	var locked := select.find_child("Slot_locked_0", true, false)
	var lock_cap := locked.find_child("LockCaption", true, false) as Label if locked != null else null
	_notes.append("P1-2 assassin_zoom=%s" % str(assassin_card.get("portrait_zoom") if assassin_card else "missing"))
	_notes.append("P2-1 lock_caption=%s vis=%s" % [
		lock_cap.text if lock_cap else "missing",
		str(lock_cap.visible) if lock_cap else "missing",
	])

	select.call("confirm_current")
	await _frames(5)
	var hub := app.find_child("HomeHub", true, false)
	if hub == null:
		_notes.append("FAIL P0-2: HomeHub missing after confirm")
		return
	await _shot("R-P0-2-home-switch-btn")
	var change_btn := hub.find_child("HeroSelectButton", true, false) as Button
	_notes.append("P0-2 switch_btn=%s vis=%s hero=%s" % [
		change_btn.text if change_btn else "missing",
		str(change_btn.visible) if change_btn else "missing",
		str(hub.call("selected_hero_id")),
	])

	var pet := hub.find_child("PetButton", true, false) as Button
	if pet != null:
		pet.pressed.emit()
		await _frames(3)
		await _shot("R-P2-2-pet-nest")
		var pet_hint := hub.find_child("PetLockedHint", true, false) as Label
		_notes.append("P2-2 pet_hint=%s vis=%s" % [
			pet_hint.text if pet_hint else "missing",
			str(pet_hint.visible and pet_hint.is_visible_in_tree()) if pet_hint else "missing",
		])

	var start_btn := hub.find_child("StartButton", true, false) as Button
	if start_btn != null:
		start_btn.pressed.emit()
	else:
		hub.call("confirm_new_run")
	await _frames(6)

	var battle := app.find_child("Battlefield", true, false)
	if battle == null:
		_notes.append("FAIL P0-1: Battlefield missing after start")
		return

	battle.call("toggle_speed")
	await _frames(3)
	await _shot("R-P1-3-speed")
	var speed_btn := battle.find_child("SpeedButton", true, false) as Button
	if speed_btn == null:
		# HUD may name it differently
		var hud := battle.find_child("HUD", true, false)
		if hud != null:
			speed_btn = hud.get("speed_button") as Button
	_notes.append("P1-3 speed_text=%s" % (speed_btn.text if speed_btn else "missing"))

	battle.set("scrap", 600)
	var tower: Node = battle.call("_spawn_tower_at", Vector2(456.0, 280.0), &"pulse", 2)
	await _frames(3)
	if tower != null:
		battle.call("_select_tower", tower)
		await _frames(3)
		await _shot("R-P2-3-sell-hint")
		var hint := battle.find_child("TowerHint", true, false) as Label
		if hint == null:
			var hud2 := battle.find_child("HUD", true, false)
			if hud2 != null:
				hint = hud2.get("tower_hint_label") as Label
		_notes.append("P2-3 tower_hint=%s" % (hint.text if hint else "missing"))

	var hero: EmberHero = battle.find_child("HeroController", true, false) as EmberHero
	if hero != null:
		hero.down_duration = 8.0
		hero.set("_hit_invuln", 0.0)
		hero.set("_dash_invuln", 0.0)
		hero.debug_god = false
		hero.take_damage(9999)
		await _frames(4)
		await _shot("R-P1-4-down-banner")
		var banner := battle.find_child("DownBanner", true, false) as Label
		_notes.append("P1-4 down=%s banner=%s vis=%s revives=%s" % [
			str(hero.is_down),
			banner.text if banner else "missing",
			str(banner.visible) if banner else "missing",
			str(hero.revives_left),
		])

	# Force core explode — wait for settlement overlay (do NOT expect instant home).
	battle.set("core_health", 0)
	battle.call("_explode_core")
	var overlay := await _wait_overlay(battle, 2.2)
	if overlay == null:
		_notes.append("P0-1 overlay not after explode; calling _end_run")
		battle.call("_end_run", &"core")
		await _frames(4)
		overlay = battle.find_child("EndOverlay", true, false) as Control
	await _frames(2)
	await _shot("R-P0-1-defeat-overlay")
	var title := battle.find_child("OverlayTitle", true, false) as Label
	var restart := battle.find_child("RestartButton", true, false) as Button
	var finished: Array = []
	if battle.has_signal("run_finished"):
		battle.connect("run_finished", func(result: Dictionary) -> void:
			finished.append(result)
		)
	_notes.append("P0-1 overlay_vis=%s title=%s action=%s home_vis=%s battle_alive=%s" % [
		str(overlay != null and overlay.visible) if overlay != null else "missing",
		title.text if title else "missing",
		restart.text if restart else "missing",
		str(hub.visible),
		str(app.find_child("Battlefield", true, false) != null),
	])

	if restart != null:
		restart.pressed.emit()
	else:
		_notes.append("FAIL P0-1: RestartButton missing — cannot click 返回家园")
	await _frames(6)
	hub = app.find_child("HomeHub", true, false)
	await _shot("R-P0-1-after-return-home")
	var continue_btn := hub.find_child("ContinueButton", true, false) as Button if hub != null else null
	_notes.append("P0-1 after_home vis=%s continue_vis=%s finished=%d battle=%s" % [
		str(hub.visible) if hub else "missing",
		str(continue_btn.visible) if continue_btn else "missing",
		finished.size(),
		str(app.find_child("Battlefield", true, false) != null),
	])

	# P0-2 reselect after return (Continue residual if any).
	change_btn = hub.find_child("HeroSelectButton", true, false) as Button if hub != null else null
	if change_btn != null:
		change_btn.pressed.emit()
	else:
		hub.call("request_hero_select")
	await _frames(5)
	select = app.find_child("CharacterSelect", true, false)
	_notes.append("P0-2 reselect_open=%s hub_vis=%s" % [
		str(select != null),
		str(hub.visible) if hub else "missing",
	])
	if select != null:
		select.call("select_hero", &"ember_hero")
		select.call("confirm_current")
	await _frames(5)
	hub = app.find_child("HomeHub", true, false)
	await _shot("R-P0-2-after-reselect")
	continue_btn = hub.find_child("ContinueButton", true, false) as Button if hub != null else null
	_notes.append("P0-2 after_reselect hero=%s hub_vis=%s continue_vis=%s" % [
		str(hub.call("selected_hero_id")) if hub else "missing",
		str(hub.visible) if hub else "missing",
		str(continue_btn.visible) if continue_btn else "missing",
	])

	app.queue_free()
	await _frames(3)
	EmberRunSave.delete_run()


func _capture_invalid_save() -> void:
	EmberRunSave.delete_run()
	EmberRunSave.write_run({
		"version": 2,
		"mode_id": "endless_td",
		"slots": [],
		"hero": {"hero_id": "ember_hero"},
	})
	var app: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	await _frames(3)
	var select := app.find_child("CharacterSelect", true, false)
	if select != null:
		select.call("select_hero", &"ember_hero")
		select.call("confirm_current")
	await _frames(5)
	var hub := app.find_child("HomeHub", true, false)
	var hint := hub.find_child("InvalidSaveHint", true, false) as Label if hub != null else null
	var cont := hub.find_child("ContinueButton", true, false) as Button if hub != null else null
	await _shot("R-P1-5-invalid-start")
	_notes.append("P1-5 hint=%s vis=%s continue_vis=%s" % [
		hint.text if hint else "missing",
		str(hint.visible) if hint else "missing",
		str(cont.visible) if cont else "missing",
	])
	if hub != null:
		hub.call("confirm_new_run")
	await _frames(5)
	var overwrite := app.find_child("OverwriteConfirm", true, false)
	var battle := app.find_child("Battlefield", true, false)
	_notes.append("P1-5 overwrite=%s battle=%s" % [
		str(overwrite != null and overwrite.visible) if overwrite != null else "none",
		str(battle != null),
	])
	app.queue_free()
	await _frames(2)
	EmberRunSave.delete_run()


func _wait_overlay(battle: Node, seconds: float) -> Control:
	var left := seconds
	while left > 0.0:
		await process_frame
		left -= 1.0 / 30.0
		var overlay := battle.find_child("EndOverlay", true, false) as Control
		if overlay != null and overlay.visible:
			return overlay
	return battle.find_child("EndOverlay", true, false) as Control


func _shot(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("CAPTURE FAIL %s: no image" % stem)
		_notes.append("SHOT_FAIL %s" % stem)
		return
	var png := "%s/%s.png" % [OUT, stem]
	var webp := "%s/%s.webp" % [OUT, stem]
	var err := image.save_png(png)
	var werr := image.save_webp(webp, false, 0.82)
	print("CAPTURE %s png=%s webp=%s %dx%d" % [stem, err, werr, image.get_width(), image.get_height()])


func _frames(n: int) -> void:
	for _i: int in range(n):
		await process_frame

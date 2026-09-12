extends SceneTree
const OUT := "res://dogfood-output/mech-p2-retest"
func _init() -> void:
	call_deferred("r")
func r() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	EmberRunSave.delete_run()
	EmberRunSave.write_run({"version": 2, "mode_id": "endless_td", "slots": [], "hero": {"hero_id": "assassin", "hero_kind": "assassin"}})
	assert(FileAccess.file_exists(EmberRunSave.RUN_PATH))
	assert(EmberRunSave.load_run().is_empty())
	var app: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	for _i in 2:
		await process_frame
	var select := app.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	for _i in 5:
		await process_frame
	var hub := app.find_child("HomeHub", true, false)
	var cont := hub.find_child("ContinueButton", true, false) as Button
	var hint := hub.find_child("InvalidSaveHint", true, false) as Label
	print("BAD cont_vis=%s hint_vis=%s hint_text=%s in_tree=%s" % [cont.visible, hint.visible, hint.text, hint.is_visible_in_tree()])
	assert(not cont.visible)
	assert(hint.visible and hint.is_visible_in_tree() and String(hint.text).contains("存档无效"))
	await _shot("01-bad-save-hint")
	app.queue_free()
	for _i in 3:
		await process_frame
	EmberRunSave.delete_run()
	assert(not FileAccess.file_exists(EmberRunSave.RUN_PATH))
	app = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	for _i in 2:
		await process_frame
	select = app.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	for _i in 5:
		await process_frame
	hub = app.find_child("HomeHub", true, false)
	cont = hub.find_child("ContinueButton", true, false) as Button
	hint = hub.find_child("InvalidSaveHint", true, false) as Label
	print("CLEAN cont_vis=%s hint_vis=%s in_tree=%s" % [cont.visible, hint.visible, hint.is_visible_in_tree()])
	assert(not cont.visible)
	assert(not hint.visible)
	assert(not hint.is_visible_in_tree())
	await _shot("02-clean-home-no-hint")
	app.queue_free()
	for _i in 3:
		await process_frame
	EmberRunSave.write_run({
		"version": 2, "mode_id": "endless_td", "run_seed": 1,
		"cleared_wave": 1, "scrap": 100, "core_health": 10, "run_time": 1.0, "defeated_count": 0,
		"hero": {"hero_id": "assassin", "hero_kind": "assassin", "health": 90, "weapon": "sword", "weapons": ["sword", ""], "position": [640.0, 336.0],
			"progression": {"level": 1, "xp": 0, "pending_choices": 0, "talent_counts": {}, "talent_rng_state": 1, "legacy_bonus_health": 0, "legacy_dash_cooldown_level": 0, "legacy_bonus_armor": 0, "skill_rank": 0}},
		"towers": [], "drop_rng_state": 1, "shop_rng_state": 1,
		"slots": [{"kind": "tower", "payload": "pulse", "cost": 80, "sold": false, "vendor": "merchant", "title": "脉冲塔"}],
		"shop": {},
	})
	assert(not EmberRunSave.load_run().is_empty())
	app = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	for _i in 2:
		await process_frame
	select = app.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	for _i in 5:
		await process_frame
	hub = app.find_child("HomeHub", true, false)
	cont = hub.find_child("ContinueButton", true, false) as Button
	hint = hub.find_child("InvalidSaveHint", true, false) as Label
	print("VALID cont_vis=%s hint_vis=%s" % [cont.visible, hint.visible])
	assert(cont.visible)
	assert(not hint.visible)
	await _shot("03-valid-save-continue")
	print("P2 RETEST PASS")
	app.queue_free()
	EmberRunSave.delete_run()
	quit()

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("%s/%s.png" % [OUT, name])
		print("SHOT ", name)

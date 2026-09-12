extends SceneTree
const OUT := "res://dogfood-output/visual-accept-r3"
const LIVE_RUN := "user://run.json"
const LIVE_BAK := "user://run.json.visual_bak"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_protect_run()
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
				"level": 2, "xp": 5, "pending_choices": 0,
				"talent_counts": {}, "talent_rng_state": 1,
				"legacy_bonus_health": 0, "legacy_dash_cooldown_level": 0,
				"legacy_bonus_armor": 0, "skill_rank": 0,
			},
		},
		"towers": [],
		"drop_rng_state": 1,
		"shop_rng_state": 1,
		"slots": [{
			"kind": "tower", "payload": "pulse", "cost": 80,
			"sold": false, "vendor": "merchant", "title": "脉冲塔",
		}],
		"shop": {},
	})
	print("LOAD_AFTER_WRITE empty=", EmberRunSave.load_run().is_empty())
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await _frames(2)
	var select := root_scene.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await _frames(4)
	var hub := root_scene.find_child("HomeHub", true, false)
	var continue_btn := hub.find_child("ContinueButton", true, false) as Button
	var start_btn := hub.find_child("StartButton", true, false) as Button
	print("CONTINUE_VIS visible=%s start=%s resumable_empty_check load=%s" % [
		continue_btn.visible if continue_btn else null,
		start_btn.visible if start_btn else null,
		EmberRunSave.load_run().is_empty(),
	])
	assert(continue_btn != null and continue_btn.visible, "continue must show with valid run.json")
	await _save_vp("15-home-continue-visible")
	continue_btn.pressed.emit()
	await _frames(5)
	await _save_vp("16-continue-restored-battle")
	var hero := root_scene.find_child("HeroController", true, false) as EmberHero
	assert(hero != null and hero.hero_kind == &"assassin", "continue must restore assassin")
	var hub2 := root_scene.find_child("HomeHub", true, false)
	var start2 := hub2.find_child("StartButton", true, false) as Button if hub2 else null
	print("AFTER_CONTINUE home.visible=%s start.in_tree=%s" % [
		hub2.visible if hub2 else null,
		start2.is_visible_in_tree() if start2 else null,
	])
	# crop evidence of leak after continue
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()
	_restore_run()
	print("CONTINUE CAPTURE DONE")
	quit()

func _save_vp(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUT, name]
	var err := image.save_png(path)
	print("CAPTURE %s err=%s" % [name, err])

func _frames(n: int) -> void:
	for _i in range(n):
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

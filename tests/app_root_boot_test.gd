extends SceneTree

const EmberRunSave := preload("res://scripts/run_save.gd")
const EmberHero := preload("res://scripts/hero.gd")
const EmberMetaSave := preload("res://scripts/meta_save.gd")

const LIVE_RUN := "user://run.json"
const LIVE_RUN_BAK := "user://run.json.boot_bak"


func _init() -> void:
	create_timer(120.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	_protect_live_run()
	EmberMetaSave.delete_profile(EmberMetaSave.SMOKE_PATH)
	assert(FileAccess.file_exists("res://scenes/app_root.tscn"), "app_root scene exists")

	await _knight_select_home_start()
	await _assassin_select_home_start()
	await _continue_expedition_restores_run()
	await _invalid_save_shows_hint()

	EmberRunSave.delete_run()
	_restore_live_run()
	print("APP ROOT BOOT PASS")
	quit()


func _knight_select_home_start() -> void:
	EmberRunSave.delete_run()
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "AppRoot boots into character select")
	assert(root_scene.find_child("HomeHub", true, false) == null, "home waits until a hero is confirmed")
	var title := select.find_child("Title", true, false) as Label
	assert(title != null and title.text == "角色选择", "select title is CJK, not tofu")
	var skin := select.find_child("SkinButton", true, false) as Button
	assert(skin != null and skin.text == "皮肤", "select card has a skin chip")
	select.call("select_hero", &"ember_hero")
	select.call("_on_skin")
	var picker := select.find_child("SkinPicker", true, false)
	assert(picker != null, "skin chip opens the imported-pack list")
	assert(picker.find_child("SkinChip_ember_hero", true, false) != null, "skin picker shows a portrait chip")
	select.call("_hide_skin_picker")
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "confirming a hero opens HomeHub")
	assert(root_scene.find_child("HeroController", true, false) == null, "home does not instance the battlefield hero")
	hub.call("confirm_new_run")
	await process_frame
	await process_frame
	var hero := root_scene.find_child("HeroController", true, false)
	assert(hero != null, "new run from home adds the battlefield")
	assert((hero as EmberHero).hero_kind == &"ember_hero", "home start launches the default knight")
	var start_after := hub.find_child("StartButton", true, false) as Button
	var continue_after := hub.find_child("ContinueButton", true, false) as Button
	var hud_layer := hub.find_child("HUD", true, false)
	assert(not hub.visible, "home Node2D hides after start")
	assert(hud_layer != null and not hud_layer.visible, "home HUD CanvasLayer must hide; Node2D.visible does not cover it")
	assert(start_after != null and not start_after.is_visible_in_tree(), "开始远征 must not stay in the battlefield tree")
	assert(continue_after == null or not continue_after.is_visible_in_tree(), "继续远征 must not leak into a new battle")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _assassin_select_home_start() -> void:
	EmberRunSave.delete_run()
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "assassin path also boots into character select")
	select.call("select_hero", &"assassin")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "confirming assassin opens HomeHub")
	assert(hub.call("selected_hero_id") == &"assassin", "home launch hero is the confirmed assassin")
	var start_btn := hub.find_child("StartButton", true, false) as Button
	assert(start_btn != null and start_btn.visible, "开始远征 is wired on HomeHub")
	start_btn.pressed.emit()
	await process_frame
	await process_frame
	var hero := root_scene.find_child("HeroController", true, false)
	assert(hero != null, "assassin start from AppRoot adds the battlefield")
	assert((hero as EmberHero).hero_kind == &"assassin", "StartButton launches the confirmed assassin")
	assert((hero as EmberHero).max_health == 105, "assassin lv1 max HP is 105")
	assert(not hub.visible, "assassin start hides the home node")
	assert(not start_btn.is_visible_in_tree(), "StartButton CanvasLayer must hide when entering battle")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _continue_expedition_restores_run() -> void:
	EmberRunSave.delete_run()
	EmberRunSave.write_run(_assassin_resume_payload())
	var loaded: Dictionary = EmberRunSave.load_run()
	assert(not loaded.is_empty(), "continue path needs a real v2 run.json")
	assert(String((loaded.get("hero", {}) as Dictionary).get("hero_id", "")) == "assassin", "disk run is assassin")

	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "continue still goes through character select first")
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "knight confirm reaches home before continue")
	assert(hub.call("selected_hero_id") == &"ember_hero", "profile last hero is knight")
	var continue_btn := hub.find_child("ContinueButton", true, false) as Button
	assert(continue_btn != null and continue_btn.visible, "继续远征 is wired when run.json exists")
	var valid_hint := hub.find_child("InvalidSaveHint", true, false) as Label
	assert(valid_hint == null or not valid_hint.visible, "valid save does not show the invalid-save hint")
	continue_btn.pressed.emit()
	await process_frame
	await process_frame
	var battle := root_scene.find_child("Battlefield", true, false)
	assert(battle != null, "continue through AppRoot instances the battlefield")
	var hero := root_scene.find_child("HeroController", true, false)
	assert(hero != null, "continued run restores a battlefield hero")
	assert((hero as EmberHero).hero_kind == &"assassin", "continue restores the run.json hero, not the last selected knight")
	assert(int(battle.get("scrap")) == 444, "continue restores scrap from run.json")
	assert(int(battle.get("current_wave")) == 3, "continue restores cleared_wave")
	var start_btn := hub.find_child("StartButton", true, false) as Button
	var hud_layer := hub.find_child("HUD", true, false)
	assert(not hub.visible, "continue hides the home node")
	assert(hud_layer != null and not hud_layer.visible, "continue must hide the home HUD CanvasLayer")
	assert(start_btn != null and not start_btn.is_visible_in_tree(), "开始远征 must not remain after continue-into-battle")
	assert(not continue_btn.is_visible_in_tree(), "继续远征 must not remain after continue-into-battle")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _invalid_save_shows_hint() -> void:
	EmberRunSave.delete_run()
	EmberRunSave.write_run({
		"version": 2,
		"mode_id": "endless_td",
		"slots": [],
		"hero": {"hero_id": "ember_hero"},
	})
	assert(FileAccess.file_exists(EmberRunSave.RUN_PATH), "empty-slots payload remains on disk")
	assert(EmberRunSave.load_run().is_empty(), "empty slots is rejected by load_run")

	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "invalid-save path still goes through character select")
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "invalid-save path still opens HomeHub")
	var continue_btn := hub.find_child("ContinueButton", true, false) as Button
	var hint := hub.find_child("InvalidSaveHint", true, false) as Label
	assert(continue_btn != null and not continue_btn.visible, "继续远征 stays hidden for a rejected save")
	assert(hint != null and hint.visible, "invalid-save hint is visible when load_run rejects disk")
	assert(hint.text.contains("存档无效"), "invalid-save hint copy")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _assassin_resume_payload() -> Dictionary:
	return {
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
	}


func _protect_live_run() -> void:
	_restore_live_run()
	if not FileAccess.file_exists(LIVE_RUN):
		return
	var src := FileAccess.open(LIVE_RUN, FileAccess.READ)
	if src == null:
		return
	var text := src.get_as_text()
	src.close()
	var bak := FileAccess.open(LIVE_RUN_BAK, FileAccess.WRITE)
	if bak != null:
		bak.store_string(text)
		bak.close()
	EmberRunSave.delete_run()


func _restore_live_run() -> void:
	if not FileAccess.file_exists(LIVE_RUN_BAK):
		return
	var bak := FileAccess.open(LIVE_RUN_BAK, FileAccess.READ)
	if bak == null:
		return
	var text := bak.get_as_text()
	bak.close()
	var live := FileAccess.open(LIVE_RUN, FileAccess.WRITE)
	if live != null:
		live.store_string(text)
		live.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LIVE_RUN_BAK))

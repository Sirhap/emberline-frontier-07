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
	await _defeat_shows_settlement_before_home()
	await _hero_death_shows_settlement_title()
	await _home_can_return_to_character_select()
	await _reselect_cancel_returns_home()
	await _hero_switch_start_vs_continue()

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
	var deploy := select.find_child("StartButton", true, false) as Button
	assert(deploy != null and deploy.text == "确认出战", "deploy chip is an action (01/03), not 已出战 status")
	var boot_cancel := select.find_child("CancelButton", true, false) as Button
	assert(boot_cancel != null and not boot_cancel.visible, "cold boot select has no 返回 home cancel")
	var assassin_card := select.find_child("Slot_assassin", true, false)
	assert(assassin_card != null and float(assassin_card.get("portrait_zoom")) >= 1.4, "assassin portrait is enlarged (01/02)")
	var locked := select.find_child("Slot_locked_0", true, false)
	var lock_caption := locked.find_child("LockCaption", true, false) as Label if locked != null else null
	assert(lock_caption != null and lock_caption.visible and lock_caption.text.contains("暂未开放"), "locked slots show 暂未开放 (03)")
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
	hub.call("confirm_new_run")
	await process_frame
	await process_frame
	assert(root_scene.find_child("OverwriteConfirm", true, false) == null, "invalid save must not prompt 覆盖当前远征 (05)")
	assert(root_scene.find_child("Battlefield", true, false) != null, "invalid save start begins a new run")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _defeat_shows_settlement_before_home() -> void:
	EmberRunSave.delete_run()
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "defeat path boots into character select")
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "defeat path opens HomeHub first")
	hub.call("confirm_new_run")
	await process_frame
	await process_frame
	var battle := root_scene.find_child("Battlefield", true, false)
	assert(battle != null, "开始远征 instances the battlefield")
	var finished: Array = []
	battle.connect("run_finished", func(result: Dictionary) -> void:
		finished.append(result)
	)
	battle.call("_end_run", &"core")
	await process_frame
	await process_frame
	assert(finished.is_empty(), "AppRoot must not jump home before the settlement overlay")
	var overlay := battle.find_child("EndOverlay", true, false) as Control
	assert(overlay != null and overlay.visible, "core loss must show EndOverlay (09b-defeat-moment)")
	var title := battle.find_child("OverlayTitle", true, false) as Label
	assert(title != null and title.text == "核心失守", "settlement title is 核心失守")
	var restart := battle.find_child("RestartButton", true, false) as Button
	assert(restart != null and restart.visible, "settlement has a return action")
	assert(restart.text == "返回家园", "launched defeat uses 返回家园, not instant home")
	assert(hub != null and not hub.visible, "home stays hidden under the settlement")
	assert(root_scene.find_child("Battlefield", true, false) == battle, "battlefield stays until the player confirms")
	restart.pressed.emit()
	await process_frame
	await process_frame
	assert(finished.size() == 1, "return home emits run_finished once")
	assert(String(finished[0].get("reason", "")) == "core", "settlement confirm keeps the core-loss reason")
	assert(root_scene.find_child("Battlefield", true, false) == null, "return home frees the battlefield")
	hub = root_scene.find_child("HomeHub", true, false)
	assert(hub != null and hub.visible, "return home shows HomeHub after settlement")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _home_can_return_to_character_select() -> void:
	EmberRunSave.delete_run()
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "boot still opens character select")
	select.call("select_hero", &"assassin")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "assassin confirm reaches home")
	assert(hub.call("selected_hero_id") == &"assassin", "home last hero is assassin")
	var change_btn := hub.find_child("HeroSelectButton", true, false) as Button
	assert(change_btn != null and change_btn.visible, "home has 更换人物 (05-home-hub)")
	assert(change_btn.text == "更换人物", "home hero-switch label")
	change_btn.pressed.emit()
	await process_frame
	await process_frame
	select = root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "更换人物 reopens character select")
	assert(hub != null and not hub.visible, "home hides while picking a new hero")
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	hub = root_scene.find_child("HomeHub", true, false)
	assert(hub != null and hub.visible, "confirming a new hero returns to home")
	assert(hub.call("selected_hero_id") == &"ember_hero", "home launch hero updates after reselect")
	assert(root_scene.find_child("CharacterSelect", true, false) == null, "select closes after confirm")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _hero_death_shows_settlement_title() -> void:
	EmberRunSave.delete_run()
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	hub.call("confirm_new_run")
	await process_frame
	await process_frame
	var battle := root_scene.find_child("Battlefield", true, false)
	assert(battle != null, "开始远征 instances the battlefield for hero death")
	var finished: Array = []
	battle.connect("run_finished", func(result: Dictionary) -> void:
		finished.append(result)
	)
	battle.call("notify_hero_defeated")
	await process_frame
	await process_frame
	assert(finished.is_empty(), "hero death must not jump home before settlement")
	var overlay := battle.find_child("EndOverlay", true, false) as Control
	assert(overlay != null and overlay.visible, "downs exhausted shows EndOverlay")
	var title := battle.find_child("OverlayTitle", true, false) as Label
	assert(title != null and title.text == "英雄阵亡", "hero death settlement title is 英雄阵亡")
	var restart := battle.find_child("RestartButton", true, false) as Button
	assert(restart != null and restart.text == "返回家园", "hero death uses 返回家园")
	restart.pressed.emit()
	await process_frame
	await process_frame
	assert(finished.size() == 1, "return home emits run_finished once")
	assert(String(finished[0].get("reason", "")) == "hero", "settlement keeps the hero-death reason")
	assert(root_scene.find_child("Battlefield", true, false) == null, "return home frees the battlefield")
	hub = root_scene.find_child("HomeHub", true, false)
	assert(hub != null and hub.visible, "return home shows HomeHub after hero death")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _reselect_cancel_returns_home() -> void:
	EmberRunSave.delete_run()
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"assassin")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null and hub.call("selected_hero_id") == &"assassin", "home last hero is assassin")
	var change_btn := hub.find_child("HeroSelectButton", true, false) as Button
	change_btn.pressed.emit()
	await process_frame
	await process_frame
	select = root_scene.find_child("CharacterSelect", true, false)
	assert(select != null and select.visible, "更换人物 opens select")
	var cancel := select.find_child("CancelButton", true, false) as Button
	assert(cancel != null and cancel.visible, "reselect shows 返回")
	assert(cancel.text == "返回", "reselect cancel label")
	select.call("select_hero", &"ember_hero")
	cancel.pressed.emit()
	await process_frame
	await process_frame
	assert(select != null and not select.visible, "cancel hides select without confirm")
	hub = root_scene.find_child("HomeHub", true, false)
	assert(hub != null and hub.visible, "cancel returns home")
	assert(hub.call("selected_hero_id") == &"assassin", "cancel does not write last_selected_hero")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _hero_switch_start_vs_continue() -> void:
	EmberRunSave.delete_run()
	EmberRunSave.write_run(_assassin_resume_payload())
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub.call("selected_hero_id") == &"ember_hero", "profile last hero is knight")
	var continue_btn := hub.find_child("ContinueButton", true, false) as Button
	assert(continue_btn != null and continue_btn.visible, "valid run.json still shows 继续远征")
	var change_btn := hub.find_child("HeroSelectButton", true, false) as Button
	change_btn.pressed.emit()
	await process_frame
	await process_frame
	select = root_scene.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"assassin")
	select.call("confirm_current")
	await process_frame
	await process_frame
	hub = root_scene.find_child("HomeHub", true, false)
	assert(hub != null and hub.visible, "confirming a new hero returns home")
	assert(hub.call("selected_hero_id") == &"assassin", "Start will use the newly confirmed assassin")
	continue_btn = hub.find_child("ContinueButton", true, false) as Button
	assert(continue_btn != null and continue_btn.visible, "Continue stays for the old run.json")
	continue_btn.pressed.emit()
	await process_frame
	await process_frame
	var battle := root_scene.find_child("Battlefield", true, false)
	var hero := root_scene.find_child("HeroController", true, false)
	assert(hero != null, "Continue launches the stored run")
	assert((hero as EmberHero).hero_kind == &"assassin", "Continue keeps the old run hero")
	assert(int(battle.get("scrap")) == 444, "Continue restores the old run scrap")
	assert(int(battle.get("current_wave")) == 3, "Continue restores the old run wave")
	root_scene.queue_free()
	await process_frame

	EmberRunSave.write_run(_assassin_resume_payload())
	root_scene = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	select = root_scene.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"assassin")
	select.call("confirm_current")
	await process_frame
	await process_frame
	hub = root_scene.find_child("HomeHub", true, false)
	change_btn = hub.find_child("HeroSelectButton", true, false) as Button
	change_btn.pressed.emit()
	await process_frame
	await process_frame
	select = root_scene.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	hub = root_scene.find_child("HomeHub", true, false)
	assert(hub.call("selected_hero_id") == &"ember_hero", "reselect wrote knight for Start")
	hub.call("confirm_new_run")
	await process_frame
	await process_frame
	var confirm := root_scene.find_child("OverwriteConfirm", true, false)
	assert(confirm != null and confirm.visible, "Start with a valid run asks to overwrite")
	var overwrite: Button
	for child: Node in confirm.get_children():
		overwrite = _find_button_with_text(child, "覆盖并出发")
		if overwrite != null:
			break
	assert(overwrite != null, "overwrite confirm has 覆盖并出发")
	overwrite.pressed.emit()
	await process_frame
	await process_frame
	battle = root_scene.find_child("Battlefield", true, false)
	hero = root_scene.find_child("HeroController", true, false)
	assert(hero != null, "Start after overwrite launches a new run")
	assert((hero as EmberHero).hero_kind == &"ember_hero", "Start uses the new knight, not the old assassin run")
	assert(int(battle.get("scrap")) == 300, "Start is a fresh run, not the old 444 scrap")
	assert(EmberRunSave.load_run().is_empty() or int(EmberRunSave.load_run().get("scrap", 300)) != 444, "old run.json is not the live battle")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()


func _find_button_with_text(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child: Node in node.get_children():
		var found := _find_button_with_text(child, text)
		if found != null:
			return found
	return null


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

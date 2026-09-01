extends SceneTree

const HomeHub := preload("res://scripts/home_hub.gd")
const SCENE_PATH := "res://scenes/home/home_hub.tscn"


func _init() -> void:
	create_timer(40.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	var hub: Node2D
	if ResourceLoader.exists(SCENE_PATH):
		hub = load(SCENE_PATH).instantiate() as Node2D
	else:
		hub = HomeHub.new()
	assert(hub != null, "HomeHub scene or script should instantiate")
	root.add_child(hub)
	await process_frame

	hub.configure({}, {})
	assert(hub.selected_hero_id() == &"ember_hero", "empty profile launches the knight")

	var run_emits: Array = []
	hub.new_run_requested.connect(func(hero_id: StringName, mode_id: StringName) -> void:
		run_emits.append({"hero": hero_id, "mode": mode_id})
	)
	var continue_emits: Array = []
	hub.continue_requested.connect(func() -> void:
		continue_emits.append(true)
	)

	var started: String = hub.confirm_new_run()
	assert(started == "", "confirm_new_run should succeed without a hero pick")
	assert(run_emits.size() == 1, "confirm_new_run emits once")
	assert(run_emits[0]["hero"] == &"ember_hero", "new run uses the default knight")
	assert(run_emits[0]["mode"] == &"endless_td", "stub mode is endless_td")

	hub.configure({"last_selected_hero": "ember_hero"}, {})
	assert(hub.selected_hero_id() == &"ember_hero", "last knight stays knight")
	assert(hub.confirm_new_run() == "")
	assert(run_emits.size() == 2)
	assert(run_emits[1]["hero"] == &"ember_hero")

	hub.configure({"last_selected_hero": "assassin"}, {})
	assert(hub.selected_hero_id() == &"assassin", "last assassin launches assassin")
	assert(hub.confirm_new_run() == "")
	assert(run_emits.size() == 3)
	assert(run_emits[2]["hero"] == &"assassin")
	assert(run_emits[2]["mode"] == &"endless_td")

	hub.configure({"last_selected_hero": "bogus"}, {})
	assert(hub.selected_hero_id() == &"ember_hero", "unknown last hero falls back to knight")
	assert(hub.confirm_new_run() == "")
	assert(run_emits.size() == 4)
	assert(run_emits[3]["hero"] == &"ember_hero")

	hub.configure({}, {"hero": {"hero_id": "assassin"}})
	hub.request_continue()
	assert(continue_emits.size() == 1, "request_continue emits when resumable_run is set")
	hub.request_continue()
	assert(continue_emits.size() == 2, "resumable continue can fire again")
	hub.configure({}, {})
	hub.request_continue()
	assert(continue_emits.size() == 2, "empty resumable_run is a no-op")

	assert(hub.pet_prompt() == "宠物系统暂未开放", "pet nest is locked")

	assert(hub.find_child("KnightPedestal", true, false) == null, "hub has no knight pedestal")
	assert(hub.find_child("AssassinPedestal", true, false) == null, "hub has no assassin pedestal")
	assert(hub.find_child("KnightPedestalBody", true, false) == null, "hub has no knight idle body")
	assert(hub.find_child("AssassinPedestalBody", true, false) == null, "hub has no assassin idle body")
	assert(hub.find_child("Preview", true, false) == null, "hub has no hero preview stand")
	assert(hub.find_child("PreviewBody", true, false) == null, "hub has no preview idle sprite")
	assert(hub.find_child("KnightPlinth", true, false) == null, "room has no knight plinth")
	assert(hub.find_child("AssassinPlinth", true, false) == null, "room has no assassin plinth")
	assert(hub.has_method("confirm_hero") == false, "hero pick API is gone")
	assert(hub.has_method("is_selection_confirmed") == false, "selection state is gone")
	assert(hub.has_method("try_open_portal") == false, "portal start API is gone")
	assert(hub.find_child("EndlessPortal", true, false) == null, "hub has no portal click target")
	assert(hub.find_child("PortalButton", true, false) == null, "hub has no portal button")
	assert(hub.find_child("PortalVisual", true, false) == null, "room has no portal arch")

	var floor_node := hub.find_child("Floor", true, false)
	assert(floor_node is Sprite2D, "floor must be a Sprite2D, not a solid ColorRect")
	var floor_sprite := floor_node as Sprite2D
	assert(floor_sprite.texture != null, "home floor texture must load")
	var floor_path := String(floor_sprite.texture.resource_path)
	assert(floor_path.contains("assets/generated/home/"), "home floor lives under assets/generated/home/")
	assert(not floor_path.contains("grid-battlefield"), "home must not reuse the combat floor")
	assert(hub.find_child("HomeRoom", true, false) != null, "visuals live in a dedicated HomeRoom node")
	assert(hub.find_child("CoderDesk", true, false) is Sprite2D, "coder desk is a stamped sprite")
	assert(hub.find_child("Bookshelf", true, false) is Sprite2D, "bookshelf is a stamped sprite")
	assert(hub.find_child("Bestiary", true, false) is Sprite2D, "enemy cabinet is a stamped sprite")
	assert(hub.find_child("Monument", true, false) is Sprite2D, "records statue is a stamped sprite")
	assert(hub.find_child("PetBed", true, false) is Sprite2D, "sofa is a stamped sprite")
	assert(hub.find_child("Coffee", true, false) is Sprite2D, "coffee station is a stamped sprite")
	var desk_tex := (hub.find_child("CoderDesk", true, false) as Sprite2D).texture
	assert(desk_tex != null and String(desk_tex.resource_path).contains("desk-coder"), "desk is the station-pack cutout")
	assert(floor_path.contains("floor-room"), "empty hall is floor-room.png")
	assert(not floor_path.contains("layout-ref"), "do not use the full layout-ref as the floor")
	assert(hub.find_child("TitleLabel", true, false) == null, "hub has no title caption")
	assert(hub.find_child("HintLabel", true, false) == null, "hub has no bottom subtitle")
	assert(hub.find_child("PortalCaption", true, false) == null, "hub has no portal caption")
	assert(hub.find_child("WeaponCodex", true, false) != null, "weapon station hitbox remains")
	assert(hub.find_child("EnemyCodex", true, false) != null, "enemy station hitbox remains")
	assert(hub.find_child("Records", true, false) != null, "records station hitbox remains")
	assert(hub.find_child("PetNest", true, false) != null, "pet nest hitbox remains")

	assert(hub.find_child("MoveStick", true, false) == null, "home has no virtual stick")
	assert(hub.find_child("XSXBHeroActor", true, false) == null, "do not instance EmberHero in the hub stub")
	assert(hub.find_child("PreviewPortrait", true, false) == null, "hub has no HUD portrait")

	var start_btn := hub.find_child("StartButton", true, false) as Button
	assert(start_btn != null, "start expedition is clickable")
	assert(start_btn.text == "开始远征", "start button label")
	assert(start_btn.visible, "start button stays on the hub")
	_assert_touch_target(start_btn)
	start_btn.pressed.emit()
	assert(run_emits.size() == 5, "start button emits new_run_requested")
	assert(run_emits[4]["hero"] == &"ember_hero")

	var continue_btn := hub.find_child("ContinueButton", true, false) as Button
	assert(continue_btn != null, "continue expedition exists")
	hub.configure({}, {"hero": {"hero_id": "assassin"}})
	assert(continue_btn.visible, "continue shows when a run can resume")
	hub.configure({}, {})
	assert(not continue_btn.visible, "continue hides without a save")

	var weapon_btn := hub.find_child("WeaponCodexButton", true, false) as Button
	var enemy_btn := hub.find_child("EnemyCodexButton", true, false) as Button
	var records_btn := hub.find_child("RecordsButton", true, false) as Button
	assert(weapon_btn != null, "weapon station is clickable")
	assert(enemy_btn != null, "enemy station is clickable")
	assert(records_btn != null, "records station is clickable")
	_assert_touch_target(weapon_btn)
	_assert_touch_target(enemy_btn)
	_assert_touch_target(records_btn)

	var panel := hub.find_child("CodexPanel", true, false)
	assert(panel != null, "hub owns a CodexPanel")
	assert(not panel.visible, "codex starts closed")
	hub.call("open_weapon_codex")
	assert(panel.visible, "weapon station opens the panel")
	var title := panel.find_child("PanelTitle", true, false) as Label
	assert(title != null and title.text == "兵器图鉴", "weapon station title")
	hub.call("open_enemy_codex")
	assert(title.text == "敌人图鉴", "enemy station title")
	hub.call("open_records")
	assert(title.text == "战绩碑", "records station title")
	panel.call("hide_panel")
	assert(not panel.visible, "close returns to the hub")

	print("HOME HUB SMOKE PASS")
	quit()


func _assert_touch_target(node: Node) -> void:
	var control := _as_control(node)
	assert(control != null, "%s should be or contain a Control" % node.name)
	assert(control.custom_minimum_size.x >= 48.0 and control.custom_minimum_size.y >= 48.0, "%s touch target must be at least 48x48" % node.name)


func _as_control(node: Node) -> Control:
	if node is Control:
		return node as Control
	for child in node.get_children():
		if child is Control:
			return child as Control
	return null

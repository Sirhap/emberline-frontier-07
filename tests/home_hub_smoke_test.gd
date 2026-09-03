extends SceneTree

const EmberHero := preload("res://scripts/hero.gd")
const HomeHub := preload("res://scripts/home_hub.gd")
const SCENE_PATH := "res://scenes/home/home_hub.tscn"
const WALKER_AWAY := Vector2(280, 560)


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
	var room := hub.find_child("HomeRoom", true, false) as HomeRoom
	assert(room != null, "visuals live in a dedicated HomeRoom node")
	assert(hub.find_child("CoderDesk", true, false) is Sprite2D, "coder desk is a stamped sprite")
	assert(hub.find_child("Bookshelf", true, false) is Sprite2D, "bookshelf is a stamped sprite")
	assert(hub.find_child("Bestiary", true, false) is Sprite2D, "BUG sign is a stamped sprite")
	assert(hub.find_child("Monument", true, false) is Sprite2D, "whiteboard is a stamped sprite")
	assert(hub.find_child("PetBed", true, false) is Sprite2D, "beanbag is a stamped sprite")
	var desk_tex := (hub.find_child("CoderDesk", true, false) as Sprite2D).texture
	assert(desk_tex != null and String(desk_tex.resource_path).contains("desk-coder"), "desk is the original station-pack coder")
	var shelf_tex := (hub.find_child("Bookshelf", true, false) as Sprite2D).texture
	assert(shelf_tex != null and String(shelf_tex.resource_path).contains("/office/"), "bookshelf is the office-sheet cutout")
	assert(not String((hub.find_child("Monument", true, false) as Sprite2D).texture.resource_path).contains("monument.png"), "do not use the farm angel")
	assert(not String((hub.find_child("PetBed", true, false) as Sprite2D).texture.resource_path).contains("sofa.png"), "do not use the farm sofa")
	var coffee_tex := (hub.find_child("Coffee", true, false) as Sprite2D).texture
	assert(coffee_tex != null and String(coffee_tex.resource_path).contains("coffee.png"), "coffee station is the station-pack original")
	assert(hub.find_child("TvStand", true, false) == null, "layout-ref has no TV cluster")
	assert(hub.find_child("Sofa", true, false) == null, "layout-ref uses the beanbag, not the office sofa")
	assert(hub.find_child("WaterCooler", true, false) is Sprite2D, "water cooler comes from the office sheet")
	assert(hub.find_child("OvertimeSign", true, false) is Sprite2D, "overtime neon comes from the office sheet")
	assert(hub.find_child("NightProps", true, false) is Node2D, "night props are grouped")
	assert(hub.find_child("DayProps", true, false) is Node2D, "day props are grouped")
	assert(hub.find_child("Workbench", true, false) is Sprite2D, "day uses the station-pack workbench")
	assert(hub.find_child("DayPanda", true, false) is Sprite2D, "day swaps in leftover office mascots")
	assert(hub.find_child("DayFridge", true, false) is Sprite2D, "day uses the snack vending instead of the night fridge")
	var night_props := hub.find_child("NightProps", true, false) as Node2D
	var day_props := hub.find_child("DayProps", true, false) as Node2D
	assert(is_equal_approx(night_props.modulate.a, 1.0) and is_equal_approx(day_props.modulate.a, 0.0), "night props start visible")
	assert(floor_path.contains("floor-room"), "empty hall is floor-room.png")
	assert(not floor_path.contains("layout-ref"), "do not use the full layout-ref as the floor")
	var day_floor := hub.find_child("DayFloor", true, false) as Sprite2D
	assert(day_floor != null and day_floor.texture != null, "daylight floor must load")
	assert(String(day_floor.texture.resource_path).ends_with("floor-room-day.png"), "daylight uses the supplied room image")
	assert(not room.is_daylight(), "home starts with the existing night floor")
	assert(is_equal_approx(floor_sprite.modulate.a, 1.0) and is_equal_approx(day_floor.modulate.a, 0.0), "night starts fully visible")
	var lighting_events: Array[bool] = []
	room.lighting_changed.connect(func(daylight: bool) -> void:
		lighting_events.append(daylight)
	)
	var lantern_btn := hub.find_child("LanternToggleButton", true, false) as Button
	assert(lantern_btn != null, "the baked lantern has a click target")
	_assert_touch_target(lantern_btn)
	lantern_btn.pressed.emit()
	assert(room.is_lighting_transitioning(), "lantern click starts a transition")
	assert(not room.toggle_daylight(), "repeated clicks are ignored during the transition")
	await create_timer(HomeRoom.LIGHT_TRANSITION_DURATION + 0.12).timeout
	assert(room.is_daylight() and not room.is_lighting_transitioning(), "transition finishes in daylight")
	assert(is_equal_approx(floor_sprite.modulate.a, 0.0) and is_equal_approx(day_floor.modulate.a, 1.0), "day floor replaces the night floor")
	assert(is_equal_approx(night_props.modulate.a, 0.0) and is_equal_approx(day_props.modulate.a, 1.0), "day props replace the night props")
	assert(lighting_events == [true], "daylight transition emits once")
	lantern_btn.pressed.emit()
	assert(room.is_lighting_transitioning(), "second lantern click starts the night transition")
	await create_timer(HomeRoom.LIGHT_TRANSITION_DURATION + 0.12).timeout
	assert(not room.is_daylight() and not room.is_lighting_transitioning(), "transition returns to night")
	assert(is_equal_approx(floor_sprite.modulate.a, 1.0) and is_equal_approx(day_floor.modulate.a, 0.0), "night floor replaces the day floor")
	assert(is_equal_approx(night_props.modulate.a, 1.0) and is_equal_approx(day_props.modulate.a, 0.0), "night props replace the day props")
	assert(lighting_events == [true, false], "both lighting transitions emit once")
	assert(hub.find_child("TitleLabel", true, false) == null, "hub has no title caption")
	assert(hub.find_child("HintLabel", true, false) == null, "hub has no bottom subtitle")
	assert(hub.find_child("PortalCaption", true, false) == null, "hub has no portal caption")
	assert(hub.find_child("WeaponCodex", true, false) != null, "weapon station hitbox remains")
	assert(hub.find_child("EnemyCodex", true, false) != null, "enemy station hitbox remains")
	assert(hub.find_child("Records", true, false) != null, "records station hitbox remains")
	assert(hub.find_child("PetNest", true, false) != null, "pet nest hitbox remains")

	assert(hub.find_child("MoveStick", true, false) == null, "home has no virtual stick")
	assert(hub.find_child("HeroController", true, false) == null, "hub walker is not the battlefield HeroController")
	var walker := hub.find_child("HomeWalker", true, false) as EmberHero
	assert(walker != null, "home stamps a walker so furniture air walls can be used")
	assert(walker.find_child("XSXBHeroActor", true, false) != null, "home walker uses the same hero actor")
	assert(walker.hub_hide_weapon, "home walker does not hold the combat sword")
	assert(not walker.has_dash, "home walker has no combat skill")
	walker.request_attack()
	assert(walker.current_state != &"attack", "home cannot attack")
	assert(float(walker.get("_attack_elapsed")) < 0.0, "home attack clip does not start")
	walker.request_dash()
	assert(walker.current_state != &"dash", "home cannot dash or cast")
	assert(float(walker.get("_dash_elapsed")) < 0.0, "home skill clip does not start")
	assert(walker.find_child("HeldWeapon", true, false) == null, "home has no floating held weapon")
	assert(walker.find_child("HeldOrbit0", true, false) == null, "home has no orbiting weapons")
	assert(walker.find_child("HeldOrbit1", true, false) == null, "home has no extra floating swords")
	assert(is_equal_approx(walker.hub_visual_height, 128.0), "home walker height matches 牛来")
	var walker_actor := walker.find_child("XSXBHeroActor", true, false) as Node2D
	assert(walker_actor != null and walker_actor.scale.y > 1.45 and walker_actor.scale.y < 1.70, "home walker is scaled to the mascot")
	assert(hub.find_child("PreviewPortrait", true, false) == null, "hub has no HUD portrait")

	var skate := room.air_wall_named("Skateboard")
	assert(not skate.is_empty(), "skateboard has a floor air wall")
	assert(float(skate.get("height", 99.0)) < EmberHero.JUMP_HEIGHT, "skateboard is shorter than a jump")
	var skate_rect: Rect2 = skate.get("rect", Rect2())
	var skate_in := skate_rect.get_center()
	assert(room.is_air_blocked(skate_in, 0.0), "grounded feet cannot enter the skateboard")
	assert(not room.is_air_blocked(skate_in, EmberHero.JUMP_HEIGHT), "jump clearance 32 clears the skateboard")
	var skate_from := Vector2(skate_rect.position.x - 14.0, skate_in.y)
	if room.is_air_blocked(skate_from, 0.0):
		skate_from = Vector2(skate_rect.end.x + 14.0, skate_in.y)
	var skate_ground := room.clamp_walk(skate_from, skate_in, 0.0)
	assert(skate_ground.distance_to(skate_in) > 2.0, "grounded clamp stops before the skateboard")
	var skate_air := room.clamp_walk(skate_from, skate_in, EmberHero.JUMP_HEIGHT)
	assert(skate_air.distance_to(skate_in) < 1.0, "jumping clamp crosses the skateboard")

	var desk := room.air_wall_named("CoderDesk")
	assert(not desk.is_empty(), "desk has a floor air wall")
	assert(float(desk.get("height", 0.0)) > EmberHero.JUMP_HEIGHT, "desk is taller than a jump")
	var desk_in: Vector2 = (desk.get("rect", Rect2()) as Rect2).get_center()
	assert(room.is_air_blocked(desk_in, EmberHero.JUMP_HEIGHT), "a 32px jump cannot vault the desk")
	assert(room.air_wall_named("Monument").is_empty(), "whiteboard hangs on the wall and has no floor block")
	assert(room.air_wall_named("OvertimeSign").is_empty(), "neon sign hangs on the wall and has no floor block")

	walker.position = skate_from
	for _step: int in range(8):
		walker.move_in_direction(skate_in - walker.position, 0.08)
	assert(not skate_rect.has_point(walker.position), "walking into the skateboard is blocked")
	walker.request_jump()
	var vaulted := false
	for _tick: int in range(36):
		await process_frame
		if walker.air_clearance() >= float(skate.get("height", 10.0)):
			walker.move_in_direction(skate_in - walker.position, 0.05)
		if skate_rect.has_point(walker.position):
			vaulted = true
			break
	assert(vaulted, "jumping while moving crosses the skateboard air wall")
	for _land: int in range(24):
		await process_frame
		if walker.air_clearance() <= 0.01:
			break
	walker.position = WALKER_AWAY

	var desk_rect: Rect2 = desk.get("rect", Rect2())
	var desk_from := Vector2(desk_rect.position.x - 16.0, desk_in.y)
	if room.is_air_blocked(desk_from, 0.0):
		desk_from = Vector2(desk_rect.end.x + 16.0, desk_in.y)
	walker.position = desk_from
	walker.request_jump()
	var desk_crossed := false
	for _tick: int in range(36):
		await process_frame
		if walker.air_clearance() >= 20.0:
			walker.move_in_direction(desk_in - walker.position, 0.05)
		if desk_rect.has_point(walker.position):
			desk_crossed = true
			break
	assert(not desk_crossed, "jumping cannot cross the desk air wall")
	walker.position = WALKER_AWAY

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

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
	assert(not hub.is_selection_confirmed(), "configure must leave selection unconfirmed")
	assert(hub.selected_hero_id() == &"", "no hero is confirmed this visit")

	var run_emits: Array = []
	hub.new_run_requested.connect(func(hero_id: StringName, mode_id: StringName) -> void:
		run_emits.append({"hero": hero_id, "mode": mode_id})
	)
	var continue_emits: Array = []
	hub.continue_requested.connect(func() -> void:
		continue_emits.append(true)
	)

	var blocked: String = hub.confirm_new_run()
	assert(blocked != "", "confirm_new_run must error before a pedestal click")
	assert(run_emits.is_empty(), "confirm_new_run should not emit before selection")

	var portal_blocked: String = hub.try_open_portal()
	assert(portal_blocked == "请先选择人物", "portal stays closed until a pedestal click")
	assert(run_emits.is_empty(), "try_open_portal must not emit new_run_requested")

	hub.confirm_hero(&"ember_hero")
	assert(hub.is_selection_confirmed(), "confirm_hero ember_hero should confirm")
	assert(hub.selected_hero_id() == &"ember_hero", "selected hero is knight")

	var opened: String = hub.try_open_portal()
	assert(opened == "", "try_open_portal succeeds after selection")
	assert(run_emits.is_empty(), "try_open_portal still does not emit; confirm_new_run does")

	var started: String = hub.confirm_new_run()
	assert(started == "", "confirm_new_run should succeed after select")
	assert(run_emits.size() == 1, "confirm_new_run emits once")
	assert(run_emits[0]["hero"] == &"ember_hero", "new run uses the confirmed knight")
	assert(run_emits[0]["mode"] == &"endless_td", "stub mode is endless_td")

	hub.configure({}, {})
	assert(not hub.is_selection_confirmed(), "configure again resets selection")
	assert(hub.selected_hero_id() == &"", "configure again clears this visit's hero")
	var reset_blocked: String = hub.confirm_new_run()
	assert(reset_blocked != "", "reset visit cannot start a run")
	assert(run_emits.size() == 1, "reset confirm_new_run must not emit")

	hub.configure({"last_selected_hero": "ember_hero"}, {})
	assert(not hub.is_selection_confirmed(), "last_selected_hero must not auto-confirm")
	assert(hub.confirm_new_run() != "", "highlighted last hero still needs a click")
	assert(run_emits.size() == 1, "last_selected_hero must not emit a run")

	hub.confirm_hero(&"assassin")
	assert(hub.is_selection_confirmed(), "assassin pedestal confirms")
	assert(hub.selected_hero_id() == &"assassin")
	var without_portal: String = hub.confirm_new_run()
	assert(without_portal == "", "confirm_new_run does not require try_open_portal")
	assert(run_emits.size() == 2, "assassin run emits without opening the portal first")
	assert(run_emits[1]["hero"] == &"assassin")
	assert(run_emits[1]["mode"] == &"endless_td")

	hub.configure({}, {"hero": {"hero_id": "assassin"}})
	hub.request_continue()
	assert(continue_emits.size() == 1, "request_continue emits when resumable_run is set")
	hub.request_continue()
	assert(continue_emits.size() == 2, "resumable continue can fire again")
	hub.configure({}, {})
	hub.request_continue()
	assert(continue_emits.size() == 2, "empty resumable_run is a no-op")

	assert(hub.pet_prompt() == "宠物系统暂未开放", "pet nest is locked")

	var knight := hub.find_child("KnightPedestal", true, false)
	var assassin := hub.find_child("AssassinPedestal", true, false)
	assert(knight != null, "KnightPedestal must exist for clicks")
	assert(assassin != null, "AssassinPedestal must exist for clicks")
	_assert_touch_target(knight)
	_assert_touch_target(assassin)
	var knight_rect := _control_rect(knight)
	var assassin_rect := _control_rect(assassin)
	assert(knight_rect.intersects(assassin_rect) == false, "pedestals must not overlap")
	var gap := _rect_gap(knight_rect, assassin_rect)
	assert(gap >= 8.0, "pedestals need 8px+ gap, got %s" % gap)

	var floor_node := hub.find_child("Floor", true, false)
	assert(floor_node is Sprite2D, "floor must be a Sprite2D, not a solid ColorRect")
	var floor_sprite := floor_node as Sprite2D
	assert(floor_sprite.texture != null, "home floor texture must load")
	var floor_path := String(floor_sprite.texture.resource_path)
	assert(floor_path.contains("assets/generated/home/"), "home floor lives under assets/generated/home/")
	assert(not floor_path.contains("grid-battlefield"), "home must not reuse the combat floor")
	assert(hub.find_child("HomeRoom", true, false) != null, "visuals live in a dedicated HomeRoom node")
	assert(hub.find_child("Bookshelf", true, false) != null, "weapon station has a bookshelf sprite")
	assert(hub.find_child("Bestiary", true, false) != null, "enemy station has a bestiary sprite")
	assert(hub.find_child("Monument", true, false) != null, "records station has a monument sprite")
	assert(hub.find_child("PetBed", true, false) != null, "pet nest has a bed sprite")

	assert(hub.find_child("MoveStick", true, false) == null, "unselected home has no virtual stick")
	assert(hub.find_child("XSXBHeroActor", true, false) == null, "do not instance EmberHero in the hub stub")
	assert(hub.find_child("PreviewPortrait", true, false) == null, "selected hero is a full body, not a HUD portrait")
	var preview_body := hub.find_child("PreviewBody", true, false) as AnimatedSprite2D
	assert(preview_body != null, "hub has a PreviewBody idle sprite")
	assert(hub.find_child("KnightPedestalBody", true, false) != null, "knight pad shows a full idle body")
	assert(hub.find_child("AssassinPedestalBody", true, false) != null, "assassin pad shows a full idle body")

	hub.configure({}, {})
	assert(preview_body.visible == false, "full body stays hidden until a pedestal click")
	hub.confirm_hero(&"ember_hero")
	assert(preview_body.visible, "selecting a hero shows the full idle body")
	assert(preview_body.sprite_frames != null and preview_body.sprite_frames.get_frame_count("idle") == 6, "preview plays the 6-frame idle")
	var preview_tex := preview_body.sprite_frames.get_frame_texture("idle", 0)
	assert(preview_tex != null, "preview idle frame loads")
	var knight_atlas := preview_tex as AtlasTexture
	assert(knight_atlas != null and knight_atlas.atlas != null, "preview crops idle frames to the opaque body")
	assert(not String(knight_atlas.atlas.resource_path).contains("portrait"), "preview must not use the HUD headshot")
	assert(String(knight_atlas.atlas.resource_path).contains("ember_hero/idle"), "knight preview uses knight idle frames")
	assert(float(preview_tex.get_height()) * preview_body.scale.y >= 180.0, "selected preview must be a full standing body, not a head")
	var knight_pad := hub.find_child("KnightPedestalBody", true, false) as CanvasItem
	assert(knight_pad != null and knight_pad.visible == false, "picked knight leaves the pad and stands on the rug")
	hub.confirm_hero(&"assassin")
	preview_tex = preview_body.sprite_frames.get_frame_texture("idle", 0)
	var assassin_atlas := preview_tex as AtlasTexture
	assert(assassin_atlas != null and assassin_atlas.atlas != null, "assassin preview crops idle frames")
	assert(String(assassin_atlas.atlas.resource_path).contains("ember_assassin/idle"), "assassin preview uses assassin idle frames")
	assert(hub.find_child("XSXBHeroActor", true, false) == null, "full-body preview must not instance the combat actor")
	assert(float(preview_tex.get_height()) * preview_body.scale.y >= 180.0, "assassin preview must be a full standing body")
	hub.configure({}, {})
	assert(preview_body.visible == false, "reset visit hides the preview body")

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


func _control_rect(node: Node) -> Rect2:
	var control := _as_control(node)
	var origin: Vector2 = control.global_position
	var size: Vector2 = control.size
	if size.x < 1.0 or size.y < 1.0:
		size = control.custom_minimum_size
	return Rect2(origin, size)


func _rect_gap(a: Rect2, b: Rect2) -> float:
	var dx := 0.0
	if a.end.x < b.position.x:
		dx = b.position.x - a.end.x
	elif b.end.x < a.position.x:
		dx = a.position.x - b.end.x
	var dy := 0.0
	if a.end.y < b.position.y:
		dy = b.position.y - a.end.y
	elif b.end.y < a.position.y:
		dy = a.position.y - b.end.y
	if dx > 0.0 and dy > 0.0:
		return sqrt(dx * dx + dy * dy)
	if dx > 0.0:
		return dx
	if dy > 0.0:
		return dy
	return 0.0

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
	assert(floor_sprite.texture != null, "floor sprite needs the battlefield texture")
	assert(String(floor_sprite.texture.resource_path).ends_with("grid-battlefield-v6.png"), "floor uses grid-battlefield-v6.png")

	assert(hub.find_child("MoveStick", true, false) == null, "unselected home has no virtual stick")
	assert(hub.find_child("XSXBHeroActor", true, false) == null, "do not instance EmberHero in the hub stub")

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

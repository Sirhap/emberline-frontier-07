extends SceneTree

## Interactive sell GUI: freeze prep, keep tower selected, print SellButton screen rect.
const PAD := Vector2(648.0, 336.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.global_position = PAD + Vector2(0.0, -16.0)
		cam.zoom = Vector2(1.45, 1.45)
		cam.reset_smoothing()
		cam.force_update_scroll()
	hero.position = PAD + Vector2(-70.0, 50.0)
	# Freeze prep so combat never starts during GUI click.
	var director = scene.get("_director")
	if director != null:
		director.prep_left = 9999.0
		director.prep_duration = 9999.0
	scene.set("scrap", 300)
	var tower: EmberTower = scene.call("_spawn_tower_at", PAD, &"pulse", 1)
	await process_frame
	await process_frame
	scene.call("_select_tower", tower)
	await process_frame
	await RenderingServer.frame_post_draw
	_print_sell_rect(scene)
	print("SELL_LIVE ready scrap=%d sell=%d towers=%d prep=%.0f" % [
		int(scene.get("scrap")),
		tower.sell_value(),
		(scene.get("_towers") as Array).size(),
		float(director.prep_left) if director != null else -1.0,
	])
	# Keep selection alive (HUD panel auto-hides after 3s).
	while true:
		await create_timer(1.0).timeout
		if not is_instance_valid(tower):
			print("SELL_LIVE tower gone scrap=%d towers=%d" % [
				int(scene.get("scrap")),
				(scene.get("_towers") as Array).size(),
			])
			_print_sell_rect(scene)
			# Stay open so post-sell screenshot can be taken.
			continue
		scene.call("_select_tower", tower)
		_print_sell_rect(scene)


func _print_sell_rect(scene: Node) -> void:
	var hud: Node = scene.get("_hud")
	if hud == null:
		print("SELL_RECT missing hud")
		return
	var btn: Button = hud.get("sell_button")
	if btn == null:
		print("SELL_RECT missing button")
		return
	var r: Rect2 = btn.get_global_rect()
	var win_pos := DisplayServer.window_get_position()
	print("SELL_RECT local=%.1f,%.1f,%.1fx%.1f disabled=%s text=%s win=%d,%d abs_center=%.0f,%.0f scrap=%d towers=%d" % [
		r.position.x, r.position.y, r.size.x, r.size.y,
		btn.disabled, btn.text,
		win_pos.x, win_pos.y,
		win_pos.x + r.position.x + r.size.x * 0.5,
		win_pos.y + r.position.y + r.size.y * 0.5,
		int(scene.get("scrap")),
		(scene.get("_towers") as Array).size(),
	])

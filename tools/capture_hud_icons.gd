extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	hero.position = Vector2(640.0, 336.0)
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()
	var hud: FrontierHud = scene.get("_hud")
	if hud != null:
		hud.set_hero_kind(&"ember_hero")
	hero.dash_cooldown_left = 0.0
	scene.call("_sync_skill_hud")
	scene.call("_sync_weapon_hud")
	await process_frame
	await process_frame
	_save("res://tools/look-qa-hud-knight.png")
	_save_pad("res://tools/look-qa-hud-knight-pad.png")
	_save_pad("res://tools/look-qa-hud-skill-ready.png")

	hero.request_dash()
	scene.call("_sync_skill_hud")
	await process_frame
	await process_frame
	_save_pad("res://tools/look-qa-hud-skill-cast.png")

	await create_timer(0.35).timeout
	hero.dash_cooldown_left = 4.0
	scene.call("_sync_skill_hud")
	await process_frame
	await process_frame
	_save_pad("res://tools/look-qa-hud-skill-cooldown.png")

	hero.apply_hero_kind(&"assassin")
	if hud != null:
		hud.set_hero_kind(&"assassin")
	hero.dash_cooldown_left = 0.0
	scene.call("_sync_skill_hud")
	scene.call("_sync_weapon_hud")
	await process_frame
	await process_frame
	_save("res://tools/look-qa-hud-assassin.png")
	_save_pad("res://tools/look-qa-hud-assassin-pad.png")
	print("HUD_ICONS_QA ok")
	quit()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])


func _save_pad(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var pad := image.get_region(Rect2i(980, 470, 300, 250))
	var err := pad.save_png(path)
	print("SAVED %s err=%s" % [path, err])

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
	hero.apply_hero_kind(&"assassin")
	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	var hud: FrontierHud = scene.get("_hud")
	if hud != null:
		hud.set_hero_kind(&"assassin")
	scene.call("_sync_skill_hud")
	hero.position = Vector2(640.0, 336.0)
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()
	await process_frame
	await process_frame
	_save("res://tools/look-qa-assassin.png")
	hero.request_dash()
	await scene.get_tree().create_timer(0.12).timeout
	_save("res://tools/look-qa-assassin-skill-early.png")
	await scene.get_tree().create_timer(0.26).timeout
	_save("res://tools/look-qa-assassin-skill.png")
	await scene.get_tree().create_timer(0.14).timeout
	_save("res://tools/look-qa-assassin-clones.png")
	var dummy := FrontierEnemy.new()
	dummy.variant = &"scout"
	dummy.max_health = 400
	dummy.move_speed = 0.0
	dummy.configure_seek(hero.global_position + Vector2(90.0, 8.0), scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", dummy)
	await scene.get_tree().create_timer(1.05).timeout
	_snap_cam(cam, hero)
	_save("res://tools/look-qa-assassin-clones-attack.png")
	print("CLONE_HEALTH %s/%s COUNT %s" % [dummy.health, dummy.max_health, (hero.get("_clone_nodes") as Array).size()])
	await scene.get_tree().create_timer(3.70).timeout
	_snap_cam(cam, hero)
	_save("res://tools/look-qa-assassin-clones-end.png")
	print("CLONE_END COUNT %s" % (hero.get("_clone_nodes") as Array).size())
	print("ASSASSIN_SKILL_QA ok")
	quit()


func _snap_cam(cam: Camera2D, hero: Node2D) -> void:
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

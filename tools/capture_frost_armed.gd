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
		cam.zoom = Vector2(1.7, 1.7)
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", 1)
	_snap(cam, hero)
	await process_frame
	await process_frame
	print("PACK %s hide=%s dash=%s duration=%s" % [
		String(hero.visual_pack_id),
		str(hero.call("_hides_held_overlay")),
		hero._clip_name(&"dash"),
		str(hero._animation_duration(hero._clip_name(&"dash"), -1.0)),
	])
	_snap(cam, hero)
	_save("res://tools/look-qa-armed-idle.png")
	hero.set_demo_state(&"run")
	await scene.get_tree().create_timer(0.18).timeout
	_snap(cam, hero)
	_save("res://tools/look-qa-armed-run.png")
	hero.set("_demo_state_time", 0.0)
	hero.set("_demo_state", &"")
	hero.call("_set_state", &"idle")
	hero.request_attack()
	await scene.get_tree().create_timer(0.18).timeout
	_snap(cam, hero)
	_save("res://tools/look-qa-armed-attack.png")
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	await process_frame
	hero.dash_cooldown_left = 0.0
	hero.request_dash()
	await scene.get_tree().create_timer(0.14).timeout
	_snap(cam, hero)
	_save("res://tools/look-qa-armed-skill.png")
	print("ARMED_QA state=%s dash_elapsed=%s overlays=%s clip=%s" % [
		String(hero.current_state),
		str(hero.get("_dash_elapsed")),
		str((hero.get("_float_sprites") as Array).size()),
		hero._clip_name(&"dash"),
	])
	quit()


func _snap(cam: Camera2D, hero: Node2D) -> void:
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

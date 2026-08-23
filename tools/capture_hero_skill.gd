extends SceneTree

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.position = Vector2(640.0, 336.0)
	hero.unlock_dash()
	var hud: Node = scene.get("_hud")
	if hud != null:
		hud.call("set_skill", true, 0.0, hero.dash_cooldown)
	_save("res://tools/look-hero-idle.png")
	hero.request_dash()
	await create_timer(0.08).timeout
	_save("res://tools/look-hero-dash.png")
	await create_timer(0.28).timeout
	hero.down_duration = 2.0
	hero.take_damage(999)
	await create_timer(0.40).timeout
	_save("res://tools/look-hero-down.png")
	print("HERO_SKILL_CAPTURE done state=%s down=%s" % [String(hero.current_state), str(hero.is_down)])
	quit()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

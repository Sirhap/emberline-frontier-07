extends SceneTree

## Capture frost transform: idle → mid-cast → armed idle/attack.

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
	hero.call("_commit_hero_kind", &"ember_hero", &"frost_warrior", true)
	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	hero.position = Vector2(640.0, 336.0)
	await process_frame
	await process_frame
	print("IDLE pack=%s" % String(hero.visual_pack_id))
	_snap(cam, hero)
	_save("res://tools/look-qa-frost-transform-idle.png")
	hero.request_dash()
	await scene.get_tree().create_timer(0.35).timeout
	_snap(cam, hero)
	_save("res://tools/look-qa-frost-transform-cast.png")
	var wait := 0
	while hero.visual_pack_id == &"frost_warrior" and wait < 80:
		await scene.get_tree().create_timer(0.05).timeout
		wait += 1
	_snap(cam, hero)
	_save("res://tools/look-qa-frost-transform-armed.png")
	print("TRANSFORM pack=%s transforming=%s" % [String(hero.visual_pack_id), str(hero.get("_transforming"))])
	hero.request_attack()
	await scene.get_tree().create_timer(0.20).timeout
	_snap(cam, hero)
	_save("res://tools/look-qa-frost-transform-attack.png")
	hero.request_dash()
	await scene.get_tree().create_timer(0.12).timeout
	_snap(cam, hero)
	_save("res://tools/look-qa-frost-transform-dash.png")
	print("TRANSFORM_QA ok pack=%s" % String(hero.visual_pack_id))
	var idle_wait := 0
	while float(hero.get("_dash_elapsed")) >= 0.0 and idle_wait < 40:
		await scene.get_tree().create_timer(0.05).timeout
		idle_wait += 1
	hero.form_left = 0.0
	hero.call("_tick_frost_form", 0.05)
	await scene.get_tree().create_timer(0.35).timeout
	_snap(cam, hero)
	_save("res://tools/look-qa-frost-untransform-cast.png")
	idle_wait = 0
	while hero.visual_pack_id == &"frost_armed" and idle_wait < 80:
		await scene.get_tree().create_timer(0.05).timeout
		idle_wait += 1
	_snap(cam, hero)
	_save("res://tools/look-qa-frost-untransform-idle.png")
	print("UNTRANSFORM pack=%s reverting=%s" % [String(hero.visual_pack_id), str(hero.get("_reverting"))])
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

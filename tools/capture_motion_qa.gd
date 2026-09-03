extends SceneTree

## Player-view shots for motion 1–6. Does not touch user://run.json.

const OUT := "res://dogfood-output/motion-qa"

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.zoom = Vector2(1.55, 1.55)
	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", 1)
	hero.dash_cooldown_left = 0.0
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.call("_set_state", &"idle")
	_aim(cam, hero)
	await _settle()
	await _save("01-field-idle")

	hero.request_attack()
	await create_timer(0.04).timeout
	_aim(cam, hero)
	await _save("02-melee-lunge-a")
	await create_timer(0.06).timeout
	_aim(cam, hero)
	await _save("03-melee-lunge-b")
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")

	hero.position = Vector2(640.0, 336.0)
	hero.move_in_direction(Vector2.RIGHT, 0.0)
	hero.request_attack()
	hero.move_in_direction(Vector2.RIGHT, 0.10)
	_aim(cam, hero)
	await _settle()
	await _save("04-moving-melee")
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")

	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", 1)
	hero.move_in_direction(Vector2.UP, 0.0)
	hero.dash_cooldown_left = 0.0
	hero.request_dash()
	await create_timer(0.02).timeout
	_aim(cam, hero)
	await _save("05-dash-up-start")
	await create_timer(0.12).timeout
	_aim(cam, hero)
	await _save("06-dash-up-mid")
	hero.set("_dash_elapsed", -1.0)
	hero.dash_cooldown_left = 0.0

	hero.position = Vector2(640.0, 336.0)
	hero.move_in_direction(Vector2.RIGHT, 0.0)
	hero.apply_hero_kind(&"assassin")
	_aim(cam, hero)
	await _save("07-swap-fade")
	await create_timer(0.12).timeout
	_aim(cam, hero)
	await _save("08-assassin-run")

	hero.dash_cooldown_left = 0.0
	hero.move_in_direction(Vector2.RIGHT, 0.0)
	hero.request_dash()
	await create_timer(0.08).timeout
	_aim(cam, hero)
	await _save("09-assassin-skill-slide")
	await create_timer(0.30).timeout
	_aim(cam, hero)
	await _save("10-assassin-clones")
	hero.set("_dash_elapsed", -1.0)
	hero.call("_clear_clones")

	hero.position = Vector2(640.0, 336.0)
	if cam != null:
		cam.zoom = Vector2(1.16, 1.16)
	_aim(cam, hero)
	await _settle()
	await _save("11-field-wide")

	print("MOTION_QA ok %s" % OUT)
	quit()


func _aim(cam: Camera2D, hero: Node2D) -> void:
	if cam == null:
		return
	cam.global_position = hero.global_position
	cam.reset_smoothing()
	cam.force_update_scroll()


func _settle() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw


func _save(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUT, shot_name]
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

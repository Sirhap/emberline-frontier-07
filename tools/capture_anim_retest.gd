extends SceneTree

## In-engine shots of knight dash/attack and frost transform/dash.

const OUT := "res://dogfood-output/anim-retest"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.zoom = Vector2(2.2, 2.2)
	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", 1)
	hero.unlock_dash()
	await _shot(cam, hero, "01-knight-idle")
	hero.dash_cooldown_left = 0.0
	hero.request_dash()
	await create_timer(0.04).timeout
	await _shot(cam, hero, "02-knight-dash-a")
	await create_timer(0.10).timeout
	await _shot(cam, hero, "03-knight-dash-b")
	hero.set("_dash_elapsed", -1.0)
	hero.dash_cooldown_left = 0.0
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.call("_set_state", &"idle")
	hero.request_attack()
	await create_timer(0.06).timeout
	await _shot(cam, hero, "04-knight-atk-a")
	await create_timer(0.12).timeout
	await _shot(cam, hero, "05-knight-atk-b")
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.call("_commit_hero_kind", &"ember_hero", &"frost_warrior", true)
	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	hero.position = Vector2(640.0, 336.0)
	await process_frame
	await _shot(cam, hero, "10-frost-idle")
	hero.request_dash()
	print("CAST clip=%s dur=%s state=%s" % [hero._clip_name(&"dash"), str(hero._animation_duration(hero._clip_name(&"dash"), -1.0)), String(hero.current_state)])
	await create_timer(0.18).timeout
	await _shot(cam, hero, "11-frost-cast-a")
	await create_timer(0.30).timeout
	await _shot(cam, hero, "12-frost-cast-b")
	await create_timer(0.50).timeout
	await _shot(cam, hero, "13-frost-cast-c")
	var wait := 0
	while hero.visual_pack_id == &"frost_warrior" and wait < 80:
		await create_timer(0.05).timeout
		wait += 1
	await _shot(cam, hero, "14-frost-armed")
	print("ARMED pack=%s" % String(hero.visual_pack_id))
	hero.dash_cooldown_left = 0.0
	hero.request_dash()
	await create_timer(0.10).timeout
	await _shot(cam, hero, "15-frost-armed-dash")
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.request_attack()
	await create_timer(0.12).timeout
	await _shot(cam, hero, "16-frost-armed-atk")
	print("ANIM_RETEST ok pack=%s clip=%s" % [String(hero.visual_pack_id), hero._clip_name(&"dash")])
	quit()


func _shot(cam: Camera2D, hero: Node2D, name: String) -> void:
	if cam != null:
		cam.zoom = Vector2(2.2, 2.2)
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("SKIP %s" % name)
		return
	var path := "%s/%s.png" % [OUT, name]
	image.save_png(path)
	print("SAVED %s" % path)

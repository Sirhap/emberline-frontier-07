extends SceneTree

const OUT := "res://dogfood-output/frost-armed-visual"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.zoom = Vector2(2.8, 2.8)
	hero.unlock_dash()
	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", 1)

	await _shot(cam, hero, &"ember_hero", "idle", "01-default-idle", 0.08)
	await _shot(cam, hero, &"frost_warrior", "idle", "02-frost-idle", 0.08)
	await _shot(cam, hero, &"frost_armed", "idle", "03-armed-idle", 0.08)
	hero.set_demo_state(&"run")
	await _wait(0.22)
	_dump(hero, "run")
	_save("04-armed-run")
	hero.set("_demo_state_time", 0.0)
	hero.set("_demo_state", &"")
	hero.call("_set_state", &"idle")
	hero.request_jump()
	await _wait(0.18)
	_dump(hero, "jump")
	_save("05-armed-jump")
	await _wait(0.40)
	hero.request_attack()
	await _wait(0.08)
	_dump(hero, "attack-early")
	_save("06-armed-attack-windup")
	await _wait(0.16)
	_dump(hero, "attack-slash")
	_save("07-armed-attack-slash")
	await _wait(0.18)
	_dump(hero, "attack-recover")
	_save("07b-armed-attack-recover")
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	await process_frame
	hero.dash_cooldown_left = 0.0
	hero.request_dash()
	await _wait(0.12)
	_dump(hero, "skill-start")
	_save("08-armed-skill-start")
	await _wait(0.32)
	_dump(hero, "skill-slam")
	_save("09-armed-skill-slam")
	if float(hero.get("_dash_elapsed")) >= 0.0:
		hero.set("_dash_elapsed", -1.0)
	hero.call("_set_state", &"down")
	await _wait(0.08)
	_dump(hero, "down")
	_save("10-armed-down")
	print("ARMED_VISUAL_DONE overlays=%s" % str((hero.get("_float_sprites") as Array).size()))
	quit()


func _shot(cam: Camera2D, hero: EmberHero, pack: StringName, _pose: String, name: String, settle: float) -> void:
	hero.apply_hero_kind(&"ember_hero", pack)
	hero.call("_apply_facing", 1)
	hero.position = Vector2(640.0, 336.0)
	hero.call("_set_state", &"idle")
	await _wait(settle)
	_dump(hero, name)
	_save(name)


func _dump(hero: EmberHero, label: String) -> void:
	var actor := hero.get_node_or_null("XSXBHeroActor")
	var sprite: Sprite2D = null
	var owner: Node2D = null
	if actor != null:
		owner = actor.get_node_or_null("VisualOwner") as Node2D
		sprite = actor.get_node_or_null("VisualOwner/FrameSprite") as Sprite2D
	var tex := "?"
	if sprite != null and sprite.texture != null:
		tex = "%sx%s" % [sprite.texture.get_width(), sprite.texture.get_height()]
	print("SHOT %s pack=%s state=%s want=%s play=%s frame=%s tex=%s scale=%s overlays=%s hide=%s dash_t=%s atk_t=%s" % [
		label,
		String(hero.visual_pack_id),
		String(hero.current_state),
		hero._clip_name(hero.current_state),
		str(actor.get("_current_animation") if actor != null else ""),
		str(hero.call("_actor_frame")),
		tex,
		str(owner.scale if owner != null else "?"),
		str((hero.get("_float_sprites") as Array).size()),
		str(hero.call("_hides_held_overlay")),
		str(hero.get("_dash_elapsed")),
		str(hero.get("_attack_elapsed")),
	])


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _save(name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var full := "%s/%s.png" % [OUT, name]
	var err := image.save_png(full)
	print("SAVED %s err=%s" % [full, err])
	var crop := image.get_region(Rect2i(460, 180, 360, 400))
	crop.save_png("%s/%s-crop.png" % [OUT, name])

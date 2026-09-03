extends SceneTree

const OUT := "res://dogfood-output/frost-armed-jump"


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
		cam.zoom = Vector2(1.8, 1.8)
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	hero.unlock_dash()
	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", 1)
	hero.call("_set_state", &"idle")
	await _wait(0.08)
	_dump(hero, "idle")
	_save("00-idle")
	hero.request_jump()
	var marks := {
		"01-crouch": 0.06,
		"02-launch": 0.16,
		"03-apex": 0.28,
		"04-descent": 0.40,
		"05-land": 0.50,
	}
	var elapsed := 0.0
	for name: String in ["01-crouch", "02-launch", "03-apex", "04-descent", "05-land"]:
		var target := float(marks[name])
		await _wait(target - elapsed)
		elapsed = target
		_dump(hero, name)
		_save(name)
	await _wait(0.20)
	_dump(hero, "06-after")
	_save("06-after")
	print("ARMED_JUMP_CAPTURE_DONE")
	quit()


func _dump(hero: EmberHero, label: String) -> void:
	var actor := hero.get_node_or_null("XSXBHeroActor")
	var sprite: Sprite2D = null
	var owner: Node2D = null
	if actor != null:
		owner = actor.get_node_or_null("VisualOwner") as Node2D
		sprite = actor.get_node_or_null("VisualOwner/FrameSprite") as Sprite2D
	print("SHOT %s pack=%s state=%s want=%s play=%s frame=%s lift=%s vis_y=%s scale=%s" % [
		label,
		String(hero.visual_pack_id),
		String(hero.current_state),
		hero._clip_name(hero.current_state),
		str(actor.get("_current_animation") if actor != null else ""),
		str(actor.get("_current_frame") if actor != null else ""),
		str(hero.get("_jump_offset")),
		str(owner.position.y if owner != null else "?"),
		str(owner.scale if owner != null else "?"),
	])


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _save(name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var full := "%s/%s.png" % [OUT, name]
	image.save_png(full)
	# Wide tall crop so the lifted sprite stays in frame.
	var crop := image.get_region(Rect2i(470, 40, 340, 520))
	crop.save_png("%s/%s-crop.png" % [OUT, name])
	print("SAVED %s" % full)

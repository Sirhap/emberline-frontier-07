extends SceneTree

## Skill → 1.2s armed window → jump apex + slash. Linux-desktop dogfood frames.
const OUT := "res://dogfood-output/frost-armed-window"


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
		cam.zoom = Vector2(2.4, 2.4)
	hero.call("_commit_hero_kind", &"ember_hero", &"frost_warrior", true)
	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", 1)
	await _wait(0.08)
	_dump(hero, "idle")
	_save("00-unarmed-idle")
	hero.request_dash()
	await _wait(0.40)
	_dump(hero, "cast")
	_save("01-cast")
	var wait := 0
	while hero.visual_pack_id != &"frost_armed" and wait < 80:
		await _wait(0.05)
		wait += 1
	assert(hero.visual_pack_id == &"frost_armed", "armed pack must commit by the 1.2s unlock")
	await _wait(0.08)
	_dump(hero, "armed")
	_save("02-armed-idle")
	hero.request_jump()
	await _wait(0.22)
	_dump(hero, "jump-apex")
	_save("03-armed-jump")
	await _wait(0.40)
	hero.call("_cancel_jump")
	await process_frame
	hero.request_attack()
	await _wait(0.10)
	_dump(hero, "attack-slash")
	_save("04-armed-attack")
	print("ARMED_WINDOW_CAPTURE_DONE pack=%s" % String(hero.visual_pack_id))
	quit()


func _dump(hero: EmberHero, label: String) -> void:
	var actor := hero.get_node_or_null("XSXBHeroActor")
	var owner: Node2D = null
	if actor != null:
		owner = actor.get_node_or_null("VisualOwner") as Node2D
	print("SHOT %s pack=%s state=%s play=%s frame=%s lift=%s vis_y=%s" % [
		label,
		String(hero.visual_pack_id),
		String(hero.current_state),
		str(actor.get("_current_animation") if actor != null else ""),
		str(actor.get("_current_frame") if actor != null else ""),
		str(hero.get("_jump_offset")),
		str(owner.position.y if owner != null else "?"),
	])


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _save(name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var full := "%s/%s.png" % [OUT, name]
	image.save_png(full)
	var crop := image.get_region(Rect2i(460, 80, 360, 480))
	crop.save_png("%s/%s-crop.png" % [OUT, name])
	print("SAVED %s" % full)

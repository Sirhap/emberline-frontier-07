extends SceneTree

## Skill → 1.2s armed window → T0 + MOVE + JUMP + ATTACK dogfood frames.
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
	hero.request_dash()
	var wait := 0
	while hero.visual_pack_id != &"frost_armed" and wait < 80:
		await _wait(0.05)
		wait += 1
	assert(hero.visual_pack_id == &"frost_armed", "armed pack must commit by the 1.2s unlock")
	assert(not bool(hero.call("_skill_controls_locked")), "controls unlock with the armed pack")
	await _wait(0.08)
	var t0 := hero.position
	_dump(hero, "T0")
	_save("LIVE-T0")
	hero.move_in_direction(Vector2.RIGHT, 0.35)
	hero.call("_update_animation_state")
	_dump(hero, "MOVE")
	_save("LIVE-MOVE")
	assert(hero.position.x >= t0.x + 24.0, "MOVE frame must show displacement vs T0")
	assert(hero.current_state == &"run", "MOVE frame must be the run clip")
	assert(str(hero.get_node("XSXBHeroActor").get("_current_animation")).begins_with("run"))
	hero.set("_move_input", Vector2.ZERO)
	hero.call("_set_state", &"idle")
	await process_frame
	hero.request_jump()
	await _wait(0.22)
	_dump(hero, "JUMP")
	_save("LIVE-JUMP")
	assert(float(hero.get("_jump_visual_offset")) < -28.0, "JUMP frame must be off-ground")
	assert(int(hero.get_node("XSXBHeroActor").get("_current_frame")) >= 2)
	await _wait(0.40)
	hero.call("_cancel_jump")
	await process_frame
	hero.request_attack()
	await _wait(0.10)
	_dump(hero, "ATTACK")
	_save("LIVE-ATTACK")
	assert(str(hero.get_node("XSXBHeroActor").get("_current_animation")).begins_with("attack"))
	assert(int(hero.get_node("XSXBHeroActor").get("_current_frame")) >= 12, "ATTACK frame must be the slash window")
	print("ARMED_WINDOW_CAPTURE_DONE pack=%s dx=%.1f lift=%.1f" % [
		String(hero.visual_pack_id),
		hero.position.x - t0.x,
		float(hero.get("_jump_visual_offset")),
	])
	quit()


func _dump(hero: EmberHero, label: String) -> void:
	var actor := hero.get_node_or_null("XSXBHeroActor")
	print("SHOT %s pack=%s state=%s play=%s frame=%s lift=%s vis=%s pos=%s" % [
		label,
		String(hero.visual_pack_id),
		String(hero.current_state),
		str(actor.get("_current_animation") if actor != null else ""),
		str(actor.get("_current_frame") if actor != null else ""),
		str(hero.get("_jump_offset")),
		str(hero.get("_jump_visual_offset")),
		str(hero.position),
	])


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _save(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP_SAVE %s (headless)" % name)
		return
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("SKIP_SAVE %s (no viewport texture)" % name)
		return
	var image := tex.get_image()
	if image == null:
		print("SKIP_SAVE %s (dummy renderer)" % name)
		return
	var full := "%s/%s.png" % [OUT, name]
	image.save_png(full)
	var crop := image.get_region(Rect2i(460, 80, 360, 480))
	crop.save_png("%s/%s-crop.png" % [OUT, name])
	print("SAVED %s" % full)

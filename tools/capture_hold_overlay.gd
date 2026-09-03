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
	hero.position = Vector2(640.0, 336.0)
	_snap_cam(cam, hero)
	await process_frame
	await process_frame
	_pose_hold(hero)
	await process_frame
	_pose_hold(hero)
	_dump(hero, "knight_idle")
	_save("res://tools/look-qa-knight-hold.png")

	hero.apply_hero_kind(&"assassin")
	hero.position = Vector2(640.0, 336.0)
	_snap_cam(cam, hero)
	hero.select_weapon_slot(0)
	await process_frame
	await process_frame
	_pose_hold(hero)
	await process_frame
	_pose_hold(hero)
	_dump(hero, "assassin_sword")
	_save("res://tools/look-qa-assassin-hold.png")

	hero.equip_weapon(&"pistol")
	await process_frame
	await process_frame
	_pose_hold(hero)
	await process_frame
	_pose_hold(hero)
	_dump(hero, "assassin_pistol")
	_save("res://tools/look-qa-assassin-gun.png")
	print("HOLD_OVERLAY_QA ok")
	quit()


func _pose_hold(hero: EmberHero) -> void:
	Input.warp_mouse(Vector2(640.0, 360.0))
	hero.set("_aim_dir", Vector2.RIGHT)
	hero.call("_apply_facing", 1)
	hero.call("_refresh_held_weapon")


func _snap_cam(cam: Camera2D, hero: Node2D) -> void:
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()


func _dump(hero: EmberHero, tag: String) -> void:
	var held := hero.find_child("HeldWeapon", true, false) as Sprite2D
	var pose := float(hero.call("_held_pose_scale"))
	var height := float(hero.call("_actor_on_screen_height"))
	var tex := "" if held == null or held.texture == null else held.texture.resource_path
	print(
		"HOLD %s kind=%s weapon=%s visible=%s tex=%s pos=%s scale=%s pose=%.3f height=%.1f"
		% [
			tag,
			String(hero.hero_kind),
			String(hero.current_weapon),
			str(held.visible) if held != null else "null",
			tex,
			str(held.position) if held != null else "null",
			str(held.scale) if held != null else "null",
			pose,
			height,
		]
	)


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

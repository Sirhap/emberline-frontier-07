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
	hero.apply_hero_kind(&"ember_hero")
	hero.equip_weapon(&"sword")
	_pose(hero)
	_snap(cam, hero.position)
	await process_frame
	await process_frame
	_save("res://tools/look-float-knight-sword.png")
	_print_float(hero, "knight-sword")

	hero.equip_weapon(&"pistol")
	_pose(hero)
	_snap(cam, hero.position)
	await process_frame
	await process_frame
	_save("res://tools/look-float-knight-pistol.png")
	_print_float(hero, "knight-pistol")

	hero.skill_levels[&"ember_hero"] = 1
	hero.call("_refresh_held_weapon")
	_pose(hero)
	_snap(cam, hero.position)
	await process_frame
	await process_frame
	_save("res://tools/look-float-knight-dual.png")
	_print_float(hero, "knight-dual")

	hero.skill_levels[&"ember_hero"] = 2
	hero.call("_refresh_held_weapon")
	_pose(hero)
	_snap(cam, hero.position)
	await process_frame
	await process_frame
	_save("res://tools/look-float-knight-triple.png")
	_print_float(hero, "knight-triple")

	hero.skill_levels[&"ember_hero"] = 0
	hero.turret_hand = true
	hero.add_turret(&"pulse")
	hero.call("_refresh_held_weapon")
	_pose(hero)
	Input.warp_mouse(Vector2(48.0, 48.0))
	scene.set("_place_preview_world", Vector2(INF, INF))
	scene.call("_sync_place_preview")
	_snap(cam, hero.position)
	await process_frame
	await process_frame
	_save("res://tools/look-float-knight-turret-hand.png")
	_print_float(hero, "knight-turret-hand")
	hero.turret_hand = false
	hero.call("_refresh_held_weapon")

	var pulse := scene.call("_spawn_tower_at", Vector2(990.0, 205.0), &"pulse", 1) as EmberTower
	scene.call("_select_tower", pulse)
	_snap(cam, hero.position)
	await process_frame
	await process_frame
	_save("res://tools/look-float-hud-tower-panel.png")
	print("HUD DefaultTowerButton=%s" % [scene.find_child("DefaultTowerButton", true, false) != null])

	hero.skill_levels[&"ember_hero"] = 0
	hero.apply_hero_kind(&"assassin")
	hero.equip_weapon(&"sword")
	hero.position = Vector2(640.0, 336.0)
	_pose(hero)
	_snap(cam, hero.position)
	await process_frame
	await process_frame
	_save("res://tools/look-float-assassin-sword.png")
	_print_float(hero, "assassin-sword")

	hero.equip_weapon(&"pistol")
	_pose(hero)
	_snap(cam, hero.position)
	await process_frame
	await process_frame
	_save("res://tools/look-float-assassin-pistol.png")
	_print_float(hero, "assassin-pistol")
	print("FLOAT_WEAPON_QA ok copies=%d" % hero.floating_weapon_count())
	quit()


func _pose(hero: EmberHero) -> void:
	Input.warp_mouse(Vector2(900.0, 336.0))
	hero.set("_aim_dir", Vector2.RIGHT)
	hero.call("_apply_facing", 1)
	hero.call("_refresh_held_weapon")


func _print_float(hero: EmberHero, tag: String) -> void:
	var visible_n := 0
	var parts: Array[String] = []
	for child in hero.get_children():
		if not (child is Sprite2D):
			continue
		var sprite := child as Sprite2D
		var name := String(sprite.name)
		if name != "HeldWeapon" and not name.begins_with("HeldOrbit"):
			continue
		if sprite.visible:
			visible_n += 1
		var tex := "" if sprite.texture == null else sprite.texture.resource_path.get_file()
		parts.append("%s vis=%s pos=%s tex=%s" % [name, sprite.visible, sprite.position, tex])
	print("%s kind=%s weapon=%s turret_hand=%s count=%d visible=%d | %s" % [
		tag,
		String(hero.hero_kind),
		String(hero.combat_weapon_id()),
		hero.turret_hand,
		hero.floating_weapon_count(),
		visible_n,
		" ; ".join(parts),
	])


func _snap(cam: Camera2D, world: Vector2) -> void:
	if cam != null:
		cam.global_position = world
		cam.reset_smoothing()
		cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

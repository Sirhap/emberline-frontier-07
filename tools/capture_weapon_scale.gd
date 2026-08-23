extends SceneTree

const SAMPLES: Array[StringName] = [
	&"dagger", &"azure-blade", &"mallet", &"chainsaw",
	&"pistol", &"ion-pistol", &"smg", &"gatling",
	&"short-shotgun", &"rocket-launcher", &"inferno-cannon",
	&"wood-bow", &"frost-staff", &"shuriken", &"grenade", &"rainbow-gun",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.call("_toggle_dev_mode")
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.position = Vector2(640.0, 336.0)
	scene.call("_dev_spawn", &"scout")
	await create_timer(0.15).timeout
	_print_scales()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/scale-shots"))
	for weapon_id: StringName in SAMPLES:
		hero.equip_weapon(weapon_id)
		hero.set("_aim_dir", Vector2.RIGHT)
		hero.call("_apply_facing", 1)
		await process_frame
		var weapon := WeaponCatalog.get_def(weapon_id)
		if WeaponCatalog.is_ranged(weapon_id):
			scene.call("_play_attack")
			await create_timer(0.07).timeout
		else:
			scene.call("_play_attack")
			await create_timer(0.10).timeout
		_save_zoom(hero, "res://tools/scale-shots/%s.png" % String(weapon_id))
		print("SHOT %s hold=%.3f fx=%.3f kind=%s" % [
			String(weapon_id),
			float(weapon["hold_scale"]),
			float(weapon["fx_scale"]),
			String(weapon["kind"]),
		])
	print("SCALE_CAPTURE ok")
	quit()


func _print_scales() -> void:
	print("SCALE_TABLE id kind hold fx pickup")
	for weapon_id: StringName in WeaponCatalog.all_ids():
		var weapon := WeaponCatalog.get_def(weapon_id)
		print("SCALE %s %s %.3f %.3f %.3f" % [
			String(weapon_id),
			String(weapon["kind"]),
			float(weapon.get("hold_scale", 0.0)),
			float(weapon.get("fx_scale", 0.0)),
			float(weapon.get("pickup_scale", 0.0)),
		])


func _save_zoom(hero: Node2D, path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var center := hero.global_position
	var region := Rect2i(int(center.x) - 140, int(center.y) - 130, 300, 240)
	region = region.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var crop := image.get_region(region)
	var err := crop.save_png(path)
	print("SAVED %s err=%s" % [path, err])

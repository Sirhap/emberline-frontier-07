extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get("_hero")
	if hero == null:
		hero = scene.get_node("HeroSlot/HeroController") as EmberHero
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	hero.position = Vector2(640.0, 336.0)
	hero.debug_god = true
	hero.apply_skill_upgrade()
	hero.apply_skill_upgrade()
	hero.equip_weapon(&"sword")
	hero._apply_facing(1)
	hero._aim_dir = Vector2.RIGHT
	if cam != null:
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()
	scene.call("_dev_spawn", &"scout")
	await process_frame
	var foes: Array = scene.get_active_enemies()
	if not foes.is_empty():
		var foe: FrontierEnemy = foes[0]
		foe.global_position = hero.global_position + Vector2(-150.0, 8.0)
		foe.set_process(false)
	await process_frame
	await process_frame
	# Face right first, then tap attack: lock should flip toward the left scout.
	hero._apply_facing(1)
	hero._aim_dir = Vector2.RIGHT
	scene.call("_play_attack")
	# Same-tap window: a few frames into the clip, floats should already be swinging.
	for _i in range(10):
		await process_frame
	_dump("lock+floats", hero, scene)
	_save("res://dogfood-output/qa/combat-floats-attack.png")
	_save("res://dogfood-output/qa/combat-lock-face.png")

	# Pistol + bigger muzzle/bullet — fresh living scout so lock can flip left.
	hero.equip_weapon(&"pistol")
	hero._attack_elapsed = -1.0
	hero._attack_cooldown = 0.0
	hero._attack_lock = null
	scene.call("_dev_spawn", &"scout")
	await process_frame
	var more: Array = scene.get_active_enemies()
	for foe3 in more:
		if is_instance_valid(foe3) and foe3.is_active():
			foe3.global_position = hero.global_position + Vector2(-150.0, 0.0)
			foe3.set_process(false)
	hero._apply_facing(1)
	hero._aim_dir = Vector2.RIGHT
	scene.call("_play_attack")
	for _i in range(3):
		await process_frame
	_dump("pistol", hero, scene)
	_save("res://dogfood-output/qa/combat-pistol-fx.png")
	quit()


func _dump(tag: String, hero: EmberHero, scene: Node) -> void:
	var floats := hero.combat_float_origins()
	print("TAG %s facing=%s aim=%s floats=%s weapon=%s state=%s" % [
		tag, hero.get_facing(), hero.aim_direction(), floats, hero.combat_weapon_id(), hero.current_state
	])
	var pistol := WeaponCatalog.get_def(&"pistol")
	var sword := WeaponCatalog.get_def(&"sword")
	print("FX pistol=%s sword=%s muzzle_kids=%s" % [
		pistol.get("fx_scale"), sword.get("fx_scale"), scene.find_child("MuzzleFlash", true, false) != null
	])


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s size=%sx%s" % [path, err, image.get_width(), image.get_height()])

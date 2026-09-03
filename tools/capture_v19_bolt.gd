extends SceneTree

const OUT_DIR := "res://dogfood-output/qa"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false

	scene.set("current_wave", 2)
	scene.set("_spawned_in_wave", 4)
	var wave2_kind: StringName = scene.call("_pick_spawn_variant")
	print("PICK_WAVE2_SLOT4 kind=%s" % wave2_kind)

	# Drive a real wave-2 combat so slot 4 can spawn a mage.
	var director: WaveDirector = scene.get("_director")
	director.current_wave = 1
	director.phase = WaveDirector.PREP
	scene.call("start_wave")
	print("started wave=%s combat=%s remaining=%s" % [
		scene.get("current_wave"), director.is_combat(), scene.get("_spawn_remaining"),
	])

	hero.position = Vector2(640.0, 336.0)
	scene.set("_dev_god", true)
	if hero != null:
		hero.debug_god = true
	_aim(scene, hero, cam)

	var mage: FrontierEnemy = null
	var forced := false
	for _i: int in range(420):
		await process_frame
		for enemy: Variant in scene.get("_enemies"):
			if enemy is FrontierEnemy and is_instance_valid(enemy) and enemy.variant == &"mage":
				mage = enemy
				break
		if mage != null:
			break
	if mage == null:
		forced = true
		mage = FrontierEnemy.new()
		mage.variant = &"mage"
		mage.max_health = 9999
		mage.move_speed = 0.0
		mage.contact_damage = 10
		mage.configure_seek(Vector2(800.0, 336.0), scene.call("core_goal") as Vector2, scene)
		scene.call("_register_enemy", mage)
		print("FORCE mage at %s" % mage.global_position)
	else:
		print("REAL wave2 mage at %s spawned_in=%s" % [mage.global_position, scene.get("_spawned_in_wave")])
		mage.move_speed = 0.0
		mage.max_health = 9999
		mage.health = 9999

	# Park hero 150px left so the bolt has travel time.
	hero.position = mage.global_position + Vector2(-150.0, 8.0)
	hero.set("_aim_dir", Vector2.RIGHT)
	hero.call("_apply_facing", 1)
	_aim(scene, hero, cam)
	await process_frame
	await process_frame

	var shots: Array = []
	mage.shot_fired.connect(func(_e, dir, dmg): shots.append({"dir": dir, "dmg": dmg}))

	var saved := 0
	for tick: int in range(240):
		if not is_instance_valid(mage):
			break
		var gap := mage.global_position.distance_to(hero.global_position)
		if gap < 70.0 or gap > 180.0:
			hero.position = mage.global_position + Vector2(-150.0, 8.0)
		_aim(scene, hero, cam)
		await process_frame
		var bolts := _count_bolts(scene)
		if shots.size() > 0 and bolts > 0:
			_aim(scene, hero, cam)
			RenderingServer.force_draw()
			await RenderingServer.frame_post_draw
			await _save("v19-mage-bolt")
			await _save("mage-shot")
			# extras mid-flight
			await _save("v19-mage-bolt-f1")
			saved = 1
			print("BOLT frame1 shots=%d bolts=%d dist=%.1f" % [shots.size(), bolts, gap])
			await process_frame
			bolts = _count_bolts(scene)
			if bolts > 0:
				await _save("v19-mage-bolt-f2")
				print("BOLT frame2 bolts=%d" % bolts)
			break
	if saved == 0:
		# last-ditch: spawn a visible bolt ourselves from the mage
		if is_instance_valid(mage):
			var dir := (hero.global_position - mage.global_position).normalized()
			scene.call("spawn_enemy_projectile", mage.global_position + Vector2(0.0, -28.0), dir, 10)
			await process_frame
			RenderingServer.force_draw()
			await RenderingServer.frame_post_draw
			await _save("v19-mage-bolt")
			await _save("mage-shot")
			print("BOLT last-ditch spawned bolts=%d" % _count_bolts(scene))
		else:
			print("BOLT FAIL no mage")

	print("V19_DONE forced=%s pick=%s shots=%d" % [forced, wave2_kind, shots.size()])
	quit()


func _count_bolts(scene: Node) -> int:
	var n := 0
	var bullets: Array = scene.get("_live_bullets") if scene.get("_live_bullets") != null else []
	for bullet: Variant in bullets:
		if bullet is EnemyProjectile and is_instance_valid(bullet) and bullet.visible:
			n += 1
	return n


func _aim(scene: Node, hero: Node2D, cam: Camera2D) -> void:
	if cam == null:
		return
	cam.position_smoothing_enabled = false
	cam.zoom = scene.call("camera_zoom_for", hero.position) as Vector2
	cam.global_position = scene.call("camera_target_for", hero.global_position) as Vector2
	cam.reset_smoothing()
	cam.force_update_scroll()


func _save(shot_name: String) -> void:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT_DIR, shot_name]
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("SAVED %s err=no-texture" % path)
		return
	var image := tex.get_image()
	if image == null:
		print("SAVED %s err=no-image" % path)
		return
	var err := image.save_png(path)
	print("SAVED %s err=%s %sx%s" % [path, err, image.get_width(), image.get_height()])

extends SceneTree

const OUT := "res://dogfood-output/qa"
const PAD := Vector2(648.0, 336.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.enabled = true
	scene.set("_camera", null)

	var tower: EmberTower = scene.call("_spawn_tower_at", PAD, &"pulse", 1)
	scene.call("_select_tower", null)
	tower.take_damage(55)
	tower.queue_redraw()
	hero.position = PAD + Vector2(-90.0, 48.0)
	_lock_cam(cam, PAD + Vector2(0.0, -28.0), 1.70)
	await _settle(cam, PAD + Vector2(0.0, -28.0))
	await _save("tower-hp")
	print("SHOT tower-hp health=%s/%s pos=%s" % [tower.health, tower.max_health, tower.global_position])

	hero.position = Vector2(180.0, 640.0)
	var scout := FrontierEnemy.new()
	scout.variant = &"scout"
	scout.max_health = 9999
	scout.move_speed = 36.0
	scout.contact_damage = 8
	scout.configure_seek(PAD + Vector2(30.0, 8.0), scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", scout)
	var hp_before := tower.health
	for _i: int in range(90):
		await process_frame
		if scout.get("_attacking") or (is_instance_valid(tower) and tower.health < hp_before):
			if _i >= 6:
				break
	_lock_cam(cam, PAD + Vector2(8.0, -20.0), 1.70)
	await _settle(cam, PAD + Vector2(8.0, -20.0))
	await _save("tower-hit")
	print("SHOT tower-hit attacking=%s tower_hp=%s->%s lock=%s dist=%.1f" % [
		scout.get("_attacking"),
		hp_before,
		tower.health if is_instance_valid(tower) else -1,
		scout.get("_tower_target") != null,
		scout.global_position.distance_to(PAD),
	])

	if is_instance_valid(tower):
		tower.take_damage(999)
	if is_instance_valid(scout):
		scout.queue_free()
	await process_frame
	await process_frame
	hero.position = PAD + Vector2(20.0, 16.0)
	scene.call("_update_rebuild_prompt")
	_lock_cam(cam, PAD + Vector2(0.0, -24.0), 1.70)
	await _settle(cam, PAD + Vector2(0.0, -24.0))
	await _save("tower-wreck")
	print("SHOT tower-wreck towers=%s wrecks=%s" % [
		(scene.get("_towers") as Array).size(),
		(scene.get("_wrecked_cells") as Dictionary).size(),
	])

	scene.set("scrap", 300)
	var rebuilt := bool(scene.call("try_rebuild_nearby"))
	scene.call("_select_tower", null)
	await process_frame
	await process_frame
	_lock_cam(cam, PAD + Vector2(0.0, -24.0), 1.70)
	await _settle(cam, PAD + Vector2(0.0, -24.0))
	await _save("tower-rebuild")
	var live: Array = scene.get("_towers")
	print("SHOT tower-rebuild ok=%s n=%s scrap=%s kind=%s" % [
		rebuilt,
		live.size(),
		int(scene.get("scrap")),
		live[0].kind if live.size() > 0 else &"",
	])
	print("TOWER_QA_CAPTURE ok")
	quit()


func _lock_cam(cam: Camera2D, at: Vector2, zoom: float) -> void:
	if cam == null:
		return
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(zoom, zoom)
	cam.global_position = at
	cam.reset_smoothing()
	cam.force_update_scroll()


func _settle(cam: Camera2D, at: Vector2) -> void:
	_lock_cam(cam, at, 1.70)
	await process_frame
	await process_frame
	_lock_cam(cam, at, 1.70)
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT, name]
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("SAVED %s err=no-texture" % path)
		return
	var image := tex.get_image()
	if image == null:
		print("SAVED %s err=no-image" % path)
		return
	var err := image.save_png(path)
	print("SAVED %s err=%s size=%sx%s" % [path, err, image.get_width(), image.get_height()])

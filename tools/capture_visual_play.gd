extends SceneTree

## Player-view shots: field / door / shop. Does not touch user://run.json.

const OUT := "res://dogfood-output/visual-qa"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.zoom = scene.call("camera_zoom_for", hero.global_position) as Vector2

	var spots: Array = [
		["play-field", Vector2(640.0, 336.0)],
		["play-door", Vector2(568.0, 40.0)],
		["play-shop", Vector2(560.0, -90.0)],
		["play-merchant", Vector2(250.0, -90.0)],
		["play-lower", Vector2(560.0, 760.0)],
		["play-hall", Vector2(40.0, 336.0)],
		["play-portal-north", Vector2(1413.0, -480.0)],
	]
	for spot: Array in spots:
		hero.position = spot[1]
		hero.call("_apply_facing", 1)
		if hero.has_method("_set_state"):
			hero.call("_set_state", &"idle")
		if cam != null:
			cam.zoom = scene.call("camera_zoom_for", hero.global_position) as Vector2
		_aim(cam, hero)
		await _settle()
		await _save(String(spot[0]))

	var pad: EmberTower = null
	for tower_v: Variant in scene.get("_towers"):
		var tower: EmberTower = tower_v
		if tower != null and tower.is_hologram_pad() and tower.weapon_id == &"":
			pad = tower
			break
	if pad != null:
		hero.set_turret_hand(false)
		hero.equip_weapon(&"pistol")
		hero.position = pad.global_position + Vector2(-48.0, 8.0)
		scene.call("_try_place_tower", pad.global_position)
		_aim(cam, hero)
		await _settle()
		await _save("play-mounted-pistol")
		pad.set("_cooldown_left", 0.0)
		pad.call("_process", 0.016)
		_aim(cam, hero)
		await _settle()
		await _save("play-mounted-aim")

	hero.add_turret(&"pulse")
	hero.set_turret_hand(true)
	hero.position = Vector2(640.0, 336.0)
	scene.set("_place_preview_world", scene.call("core_goal"))
	scene.call("_sync_place_preview")
	_aim(cam, hero)
	await _settle()
	await _save("play-core-ghost")

	print("VISUAL_QA ok %s" % OUT)
	quit()


func _aim(cam: Camera2D, hero: Node2D) -> void:
	if cam == null:
		return
	cam.global_position = hero.global_position
	cam.reset_smoothing()
	cam.force_update_scroll()


func _settle() -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	await process_frame


func _save(shot_name: String) -> void:
	RenderingServer.force_draw()
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUT, shot_name]
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

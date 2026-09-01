extends SceneTree

## Headless captures: home hub, talent cards, HUD level chip.

const EmberRunSave := preload("res://scripts/run_save.gd")
const TalentCatalog := preload("res://scripts/talent_catalog.gd")
const OUT_DIR := "/tmp/ember-captures"

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await _capture_home()
	await _capture_talent()
	await _capture_hud()
	print("HOME TALENT HUD CAPTURE ok")
	quit()


func _capture_home() -> void:
	var hub: Node2D = load("res://scenes/home/home_hub.tscn").instantiate()
	root.add_child(hub)
	hub.configure({
		"codex": {
			"weapons": {"sword": {"discovered": true}, "pistol": {"discovered": true}},
			"enemies": {"scout": {"seen": true, "kills": 4, "leaks": 1}},
		},
		"records": {"highest_wave": 6, "best_kills": 18, "best_survive_time": 90.0},
	}, {})
	await _settle()
	_save("home-empty.png")

	hub.confirm_hero(&"ember_hero")
	await _settle()
	_save("home-knight.png")

	hub.call("open_weapon_codex")
	await _settle()
	_save("home-weapon-codex.png")

	hub.call("open_enemy_codex")
	await _settle()
	_save("home-enemy-codex.png")

	hub.call("open_records")
	await _settle()
	_save("home-records.png")

	hub.find_child("CodexPanel", true, false).call("hide_panel")
	hub.confirm_hero(&"assassin")
	hub.try_open_portal()
	await _settle()
	_save("home-portal-mode.png")

	hub.queue_free()
	await process_frame


func _capture_talent() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await _settle()
	var overlay: Node = scene.find_child("TalentChoiceOverlay", true, false)
	if overlay == null:
		overlay = scene.get("_talent_overlay")
	var hud: Node = scene.find_child("FrontierHud", true, false)
	if hud == null:
		hud = scene.get("_hud")
	if hud != null and hud.has_method("set_hero_xp"):
		hud.call("set_hero_xp", 3, 12, 80)
		hud.call("set_hero_hp", 120, 120, false)
	overlay.show_choices(3, [
		TalentCatalog.get_def(&"force_training"),
		TalentCatalog.get_def(&"tempered_body"),
		TalentCatalog.get_def(&"swift_step"),
	], {&"force_training": 1})
	await _settle()
	_save("talent-three-pick.png")
	scene.queue_free()
	await process_frame


func _capture_hud() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await _settle()
	var hud: Node = scene.find_child("FrontierHud", true, false)
	if hud == null:
		hud = scene.get("_hud")
	if hud != null and hud.has_method("set_hero_xp"):
		hud.call("set_hero_xp", 4, 28, 100)
		hud.call("set_hero_hp", 96, 120, false)
		if hud.has_method("set_hero_armor"):
			hud.call("set_hero_armor", 2, 2)
	var hero: Node2D = scene.find_child("HeroController", true, false)
	var cam: Camera2D = scene.get("_camera")
	if cam != null and hero != null:
		cam.position_smoothing_enabled = false
		cam.global_position = hero.global_position
		cam.reset_smoothing()
		cam.force_update_scroll()
	await _settle()
	_save("hud-level-chip.png")
	scene.queue_free()
	await process_frame


func _settle() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var path := "%s/%s" % [OUT_DIR, name]
	var err := image.save_png(path)
	print("SAVED %s %dx%d err=%s" % [path, image.get_width(), image.get_height(), err])

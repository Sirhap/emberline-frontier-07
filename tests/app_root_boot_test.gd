extends SceneTree

const EmberRunSave := preload("res://scripts/run_save.gd")
const EmberHero := preload("res://scripts/hero.gd")
const EmberMetaSave := preload("res://scripts/meta_save.gd")


func _init() -> void:
	create_timer(45.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	EmberMetaSave.delete_profile(EmberMetaSave.SMOKE_PATH)
	assert(FileAccess.file_exists("res://scenes/app_root.tscn"), "app_root scene exists")
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "AppRoot boots into HomeHub")
	assert(root_scene.find_child("HeroController", true, false) == null, "home does not instance the battlefield hero")
	hub.call("confirm_hero", &"ember_hero")
	hub.call("confirm_new_run")
	await process_frame
	await process_frame
	var hero := root_scene.find_child("HeroController", true, false)
	assert(hero != null, "new run from home adds the battlefield")
	assert((hero as EmberHero).hero_kind == &"ember_hero", "home knight pick launches knight")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()
	print("APP ROOT BOOT PASS")
	quit()

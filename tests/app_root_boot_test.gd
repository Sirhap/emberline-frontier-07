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
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "AppRoot boots into character select")
	assert(root_scene.find_child("HomeHub", true, false) == null, "home waits until a hero is confirmed")
	var title := select.find_child("Title", true, false) as Label
	assert(title != null and title.text == "角色选择", "select title is CJK, not tofu")
	var skin := select.find_child("SkinButton", true, false) as Button
	assert(skin != null and skin.text == "皮肤", "select card has a skin chip")
	select.call("select_hero", &"ember_hero")
	select.call("_on_skin")
	var picker := select.find_child("SkinPicker", true, false)
	assert(picker != null, "skin chip opens the imported-pack list")
	assert(picker.find_child("SkinChip_ember_hero", true, false) != null, "skin picker shows a portrait chip")
	select.call("_hide_skin_picker")
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "confirming a hero opens HomeHub")
	assert(root_scene.find_child("HeroController", true, false) == null, "home does not instance the battlefield hero")
	hub.call("confirm_new_run")
	await process_frame
	await process_frame
	var hero := root_scene.find_child("HeroController", true, false)
	assert(hero != null, "new run from home adds the battlefield")
	assert((hero as EmberHero).hero_kind == &"ember_hero", "home start launches the default knight")
	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()
	print("APP ROOT BOOT PASS")
	quit()

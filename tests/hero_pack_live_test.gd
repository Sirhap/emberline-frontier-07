extends SceneTree

const EmberHero := preload("res://scripts/hero.gd")
const HeroPackCatalog := preload("res://scripts/hero_pack_catalog.gd")
const HeroPackImporter := preload("res://scripts/hero_pack_importer.gd")
const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")
const EmberMetaSave := preload("res://scripts/meta_save.gd")
const EmberRunSave := preload("res://scripts/run_save.gd")


func _init() -> void:
	create_timer(45.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	HeroPackCatalog.load_from("res://data/imported_hero_packs.json")
	assert(HeroPackCatalog.selectable_skin_ids(&"ember_hero").has(&"ember_hero"), "knight default skin listed")
	assert(HeroPackCatalog.selectable_skin_ids(&"assassin").has(&"assassin"), "assassin default skin listed")

	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null)
	select.call("select_hero", &"ember_hero")
	select.call("_on_skin")
	var picker := select.find_child("SkinPicker", true, false)
	assert(picker != null, "skin picker opens")
	assert(picker.find_child("SkinChip_ember_hero", true, false) != null, "picker previews the default skin")
	assert(picker.find_child("SkinChip_frost_warrior", true, false) != null, "picker previews frost warrior")
	assert(picker.find_child("SkinChip_frost_armed", true, false) == null, "armed form is not a selectable skin")
	var frost_art := picker.find_child("SkinChip_frost_warrior", true, false).find_child("Art", true, false) as TextureRect
	assert(frost_art != null and frost_art.texture != null, "frost chip shows a portrait")
	select.call("_preview_skin", &"frost_warrior")
	var knight_card := select.find_child("Slot_ember_hero", true, false)
	assert(knight_card != null)
	assert(String(knight_card.get("sprite_path")).contains("frost_warrior"), "hovering frost previews it on the knight card")
	select.call("_pick_skin", &"frost_warrior")
	assert(select.call("selected_skin_id") == &"frost_warrior")
	select.call("_hide_skin_picker")
	select.call("select_hero", &"assassin")
	assert(select.call("selected_hero_id") == &"assassin")
	select.call("confirm_current")
	await process_frame
	await process_frame
	var hub := root_scene.find_child("HomeHub", true, false)
	assert(hub != null, "assassin confirm opens home")
	var walker := hub.find_child("HomeWalker", true, false) as EmberHero
	assert(walker != null)
	assert(walker.hero_kind == &"assassin", "home walker uses assassin combat")
	assert(walker.visual_pack_id == &"assassin", "home walker uses default assassin pack")
	var actor := walker.get_node_or_null("XSXBHeroActor")
	assert(actor != null)
	assert(str(actor.get("frame_profile_id")) == "ember_assassin")

	var incomplete := "user://hero_pack_live_incomplete"
	_rm_tree(incomplete)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(incomplete))
	var meta := FileAccess.open("%s/pack.json" % incomplete, FileAccess.WRITE)
	meta.store_string(JSON.stringify({
		"kind": "skin",
		"id": "knight_gold",
		"title": "金甲",
		"base": "ember_hero",
		"view_mode": "three",
	}))
	meta.close()
	for slot: String in ["idle", "run", "jump", "attack", "dash", "down"]:
		for view: String in ["front", "side"]:
			var folder := "%s/%s/%s" % [incomplete, slot, view]
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
			_tiny_png("%s/00.png" % folder)
	var rejected: Dictionary = HeroPackImporter.import_pack(incomplete, {
		"assets_root": "user://hero_pack_live_dest/assets",
		"manifest_path": "user://hero_pack_live_dest/animation_manifest.json",
		"catalog_path": "user://hero_pack_live_dest/catalog.json",
	})
	assert(not bool(rejected.get("ok", true)), "incomplete three-view pack must not import")
	assert(not HeroPackCatalog.selectable_skin_ids(&"ember_hero").has(&"knight_gold"), "incomplete skin stays unselectable")

	root_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()
	HeroPackCatalog.load_from("res://data/imported_hero_packs.json")
	print("HERO PACK LIVE PASS")
	quit()


func _tiny_png(path: String) -> void:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(8):
		image.set_pixel(x, 7, Color(1, 0, 0, 1))
	image.save_png(path)


func _rm_tree(path: String) -> void:
	var abs_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(abs_path) and not FileAccess.file_exists(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var child := "%s/%s" % [path, name]
		if dir.current_is_dir():
			_rm_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(abs_path)

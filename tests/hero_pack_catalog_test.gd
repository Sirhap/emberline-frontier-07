extends SceneTree

const HeroPackCatalog := preload("res://scripts/hero_pack_catalog.gd")
const HeroPackValidator := preload("res://scripts/hero_pack_validator.gd")
const HeroPackImporter := preload("res://scripts/hero_pack_importer.gd")
const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")
const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")

const KNIGHT_DIR := "res://xsxb_frame_tuner/workspace/projects/emberline_frontier_07_final/assets/ember_hero"
const ASSASSIN_DIR := "res://xsxb_frame_tuner/workspace/projects/emberline_enemies/assets/ember_assassin"
const FIXTURE := "user://hero_pack_fixture"
const IMPORT_ASSETS := "user://hero_pack_import/assets"
const IMPORT_MANIFEST := "user://hero_pack_import/animation_manifest.json"
const IMPORT_CATALOG := "user://hero_pack_import/catalog.json"


func _init() -> void:
	create_timer(40.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	HeroPackCatalog.load_from("res://data/imported_hero_packs.json")
	var knight: Dictionary = HeroPackValidator.validate_dir(KNIGHT_DIR)
	assert(bool(knight.get("complete", false)), "builtin knight pack must be COMPLETE %s" % str(knight.get("missing", [])))
	assert(String(knight.get("view_mode", "")) == "side_flip")
	var assassin: Dictionary = HeroPackValidator.validate_dir(ASSASSIN_DIR)
	assert(bool(assassin.get("complete", false)), "builtin assassin pack must be COMPLETE %s" % str(assassin.get("missing", [])))

	HeroPackCatalog.load_from("res://data/imported_hero_packs.json")
	assert(not HeroPackCatalog.pack_by_id(&"ember_hero").is_empty(), "default knight skin exists")
	var skins: Array = HeroPackCatalog.skins_for(&"ember_hero")
	assert(not skins.is_empty(), "knight has a default skin")
	assert(String((skins[0] as Dictionary).get("id", "")) == "ember_hero")
	assert(HeroPackCatalog.selectable_skin_ids(&"assassin").has(&"assassin"))
	assert(not HeroDefinitionCatalog.has_id(&"blade_custom"), "fixture hero must not leak from empty catalog")

	_reset_fixture()
	_write_three_view_pack(FIXTURE, "knight_gold", "skin", "ember_hero", "金甲")
	var gold_report: Dictionary = HeroPackValidator.validate_dir(FIXTURE)
	assert(bool(gold_report.get("complete", false)), "fixture three-view pack should validate %s" % str(gold_report.get("missing", [])))

	_reset_import_dest()
	var imported: Dictionary = HeroPackImporter.import_pack(FIXTURE, {
		"project_id": "test_project",
		"assets_root": IMPORT_ASSETS,
		"manifest_path": IMPORT_MANIFEST,
		"catalog_path": IMPORT_CATALOG,
	})
	assert(bool(imported.get("ok", false)), "import should succeed %s" % str(imported))
	assert(FileAccess.file_exists("%s/knight_gold/idle/front/00.png" % IMPORT_ASSETS), "copied idle/front")
	var manifest_text := FileAccess.get_file_as_string(IMPORT_MANIFEST)
	assert(manifest_text.contains("idle_front"), "manifest has idle_front")
	assert(manifest_text.contains("dash_back"), "manifest has dash_back")
	HeroPackCatalog.load_from(IMPORT_CATALOG)
	assert(HeroPackCatalog.selectable_skin_ids(&"ember_hero").has(&"knight_gold"), "imported skin is selectable")
	assert(not HeroDefinitionCatalog.has_id(&"knight_gold"), "skin does not add a playable hero")

	_reset_fixture()
	_write_three_view_pack(FIXTURE, "blade_custom", "hero", "assassin", "刃影", true)
	var hero_imported: Dictionary = HeroPackImporter.import_pack(FIXTURE, {
		"project_id": "test_project",
		"assets_root": IMPORT_ASSETS,
		"manifest_path": IMPORT_MANIFEST,
		"catalog_path": IMPORT_CATALOG,
	})
	assert(bool(hero_imported.get("ok", false)), "hero import should succeed %s" % str(hero_imported))
	HeroPackCatalog.load_from(IMPORT_CATALOG)
	assert(HeroDefinitionCatalog.has_id(&"blade_custom"), "imported hero is playable")
	assert(HeroDefinitionCatalog.combat_base(&"blade_custom") == &"assassin", "imported hero clones assassin combat")
	assert(int(HeroDefinitionCatalog.stats_at_level(&"blade_custom", 1)["max_health"]) == 105)
	assert(HeroPackCatalog.pack_by_id(&"blade_custom").get("kind", "") == "hero")
	var select := (load("res://scenes/ui/character_select.tscn") as PackedScene).instantiate()
	root.add_child(select)
	await process_frame
	assert(select.find_child("Slot_blade_custom", true, false) != null, "imported hero gets a select card")
	select.queue_free()
	await process_frame

	HeroPackCatalog.load_from("res://data/imported_hero_packs.json")
	print("HERO PACK CATALOG PASS")
	quit()


func _reset_fixture() -> void:
	_rm_tree(FIXTURE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE))


func _reset_import_dest() -> void:
	_rm_tree("user://hero_pack_import")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://hero_pack_import"))


func _write_three_view_pack(root: String, pack_id: String, kind: String, base: String, title: String, assassin_slots: bool = false) -> void:
	var meta := {
		"kind": kind,
		"id": pack_id,
		"title": title,
		"base": base,
		"view_mode": "three",
	}
	var file := FileAccess.open("%s/pack.json" % root, FileAccess.WRITE)
	file.store_string(JSON.stringify(meta))
	file.close()
	var slots: Array = ["idle", "jump", "attack", "down"]
	if assassin_slots:
		slots.append_array(["walk", "attack_b", "skill_cast", "skill_bubble"])
	else:
		slots.append_array(["run", "dash"])
	for slot: String in slots:
		for view: String in HeroPackSpec.VIEWS:
			var path := "%s/%s/%s" % [root, slot, view]
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
			_tiny_png("%s/00.png" % path)


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

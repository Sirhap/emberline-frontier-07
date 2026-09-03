extends SceneTree

const HeroPackCatalog := preload("res://scripts/hero_pack_catalog.gd")
const HeroPackImporter := preload("res://scripts/hero_pack_importer.gd")
const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")
const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")

const ASSETS := "user://pack_studio_test/assets"
const MANIFEST := "user://pack_studio_test/animation_manifest.json"
const CATALOG := "user://pack_studio_test/catalog.json"
const PNG_A := "user://pack_studio_test/a.png"
const PNG_B := "user://pack_studio_test/b.png"


func _init() -> void:
	create_timer(40.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	_reset()
	_tiny_png(PNG_A, Color(1, 0, 0, 1))
	_tiny_png(PNG_B, Color(0, 0, 1, 1))
	var opts := {
		"project_id": "studio_test",
		"assets_root": ASSETS,
		"manifest_path": MANIFEST,
		"catalog_path": CATALOG,
	}

	var blocked: Dictionary = HeroPackImporter.create_draft("ember_hero", "骑士", "skin", "ember_hero", opts)
	assert(not bool(blocked.get("ok", false)), "cannot draft over builtin id")
	assert(not bool(HeroPackImporter.delete_imported("assassin", opts).get("ok", false)), "cannot delete builtin")

	var draft: Dictionary = HeroPackImporter.create_draft("gold_draft", "金甲草稿", "skin", "ember_hero", opts)
	assert(bool(draft.get("ok", false)), "create_draft %s" % str(draft))
	var pack_id := "gold_draft"
	HeroPackCatalog.load_from(CATALOG)
	assert(not bool(HeroPackCatalog.pack_by_id(&"gold_draft").get("complete", true)), "draft starts incomplete")
	assert(not HeroPackCatalog.selectable_skin_ids(&"ember_hero").has(&"gold_draft"), "incomplete draft is not selectable")
	assert(not HeroDefinitionCatalog.has_id(&"gold_draft"), "skin draft is not a hero")

	var one: Dictionary = HeroPackImporter.add_frames(pack_id, "idle", "side", PackedStringArray([PNG_A]), "append", opts)
	assert(bool(one.get("ok", false)), "add idle/side %s" % str(one))
	assert(HeroPackImporter.list_frames(pack_id, "idle", "side", opts).size() == 1)
	HeroPackCatalog.load_from(CATALOG)
	assert(not bool(HeroPackCatalog.pack_by_id(&"gold_draft").get("complete", true)))
	assert(not HeroPackCatalog.selectable_skin_ids(&"ember_hero").has(&"gold_draft"))

	var before := String(HeroPackImporter.list_frames(pack_id, "idle", "side", opts)[0])
	var replaced: Dictionary = HeroPackImporter.replace_frame(pack_id, "idle", "side", 0, PNG_B, opts)
	assert(bool(replaced.get("ok", false)), "replace_frame %s" % str(replaced))
	assert(String(replaced.get("path", "")) == before, "replace keeps the same path")
	var image := Image.new()
	assert(image.load(ProjectSettings.globalize_path(before)) == OK)
	assert(image.get_pixel(0, 7) == Color(0, 0, 1, 1), "replaced pixels match PNG_B")

	for slot: String in ["idle", "run", "jump", "attack", "dash", "down"]:
		for view: String in HeroPackSpec.VIEWS:
			if slot == "idle" and view == "side":
				continue
			var added: Dictionary = HeroPackImporter.add_frames(pack_id, slot, view, PackedStringArray([PNG_A]), "replace", opts)
			assert(bool(added.get("ok", false)), "fill %s/%s %s" % [slot, view, str(added)])

	var pub: Dictionary = HeroPackImporter.publish(pack_id, opts)
	assert(bool(pub.get("ok", false)), "publish %s" % str(pub))
	HeroPackCatalog.load_from(CATALOG)
	assert(bool(HeroPackCatalog.pack_by_id(&"gold_draft").get("complete", false)), "published pack is complete")
	assert(HeroPackCatalog.selectable_skin_ids(&"ember_hero").has(&"gold_draft"), "published skin appears on knight")

	var zip_path := "user://pack_studio_test/gold_draft.zip"
	var zipped: Dictionary = HeroPackImporter.export_zip(pack_id, zip_path, opts)
	assert(bool(zipped.get("ok", false)), "export_zip %s" % str(zipped))
	assert(FileAccess.file_exists(zip_path), "zip exists")

	assert(bool(HeroPackImporter.delete_imported(pack_id, opts).get("ok", false)))
	HeroPackCatalog.load_from(CATALOG)
	assert(HeroPackCatalog.pack_by_id(&"gold_draft").is_empty(), "deleted pack leaves catalog")
	assert(not HeroPackCatalog.selectable_skin_ids(&"ember_hero").has(&"gold_draft"))

	HeroPackCatalog.load_from("res://data/imported_hero_packs.json")
	print("HERO PACK STUDIO PASS")
	quit()


func _reset() -> void:
	_rm_tree("user://pack_studio_test")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://pack_studio_test"))
	HeroPackCatalog.load_from(CATALOG)


func _tiny_png(path: String, color: Color) -> void:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(8):
		image.set_pixel(x, 7, color)
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

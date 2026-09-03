extends SceneTree

## OpenGL snapshot of the in-game pack studio from character select.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	for _i in range(4):
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://dogfood-output/pack-studio"))
	_save("res://dogfood-output/pack-studio/select.png")
	var select := root_scene.find_child("CharacterSelect", true, false)
	assert(select != null, "character select should boot")
	var import_btn := select.find_child("ImportButton", true, false) as Button
	assert(import_btn != null and import_btn.visible, "desktop select shows 导入")
	if root_scene.has_method("toggle_pack_studio"):
		root_scene.call("toggle_pack_studio")
	for _j in range(6):
		await process_frame
	var studio := root_scene.find_child("PackStudio", true, false)
	assert(studio != null and studio.visible, "F1/导入 opens pack studio")
	_save("res://dogfood-output/pack-studio/studio.png")
	var list := studio.find_child("PackList", true, false) as ItemList
	if list != null and list.item_count > 0:
		var frost := 0
		for i in range(list.item_count):
			if String(list.get_item_text(i)).contains("frost") or String(list.get_item_text(i)).contains("霜"):
				frost = i
				break
		list.select(frost)
		list.item_selected.emit(frost)
		for _k in range(4):
			await process_frame
		_save("res://dogfood-output/pack-studio/frost-pack.png")
	print("CAPTURE pack studio ok")
	quit()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("CAPTURE skip: no viewport texture for %s" % path)
		return
	image.save_png(path)
	print("CAPTURE %s" % path)

extends SceneTree

## Snapshot the boot character-select screen for visual QA.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://dogfood-output/character-select"))
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("CAPTURE skip: no viewport texture")
		quit()
		return
	image.save_png("res://dogfood-output/character-select/boot.png")
	var select := root_scene.find_child("CharacterSelect", true, false)
	if select != null and select.has_method("_on_skin"):
		select.call("select_hero", &"ember_hero")
		await process_frame
		select.call("_on_skin")
		await process_frame
		var picker_img := root.get_viewport().get_texture().get_image()
		if picker_img != null:
			picker_img.save_png("res://dogfood-output/character-select/skin-picker.png")
		if select.has_method("_pick_skin"):
			select.call("_pick_skin", &"frost_warrior")
			await process_frame
			var frost_img := root.get_viewport().get_texture().get_image()
			if frost_img != null:
				frost_img.save_png("res://dogfood-output/character-select/knight-frost.png")
	print("CAPTURE ok")
	quit()

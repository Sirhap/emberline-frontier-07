extends SceneTree

const OUT := "res://dogfood-output/frost-armed-visual"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var hub := load("res://scenes/home/home_hub.tscn").instantiate() as Node2D
	root.add_child(hub)
	await process_frame
	await process_frame
	var walker := hub.find_child("HomeWalker", true, false) as EmberHero
	if walker == null:
		print("HOME_WALKER missing")
		quit(1)
		return
	walker.hub_hide_weapon = true
	walker.apply_hero_kind(&"ember_hero", &"frost_armed")
	walker.position = Vector2(280, 559)
	walker.call("_apply_facing", 1)
	walker.call("_apply_view_from_move", Vector2(1.0, 0.0))
	await process_frame
	_save("10-home-side")
	walker.call("_apply_view_from_move", Vector2(0.0, 1.0))
	await process_frame
	_save("11-home-front")
	walker.call("_apply_view_from_move", Vector2(0.0, -1.0))
	await process_frame
	_save("12-home-back")
	print("HOME_ARMED pack=%s view=%s clip=%s" % [
		String(walker.visual_pack_id),
		str(walker.get("_view")),
		walker._clip_name(&"idle"),
	])
	quit()


func _save(name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png("%s/%s.png" % [OUT, name])
	print("SAVED %s err=%s" % [name, err])

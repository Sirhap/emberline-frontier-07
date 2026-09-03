extends SceneTree

const OUT_DIR := "/tmp/ember-home-walker"


func _init() -> void:
	create_timer(12.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var hub := load("res://scenes/home/home_hub.tscn").instantiate() as Node2D
	root.add_child(hub)
	await _settle()
	var walker := hub.find_child("HomeWalker", true, false) as EmberHero
	if walker == null:
		push_error("HomeWalker missing")
		quit(1)
		return
	# Stand on the same foot line as 牛来.
	walker.position = Vector2(280, 559)
	await _settle()
	if not _save("walker-vs-bull.png"):
		return
	print("HOME WALKER CAPTURE PASS")
	quit()


func _settle() -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	await process_frame


func _save(file_name: String) -> bool:
	var image := root.get_viewport().get_texture().get_image()
	var path := "%s/%s" % [OUT_DIR, file_name]
	if image.save_png(path) != OK:
		push_error("Could not save %s" % path)
		quit(1)
		return false
	print("WROTE ", path)
	return true

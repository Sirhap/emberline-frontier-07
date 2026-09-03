extends SceneTree

const OUT_DIR := "/tmp/ember-home-lighting"


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


## Captures the night endpoint, transition midpoint, and daylight endpoint.
func _run() -> void:
	var make_error := DirAccess.make_dir_recursive_absolute(OUT_DIR)
	if make_error != OK:
		push_error("Could not create lighting capture directory: %s" % error_string(make_error))
		quit(1)
		return
	var hub := load("res://scenes/home/home_hub.tscn").instantiate() as Node2D
	if hub == null:
		push_error("Could not instantiate the home hub")
		quit(1)
		return
	root.add_child(hub)
	await _settle()
	var room := hub.find_child("HomeRoom", true, false) as HomeRoom
	if room == null:
		push_error("HomeRoom was not built")
		quit(1)
		return
	if not _save("home-night.png"):
		return
	if not room.toggle_daylight():
		push_error("Daylight transition did not start")
		quit(1)
		return
	await create_timer(HomeRoom.LIGHT_TRANSITION_DURATION * 0.5).timeout
	await _settle()
	if not _save("home-transition.png"):
		return
	await create_timer(HomeRoom.LIGHT_TRANSITION_DURATION * 0.6).timeout
	await _settle()
	if not room.is_daylight():
		push_error("Daylight transition did not finish")
		quit(1)
		return
	if not _save("home-day.png"):
		return
	if not room.toggle_daylight():
		push_error("Night transition did not start")
		quit(1)
		return
	await create_timer(HomeRoom.LIGHT_TRANSITION_DURATION * 0.5).timeout
	await _settle()
	if not _save("home-transition-night.png"):
		return
	await create_timer(HomeRoom.LIGHT_TRANSITION_DURATION * 0.6).timeout
	await _settle()
	if room.is_daylight():
		push_error("Night transition did not finish")
		quit(1)
		return
	print("HOME LIGHTING CAPTURE PASS")
	quit()


func _settle() -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	await process_frame


func _save(file_name: String) -> bool:
	var image := root.get_viewport().get_texture().get_image()
	var path := "%s/%s" % [OUT_DIR, file_name]
	var save_error := image.save_png(path)
	if save_error != OK:
		push_error("Could not save %s: %s" % [path, error_string(save_error)])
		quit(1)
		return false
	print("SAVED %s" % path)
	return true

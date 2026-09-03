extends SceneTree

const EmberHero := preload("res://scripts/hero.gd")
const OUT_DIR := "/tmp/ember-home-airwalls"


func _init() -> void:
	create_timer(20.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var hub := load("res://scenes/home/home_hub.tscn").instantiate() as Node2D
	root.add_child(hub)
	await _settle()
	var room := hub.find_child("HomeRoom", true, false) as HomeRoom
	var walker := hub.find_child("HomeWalker", true, false) as EmberHero
	if room == null or walker == null:
		push_error("HomeRoom or HomeWalker missing")
		quit(1)
		return
	var skate := room.air_wall_named("Skateboard")
	var desk := room.air_wall_named("CoderDesk")
	if skate.is_empty() or desk.is_empty():
		push_error("Air walls were not stamped")
		quit(1)
		return
	var skate_rect: Rect2 = skate.get("rect", Rect2())
	var desk_rect: Rect2 = desk.get("rect", Rect2())
	_draw_debug(room, [skate_rect, desk_rect])

	var skate_in := skate_rect.get_center()
	var skate_from := Vector2(skate_rect.position.x - 18.0, skate_in.y)
	walker.position = skate_from
	await _settle()
	if not _save("air-skate-approach.png"):
		return
	for _i: int in range(10):
		walker.move_in_direction(skate_in - walker.position, 0.08)
	await _settle()
	var blocked := not skate_rect.has_point(walker.position)
	if not _save("air-skate-blocked.png"):
		return

	walker.position = skate_from
	walker.request_jump()
	var vaulted := false
	for _tick: int in range(36):
		await process_frame
		if walker.air_clearance() >= float(skate.get("height", 10.0)):
			walker.move_in_direction(skate_in - walker.position, 0.05)
		if skate_rect.has_point(walker.position):
			vaulted = true
			break
	await _settle()
	if not _save("air-skate-jump.png"):
		return
	for _land: int in range(24):
		await process_frame
		if walker.air_clearance() <= 0.01:
			break

	var desk_in := desk_rect.get_center()
	var desk_from := Vector2(desk_rect.position.x - 20.0, desk_in.y)
	walker.position = desk_from
	walker.request_jump()
	var desk_crossed := false
	for _tick: int in range(36):
		await process_frame
		if walker.air_clearance() >= 20.0:
			walker.move_in_direction(desk_in - walker.position, 0.05)
		if desk_rect.has_point(walker.position):
			desk_crossed = true
			break
	await _settle()
	if not _save("air-desk-jump.png"):
		return

	if not blocked:
		push_error("Skateboard did not block a grounded walk")
		quit(1)
		return
	if not vaulted:
		push_error("Jump did not clear the skateboard")
		quit(1)
		return
	if desk_crossed:
		push_error("Jump cleared the desk, which is taller than JUMP_HEIGHT")
		quit(1)
		return
	print("HOME AIRWALL CAPTURE PASS")
	quit()


func _draw_debug(room: HomeRoom, rects: Array[Rect2]) -> void:
	for i: int in range(rects.size()):
		var box := ColorRect.new()
		box.name = "AirDebug%d" % i
		box.position = rects[i].position
		box.size = rects[i].size
		box.color = Color(1.0, 0.2, 0.2, 0.28)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.z_index = 8
		room.add_child(box)


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
	print("WROTE ", path)
	return true

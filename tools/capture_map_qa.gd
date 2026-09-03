extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	var hud: CanvasLayer = scene.get("_hud") as CanvasLayer
	if hud != null:
		hud.visible = false
	hero.visible = false

	var mouth_mid := 1280.0 / 1536.0 * 4.0 + 26.5 * (1280.0 / 1536.0 * 64.0)
	var east_join := 1280.0 / 1536.0 * 4.0 + 33.0 * (1280.0 / 1536.0 * 64.0)
	var spots: Array = [
		["map-field", Vector2(640.0, 336.0)],
		["map-south-overlay", Vector2(720.0, 540.0)],
		["map-south-wall", Vector2(720.0, 620.0)],
		["map-east-paint-edge", Vector2(1016.0, 336.0)],
		["map-east-expand", Vector2(1480.0, 336.0)],
		["map-east-road", Vector2(east_join + 140.0, 336.0)],
		["map-east-portal", Vector2(2100.0, 336.0)],
		["map-shop-door", Vector2(568.0, 40.0)],
		["map-shop-inside", Vector2(560.0, -120.0)],
		["map-hall", Vector2(40.0, 336.0)],
		["map-north-mouth", Vector2(mouth_mid, 80.0)],
		["map-north-road", Vector2(mouth_mid, -200.0)],
		["map-north-portal", Vector2(mouth_mid, -480.0)],
		["map-south-mouth", Vector2(mouth_mid, 640.0)],
		["map-south-road", Vector2(mouth_mid, 1100.0)],
		["map-south-portal", Vector2(mouth_mid, 1320.0)],
	]
	for spot: Array in spots:
		hero.position = spot[1]
		_snap(cam, spot[1])
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		await process_frame
		_save("res://tools/look-qa-%s.png" % String(spot[0]))

	print("MAP_QA ok")
	quit()


func _snap(cam: Camera2D, world: Vector2) -> void:
	if cam == null:
		return
	cam.zoom = Vector2.ONE
	cam.global_position = world
	cam.reset_smoothing()
	cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

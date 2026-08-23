extends SceneTree

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.position = Vector2(420.0, 336.0)
	scene.queue_redraw()
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png("res://tools/look-core.png")
	print("CORE_CAPTURE err=%s glow=%s" % [err, str(scene.get("CORE_GLOW"))])
	quit()

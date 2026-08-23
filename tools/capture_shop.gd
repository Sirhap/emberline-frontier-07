extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	var image := root.get_viewport().get_texture().get_image()
	var path := "res://tools/shop_shot.png"
	var err := image.save_png(path)
	print("SHOP_SHOT %s err=%s size=%sx%s" % [path, err, image.get_width(), image.get_height()])
	quit()

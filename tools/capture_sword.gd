extends SceneTree

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.position = Vector2(640.0, 336.0)
	await process_frame
	_save("res://tools/look-sword-idle.png")
	hero.request_attack()
	await create_timer(0.22).timeout
	_save("res://tools/look-sword-attack.png")
	hero.position = Vector2(640.0, 336.0)
	hero.move_in_direction(Vector2.LEFT, 0.02)
	await process_frame
	_save("res://tools/look-sword-left.png")
	print("SWORD_CAPTURE weapon=%s visible=%s" % [String(hero.current_weapon), str((hero.find_child("HeldWeapon", true, false) as Sprite2D).visible)])
	quit()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

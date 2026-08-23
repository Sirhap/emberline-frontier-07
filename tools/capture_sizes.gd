extends SceneTree

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var actor: Node = scene.get_node("HeroSlot/HeroController/XSXBHeroActor")
	hero.position = Vector2(640.0, 336.0)
	hero.set_demo_state(&"idle")
	await create_timer(0.12).timeout
	_dump(actor, "idle")
	_save("res://tools/look-idle.png")
	hero.set_demo_state(&"run")
	await create_timer(0.20).timeout
	_dump(actor, "run")
	_save("res://tools/look-run.png")
	hero.request_jump()
	await create_timer(0.02).timeout
	_dump(actor, "jump-stand")
	_save("res://tools/look-jump-stand.png")
	await create_timer(0.16).timeout
	_dump(actor, "jump-apex")
	_save("res://tools/look-jump.png")
	await create_timer(0.50).timeout
	hero.request_attack()
	await create_timer(0.12).timeout
	_dump(actor, "attack")
	_save("res://tools/look-attack1.png")
	print("SIZE_CAPTURE done")
	quit()


func _dump(actor: Node, label: String) -> void:
	var owner := actor.get_node_or_null("VisualOwner") as Node2D
	var sprite := actor.get_node_or_null("VisualOwner/FrameSprite") as Sprite2D
	var scale_txt := "?"
	var tex_txt := "?"
	if owner != null:
		scale_txt = str(owner.scale)
	if sprite != null and sprite.texture != null:
		tex_txt = "%sx%s" % [sprite.texture.get_width(), sprite.texture.get_height()]
	print("STATE %s scale=%s tex=%s anim=%s" % [label, scale_txt, tex_txt, actor.get("frame_animation")])


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

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
	hero.health = 999
	hero.max_health = 999
	var kinds: Array[StringName] = [&"scout", &"brute", &"mage", &"runner", &"boss"]
	var spawned: Array[FrontierEnemy] = []
	var x := 520.0
	for kind: StringName in kinds:
		var enemy := FrontierEnemy.new()
		enemy.variant = kind
		enemy.max_health = 9999
		enemy.move_speed = 0.0
		enemy.contact_damage = 0
		enemy.configure_seek(Vector2(x, 336.0), Vector2(154.0, 336.0), scene)
		scene.call("_register_enemy", enemy)
		spawned.append(enemy)
		x += 110.0
	await process_frame
	await create_timer(0.16).timeout
	_save("res://tools/look-enemy-idle.png")
	for enemy: FrontierEnemy in spawned:
		enemy.play_attack(Vector2.LEFT)
	await create_timer(0.22).timeout
	_save("res://tools/look-enemy-attack.png")
	await create_timer(0.42).timeout
	_save("res://tools/look-enemy-recover.png")
	print("ENEMY_ATTACK_CAPTURE done")
	quit()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

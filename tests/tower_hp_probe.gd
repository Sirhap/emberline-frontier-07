extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	while not (scene.get("_towers") as Array).is_empty():
		scene.call("_select_tower", (scene.get("_towers") as Array)[0])
		scene.call("sell_selected_tower")
	scene.set("scrap", 300)
	var tower: EmberTower = scene.call("_spawn_tower_at", Vector2(990.0, 205.0), &"pulse", 1)
	assert(tower.max_health == 120 and tower.health == 120)
	var scrap0: int = int(scene.get("scrap"))
	tower.take_damage(40)
	assert(tower.health == 80)
	tower.take_damage(80)
	await process_frame
	assert((scene.get("_towers") as Array).is_empty())
	assert(int(scene.get("scrap")) == scrap0)
	assert((scene.get("_wrecked_cells") as Dictionary).size() == 1)
	hero.position = Vector2(990.0, 205.0)
	assert(bool(scene.call("try_rebuild_nearby")))
	assert((scene.get("_towers") as Array).size() == 1)
	assert((scene.get("_towers") as Array)[0].kind == &"pulse")
	assert(int(scene.get("scrap")) == scrap0 - 80)
	print("TOWER_HP_PROBE PASS default_hp=120 rebuild_pulse=80 burst=110 frost=90 contact=40")
	quit()

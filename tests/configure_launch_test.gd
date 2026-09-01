extends SceneTree

const EmberRunSave := preload("res://scripts/run_save.gd")
const EmberHero := preload("res://scripts/hero.gd")
const CharacterProgression := preload("res://scripts/character_progression.gd")


func _init() -> void:
	create_timer(45.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	var knight: Node = load("res://main.tscn").instantiate()
	root.add_child(knight)
	await process_frame
	var knight_hero: EmberHero = knight.get("_hero")
	assert(knight_hero != null, "direct main.tscn still boots a hero")
	assert(knight_hero.hero_kind == &"ember_hero", "smoke/direct boot is knight")
	assert(knight_hero.max_health == 120, "knight lv1 max HP is 120")
	assert(knight_hero.armor_max >= 2, "knight lv1 armor capacity is 2")
	var knight_prog: CharacterProgression = knight.get("_progression")
	assert(knight_prog != null, "direct boot still creates CharacterProgression")
	assert(knight_prog.hero_id() == &"ember_hero", "direct boot progression is knight")
	assert(knight_prog.level() == 1, "new run starts lv1")
	knight.queue_free()
	await process_frame

	var launched: Node = load("res://main.tscn").instantiate()
	launched.call("configure_launch", {
		"hero_id": &"assassin",
		"mode_id": &"endless_td",
		"run_seed": 7,
	})
	root.add_child(launched)
	await process_frame
	var assassin: EmberHero = launched.get("_hero")
	assert(assassin.hero_kind == &"assassin", "configure_launch before add_child selects assassin")
	assert(assassin.max_health == 105, "assassin lv1 max HP is 105")
	var prog: CharacterProgression = launched.get("_progression")
	assert(prog.hero_id() == &"assassin")
	assert(prog.level() == 1)
	launched.queue_free()
	await process_frame
	EmberRunSave.delete_run()

	print("CONFIGURE LAUNCH PASS")
	quit()

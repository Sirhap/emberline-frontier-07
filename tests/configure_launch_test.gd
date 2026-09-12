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
	var finished: Array = []
	launched.connect("run_finished", func(result: Dictionary) -> void:
		finished.append(result)
	)
	launched.call("_end_run", &"core")
	await process_frame
	assert(finished.is_empty(), "configure_launch defeat must show settlement before run_finished")
	var overlay := launched.find_child("EndOverlay", true, false) as Control
	assert(overlay != null and overlay.visible, "launched defeat shows EndOverlay")
	var restart := launched.find_child("RestartButton", true, false) as Button
	assert(restart != null and restart.text == "返回家园", "AppRoot launch uses 返回家园")
	restart.pressed.emit()
	await process_frame
	assert(finished.size() == 1, "settlement confirm emits run_finished")
	assert(String(finished[0].get("reason", "")) == "core", "core loss reason is preserved")
	launched.queue_free()
	await process_frame

	var hero_loss: Node = load("res://main.tscn").instantiate()
	hero_loss.call("configure_launch", {
		"hero_id": &"ember_hero",
		"mode_id": &"endless_td",
		"run_seed": 9,
	})
	root.add_child(hero_loss)
	await process_frame
	var hero_finished: Array = []
	hero_loss.connect("run_finished", func(result: Dictionary) -> void:
		hero_finished.append(result)
	)
	hero_loss.call("notify_hero_defeated")
	await process_frame
	assert(hero_finished.is_empty(), "hero death waits on settlement before run_finished")
	var hero_overlay := hero_loss.find_child("EndOverlay", true, false) as Control
	assert(hero_overlay != null and hero_overlay.visible, "downs-exhausted shows EndOverlay")
	var hero_title := hero_loss.find_child("OverlayTitle", true, false) as Label
	assert(hero_title != null and hero_title.text == "英雄阵亡", "hero death settlement title is 英雄阵亡")
	var hero_restart := hero_loss.find_child("RestartButton", true, false) as Button
	assert(hero_restart != null and hero_restart.text == "返回家园", "launched hero death uses 返回家园")
	hero_restart.pressed.emit()
	await process_frame
	assert(hero_finished.size() == 1, "hero death confirm emits run_finished")
	assert(String(hero_finished[0].get("reason", "")) == "hero", "hero death reason is preserved")
	hero_loss.queue_free()
	await process_frame
	EmberRunSave.delete_run()

	print("CONFIGURE LAUNCH PASS")
	quit()

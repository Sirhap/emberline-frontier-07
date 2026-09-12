extends SceneTree

const EmberRunSave := preload("res://scripts/run_save.gd")
const EmberHero := preload("res://scripts/hero.gd")
const CharacterProgression := preload("res://scripts/character_progression.gd")
const TalentChoiceOverlay := preload("res://scripts/talent_choice_overlay.gd")


func _init() -> void:
	create_timer(50.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	var seed := _seed_offering(&"field_medic")
	assert(seed > 0, "need a run seed whose first three-card set includes field_medic")

	var scene: Node = load("res://main.tscn").instantiate()
	scene.call("configure_launch", {
		"hero_id": &"ember_hero",
		"mode_id": &"endless_td",
		"run_seed": seed,
	})
	root.add_child(scene)
	await process_frame
	await process_frame

	var hero: EmberHero = scene.get("_hero")
	var prog: CharacterProgression = scene.get("_progression")
	var overlay: TalentChoiceOverlay = scene.find_child("TalentChoiceOverlay", true, false)
	assert(hero != null and prog != null and overlay != null, "battle boots hero, progression, and talent overlay")
	assert(prog.level() == 1, "new run starts lv1")
	assert(hero.max_health == 120, "knight lv1 max HP is 120")
	var hp_lv1: int = hero.health

	for _i: int in range(8):
		_kill_scout(scene)
	assert(prog.level() == 2, "8 scout kills (40 XP) must level to 2")
	assert(int(prog.snapshot()["pending_choices"]) == 1, "level-up owes one three-card pick")
	assert(overlay.visible, "level-up must show the talent overlay")
	var choices: Array = prog.open_choices()
	assert(choices.size() == 3, "overlay offers three cards")
	var medic_index := _index_of(choices, &"field_medic")
	assert(medic_index >= 0, "seed %d must offer field_medic so wave-clear heal is non-zero" % seed)

	var before_max: int = hero.max_health
	overlay.choose_index(medic_index)
	assert(not overlay.visible, "picking a card hides the overlay")
	assert(int(prog.talent_counts().get(&"field_medic", 0)) == 1, "chosen talent must land on progression")
	assert(is_equal_approx(prog.current_stats().wave_heal_ratio, 0.08), "field_medic must apply 8% wave heal")
	assert(hero.max_health == before_max or hero.max_health == 130, "level stats stay applied after the pick")
	assert(hero.max_health >= hp_lv1, "kill→level path must raise or keep max HP")

	hero.health = 20
	var expected_heal: int = int(prog.apply_wave_clear().get("heal", 0))
	assert(expected_heal > 0, "field_medic wave-clear heal must be non-zero")
	scene.call("_finish_wave")
	assert(hero.health == 20 + expected_heal, "wave-clear must heal the hero through apply_wave_clear (want %d, got %d)" % [20 + expected_heal, hero.health])

	scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()
	print("RUN LOOP PROGRESSION PASS")
	quit()


func _kill_scout(scene: Node) -> void:
	var enemy := FrontierEnemy.new()
	enemy.variant = &"scout"
	enemy.rank = &"normal"
	enemy.max_health = 1
	enemy.move_speed = 0.0
	enemy.configure_seek(Vector2(640.0, 336.0), scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", enemy)
	enemy.take_damage(99, &"hero")


func _index_of(choices: Array, talent_id: StringName) -> int:
	for index: int in range(choices.size()):
		var card: Variant = choices[index]
		if card is Dictionary and StringName(str((card as Dictionary).get("id", &""))) == talent_id:
			return index
	return -1


func _seed_offering(talent_id: StringName) -> int:
	for seed: int in range(1, 400):
		var probe := CharacterProgression.new()
		probe.start(&"ember_hero", seed)
		for _i: int in range(8):
			probe.award_kill(&"scout", &"normal")
		if _index_of(probe.open_choices(), talent_id) >= 0:
			return seed
	return 0

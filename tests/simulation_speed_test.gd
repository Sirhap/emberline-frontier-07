extends SceneTree

const EmberRunSave := preload("res://scripts/run_save.gd")
const EmberHero := preload("res://scripts/hero.gd")

const MOVE_WAIT := 0.45
const PREP_WAIT := 1.0
const WALK_START := Vector2(720.0, 400.0)
const HERO_AWAY := Vector2(220.0, 200.0)


func _init() -> void:
	create_timer(45.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var director: WaveDirector = scene.get("_director")
	var hero: EmberHero = scene.get("_hero")
	assert(hero != null and director != null and director.is_prep(), "fresh battle starts in PREP")
	hero.position = HERO_AWAY
	await create_timer(0.35).timeout

	scene.set("simulation_speed", 2.0)
	var prep_before: float = director.prep_left
	await create_timer(PREP_WAIT).timeout
	assert(director.is_prep(), "1s wall clock must stay inside the 50s prep")
	var prep_drop: float = prep_before - director.prep_left
	assert(prep_drop > 0.70 and prep_drop < 1.35, "2× must not speed prep countdown (dropped %.3f over %.1fs wall, want ~1.0)" % [prep_drop, PREP_WAIT])

	var move_1: float = await _walk_probe(scene, hero, 1.0)
	var move_2: float = await _walk_probe(scene, hero, 2.0)
	assert(move_1 > 8.0, "1× enemy should walk a measurable distance, got %.2f" % move_1)
	assert(absf(move_2 - move_1) < maxf(6.0, move_1 * 0.18), "2× must not speed enemy movement (1×=%.2f 2×=%.2f)" % [move_1, move_2])

	var interval_1: float = await _spawn_gap(scene, 1.0)
	var interval_2: float = await _spawn_gap(scene, 2.0)
	assert(interval_1 > 0.55, "1× spawn gap should be the wave-1 interval (~0.86s), got %.3f" % interval_1)
	assert(interval_2 > 0.20, "2× spawn gap should still be a real wait, got %.3f" % interval_2)
	var ratio := interval_2 / interval_1
	assert(ratio > 0.35 and ratio < 0.65, "2× must halve spawn interval vs 1× (2×=%.3f 1×=%.3f ratio=%.3f)" % [interval_2, interval_1, ratio])

	scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()
	print("SIMULATION SPEED PASS")
	quit()


func _walk_probe(scene: Node, hero: EmberHero, speed: float) -> float:
	scene.set("simulation_speed", speed)
	hero.position = HERO_AWAY
	var enemy := FrontierEnemy.new()
	enemy.variant = &"scout"
	enemy.rank = &"normal"
	enemy.max_health = 9999
	enemy.move_speed = 80.0
	enemy.configure_seek(WALK_START, scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", enemy)
	await process_frame
	enemy.global_position = WALK_START
	enemy.move_speed = 80.0
	enemy.set("_aggro", false)
	var start: Vector2 = enemy.global_position
	await create_timer(MOVE_WAIT).timeout
	var traveled: float = start.distance_to(enemy.global_position)
	enemy.move_speed = 0.0
	if is_instance_valid(enemy):
		enemy.queue_free()
		(scene.get("_enemies") as Array).erase(enemy)
	await process_frame
	return traveled


func _spawn_gap(scene: Node, speed: float) -> float:
	scene.set("simulation_speed", speed)
	if not bool(scene.get("_wave_active")):
		scene.call("start_wave")
		assert(bool(scene.get("_wave_active")), "start_wave must enter combat")
	var before: int = (scene.get("_enemies") as Array).size()
	assert(await _wait_enemy_count(scene, before + 1, 3.5), "need one new spawn before measuring the gap at %.1f×" % speed)
	var t0 := Time.get_ticks_usec()
	assert(await _wait_enemy_count(scene, before + 2, 3.5), "need a following spawn so the %.1f× interval can be measured" % speed)
	return float(Time.get_ticks_usec() - t0) / 1_000_000.0


func _wait_enemy_count(scene: Node, want: int, timeout: float) -> bool:
	var waited := 0.0
	while waited < timeout:
		if (scene.get("_enemies") as Array).size() >= want:
			return true
		await create_timer(0.02).timeout
		waited += 0.02
	return false

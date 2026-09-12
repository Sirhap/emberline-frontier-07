extends SceneTree

const EmberRunSave := preload("res://scripts/run_save.gd")
const EmberHero := preload("res://scripts/hero.gd")

const MOVE_WAIT := 0.45
const PREP_WAIT := 1.0


func _init() -> void:
	create_timer(60.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()

	var one_x: Dictionary = await _measure_speed(1.0)
	var two_x: Dictionary = await _measure_speed(2.0)

	var interval_1: float = float(one_x["spawn_interval"])
	var interval_2: float = float(two_x["spawn_interval"])
	assert(interval_1 > 0.55, "1× spawn gap should be the wave-1 interval (~0.86s), got %.3f" % interval_1)
	assert(interval_2 > 0.20, "2× spawn gap should still be a real wait, got %.3f" % interval_2)
	var ratio := interval_2 / interval_1
	assert(ratio > 0.35 and ratio < 0.65, "2× must halve spawn interval vs 1× (2×=%.3f 1×=%.3f ratio=%.3f)" % [interval_2, interval_1, ratio])

	var move_1: float = float(one_x["move_distance"])
	var move_2: float = float(two_x["move_distance"])
	assert(move_1 > 8.0, "1× enemy should walk a measurable distance, got %.2f" % move_1)
	assert(absf(move_2 - move_1) < maxf(6.0, move_1 * 0.18), "2× must not speed enemy movement (1×=%.2f 2×=%.2f)" % [move_1, move_2])

	var prep_drop: float = float(two_x["prep_drop"])
	assert(prep_drop > 0.70 and prep_drop < 1.35, "2× must not speed prep countdown (dropped %.3f over %.1fs wall, want ~1.0)" % [prep_drop, PREP_WAIT])

	EmberRunSave.delete_run()
	print("SIMULATION SPEED PASS")
	quit()


func _measure_speed(speed: float) -> Dictionary:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.set("simulation_speed", speed)
	var director: WaveDirector = scene.get("_director")
	var hero: EmberHero = scene.get("_hero")
	assert(hero != null and director != null, "battle scene must boot a hero and director")
	hero.position = Vector2(220.0, 200.0)
	hero.set("move_speed", 0.0)

	var prep_drop := 0.0
	if is_equal_approx(speed, 2.0):
		assert(director.is_prep(), "fresh run starts in PREP")
		var prep_before: float = director.prep_left
		await create_timer(PREP_WAIT).timeout
		assert(director.is_prep(), "1s wall clock must stay in the 50s prep")
		prep_drop = prep_before - director.prep_left

	var move_distance := await _walk_probe(scene, hero)
	var spawn_interval := await _spawn_gap(scene)

	scene.queue_free()
	await process_frame
	return {
		"spawn_interval": spawn_interval,
		"move_distance": move_distance,
		"prep_drop": prep_drop,
	}


func _walk_probe(scene: Node, hero: EmberHero) -> float:
	var enemy := FrontierEnemy.new()
	enemy.variant = &"scout"
	enemy.rank = &"normal"
	enemy.max_health = 9999
	enemy.move_speed = 80.0
	enemy.configure_seek(Vector2(720.0, 400.0), scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", enemy)
	await process_frame
	enemy.move_speed = 80.0
	enemy.set("_aggro", false)
	hero.position = Vector2(220.0, 200.0)
	var start: Vector2 = enemy.global_position
	await create_timer(MOVE_WAIT).timeout
	var traveled: float = start.distance_to(enemy.global_position)
	enemy.move_speed = 0.0
	return traveled


func _spawn_gap(scene: Node) -> float:
	var before: int = (scene.get("_enemies") as Array).size()
	scene.call("start_wave")
	assert(bool(scene.get("_wave_active")), "start_wave must enter combat")
	assert(await _wait_enemy_count(scene, before + 1, 2.5), "wave should spawn the first enemy")
	var t0 := Time.get_ticks_usec()
	assert(await _wait_enemy_count(scene, before + 2, 3.5), "wave should spawn a second enemy so the interval can be measured")
	return float(Time.get_ticks_usec() - t0) / 1_000_000.0


func _wait_enemy_count(scene: Node, want: int, timeout: float) -> bool:
	var waited := 0.0
	while waited < timeout:
		if (scene.get("_enemies") as Array).size() >= want:
			return true
		await create_timer(0.02).timeout
		waited += 0.02
	return false

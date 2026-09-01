extends SceneTree

const EmberHero := preload("res://scripts/hero.gd")


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	var absorbed: Dictionary = EmberHero.resolve_hit(8, 2, 2)
	assert(int(absorbed["hp_lost"]) == 0, "armor fully absorbs 8 dmg")
	assert(int(absorbed["armor"]) == 1, "one armor charge spent")
	assert(int(absorbed["armor_spent"]) == 1)
	assert(bool(absorbed["absorbed"]), "8 vs armor is fully absorbed")

	var leftover: Dictionary = EmberHero.resolve_hit(10, 2, 2)
	assert(int(leftover["hp_lost"]) == 1, "10-8 armor then defense 2 still min 1 HP")
	assert(int(leftover["armor"]) == 1)
	assert(not bool(leftover["absorbed"]))

	var unarmored: Dictionary = EmberHero.resolve_hit(10, 0, 2)
	assert(int(unarmored["hp_lost"]) == 8, "10 minus defense 2 is 8")
	assert(int(unarmored["armor_spent"]) == 0)

	var chip: Dictionary = EmberHero.resolve_hit(5, 0, 20)
	assert(int(chip["hp_lost"]) == 1, "raw>0 and not absorbed floors to 1 HP")

	var zero: Dictionary = EmberHero.resolve_hit(0, 2, 2)
	assert(int(zero["hp_lost"]) == 0, "zero raw deals no HP")
	assert(int(zero["armor_spent"]) == 0, "zero raw does not spend armor")

	var big: Dictionary = EmberHero.resolve_hit(20, 1, 2)
	assert(int(big["hp_lost"]) == 10, "20-8 armor then -2 defense is 10")

	assert(EmberHero.scale_damage(100, 100, 1.0, 1.0, 1.0, 1.0) == 100, "identity scale")
	assert(EmberHero.scale_damage(100, 102, 1.0, 1.0, 1.0, 1.0) == 102, "attack_power 102")
	assert(EmberHero.scale_damage(46, 100, 1.12, 1.08, 1.10, 1.0) == 61, "forge*all*melee rounds")
	assert(EmberHero.scale_damage(1, 100, 0.01, 0.01, 0.01, 0.01) == 1, "scaled damage never 0")

	print("HERO COMBAT FORMULA PASS")
	quit()

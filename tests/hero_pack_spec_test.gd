extends SceneTree

const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")


func _init() -> void:
	create_timer(20.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	assert(HeroPackSpec.clip_name("idle", "ember_hero", "side_flip", "front") == "idle", "side_flip ignores view")
	assert(HeroPackSpec.clip_name("run", "ember_hero", "three", "front") == "run_front", "knight three-view run")
	assert(HeroPackSpec.clip_name("run", "assassin", "three", "back") == "walk_back", "assassin run aliases then view")
	assert(HeroPackSpec.clip_name("dash", "assassin", "side_flip", "side") == "skill_cast", "assassin dash aliases")
	assert(HeroPackSpec.view_from_move(Vector2.ZERO) == &"", "still keeps previous")
	assert(HeroPackSpec.view_from_move(Vector2(1.0, 0.2)) == &"side", "horizontal wins")
	assert(HeroPackSpec.view_from_move(Vector2(0.0, 1.0)) == &"front", "south is front")
	assert(HeroPackSpec.view_from_move(Vector2(0.0, -1.0)) == &"back", "north is back")
	var knight: PackedStringArray = HeroPackSpec.required_slots("ember_hero")
	assert(knight.has("idle") and knight.has("dash") and not knight.has("walk"), "knight slots")
	assert(HeroPackSpec.template_for("ember_hero").get("optional", []).has("skill_cast"), "knight may ship a skill_cast clip")
	var assassin: PackedStringArray = HeroPackSpec.required_slots("assassin")
	assert(assassin.has("walk") and assassin.has("skill_bubble") and assassin.has("attack_b"), "assassin slots")
	assert(HeroPackSpec.is_builtin_side_flip("ember_hero"))
	assert(HeroPackSpec.is_builtin_side_flip("assassin"))
	assert(not HeroPackSpec.is_builtin_side_flip("knight_gold"))
	print("HERO PACK SPEC PASS")
	quit()

extends SceneTree

const Hero := preload("res://scripts/hero.gd")
var _failures: Array[String] = []
var _missing: Array[String] = []
var _require_directions := false


## Default checks fallback; --require-directions makes missing directional clips fatal.
func _init() -> void:
	_require_directions = "--require-directions" in OS.get_cmdline_user_args()
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


## Check the actual actor, including initial playback and loaded frame texture.
func _expect_clip(hero: EmberHero, clip: String) -> void:
	var actor := hero.get_node("XSXBHeroActor")
	var animations: Dictionary = actor.get("_animations")
	var expected := clip
	if clip.ends_with("_front") or clip.ends_with("_back"):
		if (animations.get(clip, {}) as Dictionary).get("frames", []).is_empty():
			var missing := "%s/%s" % [hero.hero_id, clip]
			if not _missing.has(missing):
				_missing.append(missing)
			if not _require_directions:
				expected = clip.get_slice("_", 0)
	_check(str(actor.get("_current_animation")) == expected, "%s expected %s, playing %s" % [hero.hero_id, expected, actor.get("_current_animation")])
	clip = expected
	_check(not (animations.get(clip, {}) as Dictionary).get("frames", []).is_empty(), "%s missing frames: %s" % [hero.hero_id, clip])
	var sprite := actor.get_node("VisualOwner/FrameSprite") as Sprite2D
	_check(sprite.texture != null, "%s has no real body texture" % hero.hero_id)


## Collect failures so both heroes and all directions are reported in one run.
func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		printerr("DIRECTION FAIL: ", message)


## Exercise public movement/jump entry points with deterministic animation time.
func _run() -> void:
	var hero := Hero.new()
	hero.hub_hide_weapon = true
	root.add_child(hero)
	for identity: StringName in [&"ember_hero", &"assassin", &"ember_hero"]:
		hero.apply_hero_kind(identity)
		_check(hero.hero_id == identity, "Character switch must commit immediately")
		var actor := hero.get_node("XSXBHeroActor")
		actor.set_process(false)
		_check(not str(actor.get("_current_animation")).is_empty(), "%s initial animation must be nonempty" % identity)
		_expect_clip(hero, hero._clip_name(&"idle"))
		_check(hero.get("_view_mode") == "three", "%s needs three-view catalog" % identity)
		for direction: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
			var view := "front" if direction == Vector2.DOWN else "back" if direction == Vector2.UP else "side"
			var suffix := "" if view == "side" else "_" + view
			hero.move_in_direction(direction, 0.01)
			hero._update_animation_state()
			_expect_clip(hero, "run" + suffix)
			hero.move_in_direction(Vector2.ZERO, 0.0)
			hero._update_animation_state()
			_check(str(hero.get("_view")) == view, "Stopping must preserve " + view)
			_expect_clip(hero, "idle" + suffix)
			var expected_facing := -1 if direction == Vector2.LEFT else 1
			_check(int(actor.get("facing")) == expected_facing, "Side flips; front/back remain unmirrored")
			hero.request_jump()
			_expect_clip(hero, "jump" + suffix)
			var duration := float(hero.call("_animation_duration", StringName(hero._clip_name(&"jump")), Hero.JUMP_DURATION))
			# The existing lift uses air=(progress-.12)/.72; apex is progress .48.
			hero.call("_update_jump", duration * 0.48)
			_check(is_equal_approx(hero.air_clearance(), 32.0), "%s/%s jump apex must be 32px" % [identity, view])
			_expect_clip(hero, "jump" + suffix)
			hero.call("_update_jump", duration)
			hero._update_animation_state()
			_check(is_zero_approx(hero.air_clearance()), "Landing must reset lift")
			_expect_clip(hero, "idle" + suffix)
		hero.hub_hide_weapon = false
		for direction: Vector2 in [Vector2.UP, Vector2.DOWN]:
			hero.move_in_direction(direction, 0.0)
			hero._update_animation_state()
			_check(hero.get("_view") == &"side", "Battlefield must lock side view")
			_expect_clip(hero, "run")
		hero.move_in_direction(Vector2.ZERO, 0.0)
		hero._update_animation_state()
		hero.hub_hide_weapon = true
	hero.free()
	await process_frame
	if not _missing.is_empty():
		printerr("DIRECTIONS INCOMPLETE: ", ", ".join(_missing))
	if _failures.is_empty():
		print("HERO DIRECTION PASS: ", "complete directional wiring" if _require_directions else "side/initialization/fallback only; not full directional or visual approval")
	else:
		printerr("HERO DIRECTION FAILED: %d checks; directional assets/runtime must be completed" % _failures.size())
	quit(0 if _failures.is_empty() else 1)

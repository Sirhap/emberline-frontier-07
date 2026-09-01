extends SceneTree

const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")
const EnemyCatalog := preload("res://scripts/enemy_catalog.gd")
const TalentCatalog := preload("res://scripts/talent_catalog.gd")
const HeroStats := preload("res://scripts/hero_stats.gd")
const CharacterProgression := preload("res://scripts/character_progression.gd")


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	assert(HeroDefinitionCatalog.has_id(&"ember_hero"))
	assert(EnemyCatalog.experience_for(&"scout", &"normal") == 5)

	var knight := CharacterProgression.new()
	var knight_bag := _bind(knight)
	knight.start(&"ember_hero", 12345)
	_kill_scouts(knight, 8)
	var knight_choices: Array = knight_bag["choices"]
	assert(knight_choices.size() == 3, "first level-up rolls 3 cards")
	assert(int(knight_bag["pending"]) == 1, "one level leaves pending 1")
	_assert_three_unique_categories(knight_choices)
	_assert_no_prefix(knight_choices, "shadow_")

	var assassin := CharacterProgression.new()
	var assassin_bag := _bind(assassin)
	assassin.start(&"assassin", 99)
	_kill_scouts(assassin, 8)
	assert(assassin_bag["choices"].size() == 3, "assassin also rolls 3 cards")
	_assert_three_unique_categories(assassin_bag["choices"])
	_assert_no_prefix(assassin_bag["choices"], "knight_")

	var a := CharacterProgression.new()
	var a_bag := _bind(a)
	a.start(&"ember_hero", 12345)
	_kill_scouts(a, 8)
	var b := CharacterProgression.new()
	var b_bag := _bind(b)
	b.start(&"ember_hero", 12345)
	_kill_scouts(b, 8)
	assert(_choice_ids(a_bag["choices"]) == _choice_ids(b_bag["choices"]), "same seed + same kills → same three ids")

	var chosen_id: StringName = knight_choices[0]["id"]
	var refuse: Dictionary = knight.choose_talent(&"not_a_card")
	assert(refuse["ok"] == false, "id not in the open set is rejected")
	assert(int(refuse["pending_choices"]) == 1, "failed choose does not spend pending")

	var picked: Dictionary = knight.choose_talent(chosen_id)
	assert(picked["ok"] == true, "open card can be chosen")
	assert(int(picked["pending_choices"]) == 0, "single pending drops to 0")
	var after: Dictionary = knight.snapshot()
	assert(int(after["pending_choices"]) == 0)
	assert(int(after["talent_counts"][String(chosen_id)]) == 1, "chosen talent count increments")
	var second: Dictionary = knight.choose_talent(chosen_id)
	assert(second["ok"] == false, "cleared open set rejects another choose")

	var stacked := CharacterProgression.new()
	var stacked_bag := _bind(stacked)
	stacked.start(&"ember_hero", 42, {"level": 1, "xp": 0, "talent_counts": {"force_training": 3}})
	_kill_scouts(stacked, 8)
	assert(stacked_bag["choices"].size() == 3, "capped force_training still rolls 3 cards")
	for card: Variant in stacked_bag["choices"]:
		assert((card as Dictionary)["id"] != &"force_training", "force_training at 3 stacks is not offered")

	var hist_a := CharacterProgression.new()
	var hist_a_bag := _bind(hist_a)
	hist_a.start(&"ember_hero", 12345)
	_kill_scouts(hist_a, 40)
	assert(int(hist_a.snapshot()["pending_choices"]) == 3)
	var first_ids: Array = _choice_ids(hist_a_bag["choices"])
	var first_pick: StringName = hist_a_bag["choices"][0]["id"]
	hist_a.choose_talent(first_pick)
	var hist_a_second: Array = _choice_ids(hist_a_bag["choices"])
	assert(hist_a_second.size() == 3, "remaining pending rolls a new three-card set")
	assert(int(hist_a.snapshot()["pending_choices"]) == 2)

	var hist_b := CharacterProgression.new()
	var hist_b_bag := _bind(hist_b)
	hist_b.start(&"ember_hero", 12345)
	_kill_scouts(hist_b, 40)
	assert(_choice_ids(hist_b_bag["choices"]) == first_ids, "same seed repeats the first set")
	hist_b.choose_talent(first_pick)
	assert(_choice_ids(hist_b_bag["choices"]) == hist_a_second, "same choose history → same next cards")

	print("TALENT CHOICE PASS")
	quit()


func _bind(prog: CharacterProgression) -> Dictionary:
	var bag := {"choices": [], "pending": 0, "stats": null}
	prog.choices_ready.connect(func(choices: Array, pending_count: int) -> void:
		bag["choices"] = choices.duplicate(true)
		bag["pending"] = pending_count
	)
	prog.stats_changed.connect(func(stats: HeroStats) -> void:
		bag["stats"] = stats
	)
	return bag


func _kill_scouts(prog: CharacterProgression, n: int) -> void:
	for _i in n:
		prog.award_kill(&"scout", &"normal")


func _choice_ids(choices: Array) -> Array:
	var ids: Array = []
	for card: Variant in choices:
		ids.append((card as Dictionary)["id"])
	return ids


func _assert_three_unique_categories(choices: Array) -> void:
	var seen := {}
	var ids := {}
	for card: Variant in choices:
		var def: Dictionary = card
		var talent_id: StringName = def["id"]
		var category: StringName = def["category"]
		assert(not ids.has(talent_id), "choice ids must be unique")
		ids[talent_id] = true
		assert(not seen.has(category), "choice categories must be unique")
		seen[category] = true
		assert(TalentCatalog.has_id(talent_id), "rolled id must exist")
		assert(TalentCatalog.get_def(talent_id)["category"] == category)
	assert(seen.has(&"offense") and seen.has(&"defense") and seen.has(&"utility"), "one offense, one defense, one utility")


func _assert_no_prefix(choices: Array, prefix: String) -> void:
	for card: Variant in choices:
		var talent_id := String((card as Dictionary)["id"])
		assert(not talent_id.begins_with(prefix), "choice %s should not start with %s" % [talent_id, prefix])

extends SceneTree

const EXPECTED_IDS: Array[StringName] = [
	&"force_training",
	&"rapid_trigger",
	&"blade_training",
	&"tempered_body",
	&"composite_armor",
	&"defensive_posture",
	&"swift_step",
	&"energy_loop",
	&"field_medic",
	&"scavenger",
	&"knight_counterfire",
	&"knight_overdrive",
	&"knight_dash_guard",
	&"shadow_edge",
	&"shadow_duration",
	&"shadow_haste",
]


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void:
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	for talent_id: StringName in EXPECTED_IDS:
		assert(TalentCatalog.has_id(talent_id), "listed id must exist: %s" % String(talent_id))
		var def: Dictionary = TalentCatalog.get_def(talent_id)
		assert(not def.is_empty(), "get_def must return a definition for %s" % String(talent_id))
		assert(def["id"] == talent_id, "def id must match key for %s" % String(talent_id))
		assert(def.has("title") and String(def["title"]).length() > 0, "title required for %s" % String(talent_id))
		assert(def.has("description") and String(def["description"]).length() > 0, "description required for %s" % String(talent_id))
		var category: StringName = def["category"]
		assert(category == &"offense" or category == &"defense" or category == &"utility", "category must be offense/defense/utility for %s" % String(talent_id))
		assert(def.has("hero_ids"), "hero_ids required for %s" % String(talent_id))
		assert(int(def["max_stacks"]) >= 1, "max_stacks must be >= 1 for %s" % String(talent_id))
		var icon := String(def["icon"])
		var expected_icon := "res://assets/generated/ui/talents/%s.png" % String(talent_id).replace("_", "-")
		assert(icon == expected_icon, "icon path mismatch for %s: %s" % [String(talent_id), icon])

	var all: Array[StringName] = TalentCatalog.all_ids()
	assert(all.size() == EXPECTED_IDS.size(), "all_ids size must match listed talents")
	for talent_id: StringName in EXPECTED_IDS:
		assert(all.has(talent_id), "all_ids must include %s" % String(talent_id))

	var assassin_offense: Array[StringName] = _pool_ids(TalentCatalog.pool_for(&"assassin", &"offense", {}))
	assert(not assassin_offense.has(&"knight_overdrive"), "assassin offense pool must not include knight_overdrive")
	assert(assassin_offense.has(&"shadow_edge"), "assassin offense pool must include shadow_edge")
	assert(assassin_offense.has(&"force_training"), "assassin offense pool must include common force_training")

	var knight_ids: Array[StringName] = TalentCatalog.ids_for_hero(&"ember_hero")
	assert(not knight_ids.has(&"shadow_edge"), "knight pool must not include shadow_edge")
	assert(knight_ids.has(&"knight_overdrive"), "knight pool must include knight_overdrive")
	assert(knight_ids.has(&"force_training"), "knight pool must include common talents")

	var assassin_ids: Array[StringName] = TalentCatalog.ids_for_hero(&"assassin")
	assert(assassin_ids.has(&"shadow_edge"), "assassin ids must include shadow_edge")
	assert(not assassin_ids.has(&"knight_counterfire"), "assassin ids must not include knight exclusives")

	var stacked: Array[StringName] = _pool_ids(TalentCatalog.pool_for(&"ember_hero", &"offense", {&"force_training": 3}))
	assert(not stacked.has(&"force_training"), "force_training must be excluded at max stacks")
	assert(stacked.has(&"rapid_trigger"), "other offense talents remain when force_training is capped")

	var assassin_utility: Array[StringName] = _pool_ids(TalentCatalog.pool_for(&"assassin", &"utility", {}))
	assert(assassin_utility.has(&"shadow_duration"), "assassin utility pool must include shadow_duration")
	assert(not assassin_utility.has(&"knight_dash_guard"), "assassin utility pool must not include knight_dash_guard")
	assert(assassin_utility.has(&"swift_step"), "assassin utility pool must include common utility")

	var unknown: Dictionary = TalentCatalog.get_def(&"not_a_talent")
	assert(unknown.is_empty(), "get_def unknown is empty")
	assert(not TalentCatalog.has_id(&"not_a_talent"), "has_id unknown is false")

	var common: Dictionary = TalentCatalog.get_def(&"force_training")
	assert(TalentCatalog.is_hero_allowed(common, &"assassin"), "empty hero_ids allows assassin")
	assert(TalentCatalog.is_hero_allowed(common, &"ember_hero"), "empty hero_ids allows knight")
	var knight_only: Dictionary = TalentCatalog.get_def(&"knight_overdrive")
	assert(TalentCatalog.is_hero_allowed(knight_only, &"ember_hero"), "knight exclusive allows ember_hero")
	assert(not TalentCatalog.is_hero_allowed(knight_only, &"assassin"), "knight exclusive rejects assassin")

	print("TALENT CATALOG PASS")
	quit()


func _pool_ids(pool: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for item: Variant in pool:
		ids.append((item as Dictionary)["id"] as StringName)
	return ids

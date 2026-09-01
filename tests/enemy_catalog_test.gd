extends SceneTree

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")

## Headless checks for EnemyCatalog XP, codex ids, and unknown fallbacks.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))

	var ids: Array[StringName] = EnemyCatalog.all_ids()
	assert(ids.size() == 6, "Codex should list six enemy ids")
	for expected: StringName in [&"scout", &"runner", &"brute", &"mage", &"elite_brute", &"boss"]:
		assert(ids.has(expected), "all_ids should include %s" % String(expected))
		assert(EnemyCatalog.has_id(expected), "has_id should accept %s" % String(expected))

	assert(EnemyCatalog.experience_for(&"scout", &"") == 5)
	assert(EnemyCatalog.experience_for(&"scout", &"normal") == 5)
	assert(EnemyCatalog.experience_for(&"scout", &"elite") == 5)
	assert(EnemyCatalog.experience_for(&"runner", &"") == 6)
	assert(EnemyCatalog.experience_for(&"runner", &"normal") == 6)
	assert(EnemyCatalog.experience_for(&"mage", &"") == 8)
	assert(EnemyCatalog.experience_for(&"mage", &"elite") == 8)
	assert(EnemyCatalog.experience_for(&"brute", &"elite") == 25)
	assert(EnemyCatalog.experience_for(&"brute", &"normal") == 10)
	assert(EnemyCatalog.experience_for(&"brute", &"") == 10)
	assert(EnemyCatalog.experience_for(&"boss", &"") == 60)
	assert(EnemyCatalog.experience_for(&"boss", &"boss") == 60)
	assert(EnemyCatalog.experience_for(&"scout", &"boss") == 60)
	assert(EnemyCatalog.experience_for(&"elite_brute", &"") == 25)
	assert(EnemyCatalog.experience_for(&"", &"") == 0)
	assert(EnemyCatalog.experience_for(&"unknown", &"") == 0)
	assert(EnemyCatalog.experience_for(&"ghost", &"elite") == 0)

	assert(EnemyCatalog.codex_id(&"brute", &"elite") == &"elite_brute")
	assert(EnemyCatalog.codex_id(&"brute", &"normal") == &"brute")
	assert(EnemyCatalog.codex_id(&"brute", &"") == &"brute")
	assert(EnemyCatalog.codex_id(&"scout", &"elite") == &"scout")
	assert(EnemyCatalog.codex_id(&"scout", &"") == &"scout")
	assert(EnemyCatalog.codex_id(&"runner", &"") == &"runner")
	assert(EnemyCatalog.codex_id(&"mage", &"") == &"mage")
	assert(EnemyCatalog.codex_id(&"boss", &"boss") == &"boss")
	assert(EnemyCatalog.codex_id(&"elite_brute", &"") == &"elite_brute")
	assert(EnemyCatalog.codex_id(&"nope", &"") == &"")
	assert(EnemyCatalog.codex_id(&"nope", &"elite") == &"")

	assert(not EnemyCatalog.has_id(&"unknown"))
	assert(EnemyCatalog.get_def(&"unknown").is_empty())
	var elite: Dictionary = EnemyCatalog.get_def(&"elite_brute")
	assert(elite["id"] == &"elite_brute")
	assert(String(elite["icon"]).ends_with("brute.png"))
	assert((elite["tags"] as Array).has(&"elite"))

	print("ENEMY CATALOG PASS")
	quit()

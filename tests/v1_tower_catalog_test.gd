extends SceneTree

const EmberShop := preload("res://scripts/shop.gd")
const EmberTower := preload("res://scripts/tower.gd")
const EmberRunSave := preload("res://scripts/run_save.gd")


func _init() -> void:
	create_timer(20.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	assert(not EmberShop.PLAYER_STOCK_KINDS.has(&"burst"), "burst is not a v1 player stock kind")
	assert(EmberShop.is_player_stock_kind(&"pulse"), "pulse is v1 stock")
	assert(EmberShop.is_player_stock_kind(&"frost"), "frost is v1 stock")
	assert(EmberShop.is_player_stock_kind(&"hologram"), "hologram is v1 stock")
	assert(not EmberShop.is_player_stock_kind(&"burst"), "burst is leftover, not player stock")
	assert(EmberRunSave.is_valid_tower_kind(&"burst"), "old saves may still restore burst")
	assert(EmberTower.build_cost(&"burst") == 110, "legacy burst cost stays 110")

	var shop := EmberShop.new()
	shop.rng.seed = 1
	shop.refresh(1, &"sword", 0, &"ember_hero", 0)
	_assert_no_burst(shop, "wave 1 merchant stock")
	var wave1: Array[StringName] = _tower_payloads(shop)
	assert(wave1.has(&"pulse") and wave1.has(&"hologram") and wave1.has(&"frost"), "wave 1 is pulse / hologram / frost")

	for wave: int in range(2, 24):
		shop.rng.seed = wave * 17
		shop.refresh(wave, &"sword", 0, &"ember_hero", 0)
		_assert_no_burst(shop, "wave %d merchant stock" % wave)

	var leftover: Dictionary = shop._restock_merchant_slot(&"burst", 4)
	assert(StringName(str(leftover.get("payload", &""))) == &"pulse", "restocking leftover burst must fall back to pulse")
	assert(StringName(str(leftover.get("kind", &""))) == &"tower", "restock still sells a tower")

	print("V1 TOWER CATALOG PASS")
	quit()


func _assert_no_burst(shop: EmberShop, where: String) -> void:
	for slot: Dictionary in shop.slots:
		var payload := StringName(str(slot.get("payload", &"")))
		assert(payload != &"burst", "%s must not offer burst" % where)
		assert(String(slot.get("title", "")).find("爆裂") < 0, "%s must not title a burst tower" % where)


func _tower_payloads(shop: EmberShop) -> Array[StringName]:
	var out: Array[StringName] = []
	for slot: Dictionary in shop.slots:
		if StringName(str(slot.get("kind", &""))) == &"tower":
			out.append(StringName(str(slot.get("payload", &""))))
	return out

extends SceneTree

const EmberShop := preload("res://scripts/shop.gd")


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	var shop := EmberShop.new()
	shop.refresh(1, &"sword", 0, &"ember_hero", 0)
	assert(not _has_kind(shop, &"vitality"), "wave 1 must not stock vitality")
	assert(_has_kind(shop, &"forge"), "wave 1 keeps forge")
	assert(_has_kind(shop, &"skill"), "wave 1 keeps skill")
	assert(_has_kind(shop, &"mech_repair"), "wave 1 keeps mechanic")
	assert(_has_kind(shop, &"summon"), "wave 1 keeps summoner")
	assert(shop.slots.size() == 7, "wave 1 is 3 merchant + forge/skill/mech/summon")

	shop.refresh(2, &"sword", 0, &"ember_hero", 0)
	assert(not _has_kind(shop, &"vitality"), "wave 2 must not stock vitality")
	assert(shop.slots.size() == 7, "wave 2 is 3 merchant + forge/skill/mech/summon")

	shop.refresh(3, &"sword", 0, &"ember_hero", 0)
	assert(not _has_kind(shop, &"vitality"), "wave 3 must not stock vitality")
	assert(_has_kind(shop, &"half_price"), "wave 3 offers half-price")
	assert(shop.slots.size() == 8, "wave 3 adds half-price, still no vitality")

	shop.sync_trainer(&"sword", 0, &"ember_hero", 0, 2)
	assert(not _has_kind(shop, &"vitality"), "sync_trainer must not reinsert vitality")

	print("SHOP NO VITALITY PASS")
	quit()


func _has_kind(shop: EmberShop, kind: StringName) -> bool:
	for slot: Dictionary in shop.slots:
		if slot.get("kind", &"") == kind:
			return true
	return false

class_name EmberShop
extends RefCounted

signal changed
signal status_text(message: String)

const FORGE_CAP := 5
const SKILL_CAP_KNIGHT := 2
const SKILL_CAP_ASSASSIN := 3

var slots: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var is_open := false
var stock_wave := 1


func _init() -> void:
	rng.randomize()


func scaled_price(base: int, wave: int) -> int:
	return int(floor(float(base) * (1.0 + 0.08 * float(maxi(wave, 1) - 1))))


func close_and_refund() -> int:
	is_open = false
	changed.emit()
	return 0


func refresh(
	wave: int,
	weapon_id: StringName = &"sword",
	forge_level: int = 0,
	hero_kind: StringName = &"ember_hero",
	skill_level: int = 0
) -> int:
	stock_wave = maxi(wave, 1)
	is_open = true
	slots.clear()
	var tower_kinds: Array[StringName] = [&"pulse", &"burst", &"frost"]
	if stock_wave <= 1:
		slots.append(_tower_slot(&"pulse", stock_wave))
		slots.append(_tower_slot(&"burst", stock_wave))
		slots.append(_tower_slot(&"frost", stock_wave))
	else:
		for _i: int in range(3):
			slots.append(_tower_slot(tower_kinds[rng.randi() % tower_kinds.size()], stock_wave))
	slots.append(_forge_slot(weapon_id, forge_level, stock_wave))
	slots.append(_skill_slot(hero_kind, skill_level, stock_wave))
	changed.emit()
	return 0


func sync_trainer(
	weapon_id: StringName,
	forge_level: int,
	hero_kind: StringName,
	skill_level: int,
	wave: int = -1
) -> void:
	if wave > 0:
		stock_wave = wave
	var forge_index := _first_kind_index(&"forge")
	var skill_index := _first_kind_index(&"skill")
	var forge_slot := _forge_slot(weapon_id, forge_level, stock_wave)
	var skill_slot := _skill_slot(hero_kind, skill_level, stock_wave)
	if forge_index >= 0:
		slots[forge_index] = forge_slot
	else:
		slots.append(forge_slot)
	if skill_index >= 0:
		slots[skill_index] = skill_slot
	else:
		slots.append(skill_slot)


func buy(
	index: int,
	scrap: int,
	forge_level: int = 0,
	skill_level: int = 0,
	hero_kind: StringName = &"ember_hero"
) -> Dictionary:
	var result := {
		"ok": false,
		"cost": 0,
		"kind": &"",
		"payload": &"",
		"message": "商店未开放",
	}
	if not is_open or index < 0 or index >= slots.size():
		return result
	var slot: Dictionary = slots[index]
	var cost := int(slot.get("cost", 0))
	var kind: StringName = slot["kind"]
	if kind == &"forge" and forge_level >= FORGE_CAP:
		result["message"] = "这把武器已经锻满"
		return result
	if kind == &"skill" and skill_level >= _skill_cap(hero_kind):
		result["message"] = "这项技能已经满级"
		return result
	if scrap < cost:
		result["message"] = "资源不足  /  需要 %d 废料" % cost
		return result
	result["ok"] = true
	result["cost"] = cost
	result["kind"] = kind
	result["payload"] = slot["payload"]
	result["message"] = String(slot.get("bought_text", "已购买"))
	if kind == &"tower" or kind == &"weapon":
		slots[index] = _restock_merchant_slot(StringName(slot.get("payload", &"")), stock_wave)
	changed.emit()
	return result


func restore_slots(next_slots: Array) -> void:
	slots.clear()
	for item in next_slots:
		if item is Dictionary:
			slots.append((item as Dictionary).duplicate(true))
	is_open = true
	changed.emit()


func _first_kind_index(kind: StringName) -> int:
	for index: int in range(slots.size()):
		if StringName(slots[index].get("kind", &"")) == kind:
			return index
	return -1


func _skill_cap(hero_kind: StringName) -> int:
	return SKILL_CAP_ASSASSIN if hero_kind == &"assassin" else SKILL_CAP_KNIGHT


func _with_vendor(slot: Dictionary, vendor: StringName) -> Dictionary:
	slot["vendor"] = vendor
	slot["sold"] = false
	return slot


func _tower_slot(kind: StringName, wave: int) -> Dictionary:
	var base := EmberTower.build_cost(kind)
	return _with_vendor({
		"kind": &"tower",
		"payload": kind,
		"title": EmberTower.kind_display_name(kind, 1),
		"detail": "买入后用手持炮台点地砖放下",
		"cost": scaled_price(base, wave),
		"bought_text": "%s已购入  /  切到炮台再点地放下" % EmberTower.kind_display_name(kind, 1),
		"icon": _tower_icon(kind),
	}, &"merchant")


func _weapon_slot(weapon_id: StringName, wave: int) -> Dictionary:
	var weapon := WeaponCatalog.get_def(weapon_id)
	var base := int(weapon.get("shop_cost", 60))
	return _with_vendor({
		"kind": &"weapon",
		"payload": weapon_id,
		"title": String(weapon["display_name"]),
		"detail": "买入后进入英雄武器槽",
		"cost": scaled_price(base, wave),
		"bought_text": "%s已装备" % String(weapon["display_name"]),
		"icon": String(weapon.get("pickup_path", "")),
	}, &"merchant")


func _random_merchant_slot(wave: int) -> Dictionary:
	var tower_kinds: Array[StringName] = [&"pulse", &"burst", &"frost"]
	return _tower_slot(tower_kinds[rng.randi() % tower_kinds.size()], wave)


func _restock_merchant_slot(kind: StringName, wave: int) -> Dictionary:
	# 有货补啥货：买走哪座炮台，柜上就补同一座。
	if kind == &"pulse" or kind == &"burst" or kind == &"frost":
		return _tower_slot(kind, wave)
	return _tower_slot(&"pulse", wave)


func _forge_slot(weapon_id: StringName, current_level: int, wave: int) -> Dictionary:
	var weapon := WeaponCatalog.get_def(weapon_id if weapon_id != &"" else &"sword")
	var next_level := mini(current_level + 1, FORGE_CAP)
	var at_cap := current_level >= FORGE_CAP
	var title := "锻造 满级" if at_cap else "锻造"
	return _with_vendor({
		"kind": &"forge",
		"payload": weapon_id,
		"title": title,
		"detail": "%s 攻击 +10%%，最多 5 级" % String(weapon.get("display_name", "武器")),
		"cost": scaled_price(180, wave),
		"bought_text": "%s锻造至 %d 级" % [String(weapon.get("display_name", "武器")), next_level],
		"icon": "res://assets/generated/ui/shop-forge.png",
	}, &"trainer")


func _skill_slot(hero_kind: StringName, current_level: int, wave: int) -> Dictionary:
	var cap := _skill_cap(hero_kind)
	var at_cap := current_level >= cap
	var title := "技能 满级" if at_cap else "技能提升"
	var detail := "提升当前英雄技能"
	var bought := "技能已满级" if at_cap else "技能已提升"
	return _with_vendor({
		"kind": &"skill",
		"payload": hero_kind,
		"title": title,
		"detail": detail,
		"cost": scaled_price(80, wave),
		"bought_text": bought,
		"icon": "res://assets/generated/ui/shop-dualwield.png",
	}, &"trainer")


func _tower_icon(kind: StringName) -> String:
	if kind == &"burst":
		return "res://assets/generated/towers/burst-lv1.png"
	if kind == &"frost":
		return "res://assets/generated/towers/frost-lv1.png"
	return "res://assets/generated/towers/tower-lv1.png"

class_name EmberShop
extends RefCounted

signal changed
signal status_text(message: String)

var slots: Array[Dictionary] = []
var held_kind: StringName = &""
var held_refund := 0
var rng := RandomNumberGenerator.new()
var is_open := false


func _init() -> void:
	rng.randomize()


func scaled_price(base: int, wave: int) -> int:
	return int(floor(float(base) * (1.0 + 0.08 * float(maxi(wave, 1) - 1))))


func refund_held() -> int:
	var amount := held_refund
	held_kind = &""
	held_refund = 0
	return amount


func close_and_refund() -> int:
	is_open = false
	var amount := refund_held()
	changed.emit()
	return amount


func refresh(
	wave: int,
	has_dash: bool,
	core_health: int,
	core_max: int,
	attack_level: int = 0,
	vitality_level: int = 0,
	dash_cd_level: int = 0
) -> int:
	var refund := refund_held()
	is_open = true
	slots.clear()
	if wave <= 1:
		slots.append(_tower_slot(&"pulse", wave))
		slots.append(_weapon_slot(&"pistol", wave))
		slots.append(_skill_or_heal_slot(false, wave))
		slots.append(_tower_slot(&"frost", wave))
	else:
		var tower_kinds: Array[StringName] = [&"pulse", &"burst", &"frost"]
		slots.append(_tower_slot(tower_kinds[rng.randi() % tower_kinds.size()], wave))
		slots.append(_weapon_slot(WeaponCatalog.random_basic_weapon(rng), wave))
		slots.append(_skill_or_heal_slot(has_dash, wave))
		if core_health < core_max:
			slots.append(_repair_slot(wave))
		else:
			slots.append(_scrap_slot())
	if has_dash:
		_append_trainer_upgrades(wave, attack_level, vitality_level, dash_cd_level)
	changed.emit()
	return refund


func offer_trainer_upgrades(wave: int, attack_level: int, vitality_level: int, dash_cd_level: int) -> void:
	if _append_trainer_upgrades(wave, attack_level, vitality_level, dash_cd_level):
		changed.emit()


func buy(index: int, scrap: int, has_dash: bool, core_health: int, core_max: int) -> Dictionary:
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
	if slot.get("sold", false):
		result["message"] = "这一格已经买过了"
		return result
	var cost := int(slot.get("cost", 0))
	if scrap < cost:
		result["message"] = "资源不足  /  需要 %d 废料" % cost
		return result
	var kind: StringName = slot["kind"]
	if (kind == &"tower" or kind == &"weapon") and held_kind != &"":
		result["message"] = "先放下手里的塔或武器，或等准备结束退款"
		return result
	if kind == &"repair" and core_health >= core_max:
		result["message"] = "核心已经满员"
		return result
	if kind == &"skill" and has_dash:
		result["message"] = "冲刺已经解锁"
		return result
	slot["sold"] = true
	slots[index] = slot
	if kind == &"tower" or kind == &"weapon":
		held_kind = slot["payload"]
		held_refund = cost
	result["ok"] = true
	result["cost"] = cost
	result["kind"] = kind
	result["payload"] = slot["payload"]
	result["message"] = String(slot.get("bought_text", "已购买"))
	changed.emit()
	return result


func mark_tower_placed() -> void:
	held_kind = &""
	held_refund = 0
	changed.emit()


func restore_slots(next_slots: Array) -> void:
	slots.clear()
	for item in next_slots:
		if item is Dictionary:
			slots.append((item as Dictionary).duplicate(true))
	held_kind = &""
	held_refund = 0
	is_open = true
	changed.emit()


func _append_trainer_upgrades(wave: int, attack_level: int, vitality_level: int, dash_cd_level: int) -> bool:
	var added := 0
	var changed_slots := false
	if attack_level < 3 and not _has_upgrade(&"attack") and added < 2:
		slots.append(_upgrade_slot(&"attack", wave, attack_level))
		added += 1
		changed_slots = true
	if vitality_level < 3 and not _has_upgrade(&"vitality") and added < 2:
		slots.append(_upgrade_slot(&"vitality", wave, vitality_level))
		added += 1
		changed_slots = true
	if dash_cd_level < 2 and not _has_upgrade(&"dash_cd") and added < 2:
		slots.append(_upgrade_slot(&"dash_cd", wave, dash_cd_level))
		changed_slots = true
	return changed_slots


func _has_upgrade(payload: StringName) -> bool:
	for slot: Dictionary in slots:
		if slot.get("kind", &"") == &"upgrade" and slot.get("payload", &"") == payload:
			return true
	return false


func _with_vendor(slot: Dictionary, vendor: StringName) -> Dictionary:
	slot["vendor"] = vendor
	return slot


func _tower_slot(kind: StringName, wave: int) -> Dictionary:
	var base := EmberTower.build_cost(kind)
	return _with_vendor({
		"kind": &"tower",
		"payload": kind,
		"title": EmberTower.kind_display_name(kind, 1),
		"detail": "点选后再点地面放下",
		"cost": scaled_price(base, wave),
		"sold": false,
		"bought_text": "%s已购入  /  点击地面放下" % EmberTower.kind_display_name(kind, 1),
		"icon": _tower_icon(kind),
	}, &"merchant")


func _weapon_slot(weapon_id: StringName, wave: int) -> Dictionary:
	var weapon := WeaponCatalog.get_def(weapon_id)
	var base := int(weapon.get("shop_cost", 60))
	return _with_vendor({
		"kind": &"weapon",
		"payload": weapon_id,
		"title": String(weapon["display_name"]),
		"detail": "点选后再点地砖放下，自动开火",
		"cost": scaled_price(base, wave),
		"sold": false,
		"bought_text": "%s已购入  /  点击地砖放下" % String(weapon["display_name"]),
		"icon": String(weapon.get("pickup_path", "")),
	}, &"merchant")


func _skill_or_heal_slot(has_dash: bool, wave: int) -> Dictionary:
	if not has_dash:
		return _with_vendor({
			"kind": &"skill",
			"payload": &"dash",
			"title": "冲刺",
			"detail": "短位移并短暂无敌",
			"cost": scaled_price(80, wave),
			"sold": false,
			"bought_text": "冲刺已解锁  /  空格使用",
			"icon": "res://assets/generated/npc/trainer.png",
		}, &"trainer")
	return _with_vendor({
		"kind": &"heal",
		"payload": &"heal",
		"title": "战地包扎",
		"detail": "立刻恢复英雄 40% 生命",
		"cost": scaled_price(50, wave),
		"sold": false,
		"bought_text": "英雄恢复了 40% 生命",
		"icon": "res://assets/generated/pickups/dash.png",
	}, &"trainer")


func _upgrade_slot(payload: StringName, wave: int, current_level: int) -> Dictionary:
	var next_level := current_level + 1
	if payload == &"attack":
		return _with_vendor({
			"kind": &"upgrade",
			"payload": &"attack",
			"title": "锐击 %d" % next_level,
			"detail": "近战伤害 +8，最多 3 级",
			"cost": scaled_price(70, wave),
			"sold": false,
			"bought_text": "近战伤害提升至 %d" % (46 + next_level * 8),
			"icon": "res://assets/generated/npc/trainer.png",
		}, &"trainer")
	if payload == &"vitality":
		return _with_vendor({
			"kind": &"upgrade",
			"payload": &"vitality",
			"title": "体魄 %d" % next_level,
			"detail": "最大生命 +20，并立刻补等量生命",
			"cost": scaled_price(70, wave),
			"sold": false,
			"bought_text": "最大生命 +20",
			"icon": "res://assets/generated/npc/trainer.png",
		}, &"trainer")
	return _with_vendor({
		"kind": &"upgrade",
		"payload": &"dash_cd",
		"title": "迅步 %d" % next_level,
		"detail": "缩短冲刺冷却",
		"cost": scaled_price(80, wave),
		"sold": false,
		"bought_text": "冲刺冷却缩短了",
		"icon": "res://assets/generated/npc/trainer.png",
	}, &"trainer")


func _repair_slot(wave: int) -> Dictionary:
	return _with_vendor({
		"kind": &"repair",
		"payload": &"core",
		"title": "核心维修",
		"detail": "核心生命 +1，上限 10",
		"cost": scaled_price(100, wave),
		"sold": false,
		"bought_text": "核心完整度 +1",
		"icon": "res://assets/generated/base/core.png",
	}, &"merchant")


## Builds the free full-core fallback offered from wave 2 onward.
func _scrap_slot() -> Dictionary:
	return _with_vendor({
		"kind": &"scrap",
		"payload": &"scrap",
		"title": "应急废料",
		"detail": "点击领取 +40 废料",
		"cost": 0,
		"sold": false,
		"bought_text": "获得 40 废料",
		"icon": "res://assets/generated/ui/scrap.png",
	}, &"merchant")


func _tower_icon(kind: StringName) -> String:
	if kind == &"burst":
		return "res://assets/generated/towers/burst-lv1.png"
	if kind == &"frost":
		return "res://assets/generated/towers/frost-lv1.png"
	return "res://assets/generated/towers/tower-lv1.png"

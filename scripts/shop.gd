class_name EmberShop
extends RefCounted

signal changed
signal status_text(message: String)

const FORGE_CAP := 5
const SKILL_CAP_KNIGHT := 2
const SKILL_CAP_ASSASSIN := 3
const VITALITY_CAP := 9
const FACILITY_KINDS: Array[StringName] = [&"barrier", &"amplifier", &"pulse_clear", &"energy_orb"]
const COMBAT_KINDS: Array[StringName] = [&"pulse", &"frost"]

var slots: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var is_open := false
var stock_wave := 1
var price_mult := 1.0
var half_price_owned := false
var vitality_level := 0
var mech_level := 0


func _init() -> void:
	rng.randomize()


func scaled_price(base: int, wave: int) -> int:
	var raw := float(base) * (1.0 + 0.08 * float(maxi(wave, 1) - 1)) * price_mult
	return maxi(1, int(floor(raw)))


func close_and_refund() -> int:
	is_open = false
	changed.emit()
	return 0


func apply_half_price() -> bool:
	if half_price_owned:
		return false
	half_price_owned = true
	price_mult = 0.5
	changed.emit()
	return true


func refresh(
	wave: int,
	weapon_id: StringName = &"sword",
	forge_level: int = 0,
	hero_kind: StringName = &"ember_hero",
	skill_level: int = 0,
	vitality: int = -1,
	mech: int = -1,
	pack_id: StringName = &""
) -> int:
	stock_wave = maxi(wave, 1)
	if vitality >= 0:
		vitality_level = vitality
	if mech >= 0:
		mech_level = mech
	is_open = true
	slots.clear()
	if stock_wave <= 1:
		slots.append(_tower_slot(&"pulse", stock_wave))
		slots.append(_tower_slot(&"hologram", stock_wave))
		slots.append(_tower_slot(&"frost", stock_wave))
	else:
		for _i: int in range(3):
			slots.append(_random_merchant_slot(stock_wave))
	slots.append(_forge_slot(weapon_id, forge_level, stock_wave))
	slots.append(_skill_slot(hero_kind, skill_level, stock_wave, pack_id))
	slots.append(_mech_repair_slot(mech_level, stock_wave))
	slots.append(_summon_slot(stock_wave))
	if stock_wave >= 3 and not half_price_owned:
		slots.append(_half_price_slot(stock_wave))
	changed.emit()
	return 0


func sync_trainer(
	weapon_id: StringName,
	forge_level: int,
	hero_kind: StringName,
	skill_level: int,
	wave: int = -1,
	vitality: int = -1,
	mech: int = -1,
	pack_id: StringName = &""
) -> void:
	if wave > 0:
		stock_wave = wave
	if vitality >= 0:
		vitality_level = vitality
	if mech >= 0:
		mech_level = mech
	_replace_or_append(&"forge", _forge_slot(weapon_id, forge_level, stock_wave))
	_replace_or_append(&"skill", _skill_slot(hero_kind, skill_level, stock_wave, pack_id))
	_remove_kind(&"vitality")
	_replace_or_append(&"mech_repair", _mech_repair_slot(mech_level, stock_wave))
	_replace_or_append(&"summon", _summon_slot(stock_wave))
	if stock_wave >= 3 and not half_price_owned:
		_replace_or_append(&"half_price", _half_price_slot(stock_wave))
	elif half_price_owned:
		_remove_kind(&"half_price")


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
	if kind == &"vitality" and vitality_level >= VITALITY_CAP:
		result["message"] = "导师成长已满"
		return result
	if kind == &"half_price" and half_price_owned:
		result["message"] = "半价天赋已激活"
		return result
	if scrap < cost:
		result["message"] = "资源不足  /  需要 %d 金币" % cost
		return result
	result["ok"] = true
	result["cost"] = cost
	result["kind"] = kind
	result["payload"] = slot["payload"]
	result["message"] = String(slot.get("bought_text", "已购买"))
	if kind == &"tower" or kind == &"weapon":
		slots[index] = _restock_merchant_slot(StringName(slot.get("payload", &"")), stock_wave)
	elif kind == &"half_price":
		apply_half_price()
		_remove_kind(&"half_price")
	elif kind == &"vitality":
		vitality_level = mini(vitality_level + 1, VITALITY_CAP)
		_replace_or_append(&"vitality", _vitality_slot(vitality_level, stock_wave))
	elif kind == &"mech_repair":
		mech_level += 1
		_replace_or_append(&"mech_repair", _mech_repair_slot(mech_level, stock_wave))
	changed.emit()
	return result


func restore_slots(next_slots: Array) -> void:
	slots.clear()
	for item in next_slots:
		if item is Dictionary:
			slots.append((item as Dictionary).duplicate(true))
	is_open = true
	changed.emit()


## Persist half-price, mentor cycle, and mechanic level across wave-clear saves.
func growth_payload() -> Dictionary:
	return {
		"price_mult": price_mult,
		"half_price_owned": half_price_owned,
		"vitality_level": vitality_level,
		"mech_level": mech_level,
	}


## Restore shop growth. Missing keys keep safe defaults for old saves.
func restore_growth(data: Dictionary) -> void:
	half_price_owned = bool(data.get("half_price_owned", false))
	var fallback := 0.5 if half_price_owned else 1.0
	price_mult = maxf(float(data.get("price_mult", fallback)), 0.01)
	vitality_level = clampi(int(data.get("vitality_level", 0)), 0, VITALITY_CAP)
	mech_level = maxi(int(data.get("mech_level", 0)), 0)


func _replace_or_append(kind: StringName, slot: Dictionary) -> void:
	var idx := _first_kind_index(kind)
	if idx >= 0:
		slots[idx] = slot
	else:
		slots.append(slot)


func _remove_kind(kind: StringName) -> void:
	var idx := _first_kind_index(kind)
	if idx >= 0:
		slots.remove_at(idx)


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
	# Mix combat pads and SK facilities after wave 1.
	var roll := rng.randf()
	if roll < 0.22:
		return _tower_slot(&"hologram", wave)
	if roll < 0.55:
		return _tower_slot(FACILITY_KINDS[rng.randi() % FACILITY_KINDS.size()], wave)
	return _tower_slot(COMBAT_KINDS[rng.randi() % COMBAT_KINDS.size()], wave)


func _restock_merchant_slot(kind: StringName, wave: int) -> Dictionary:
	if EmberRunSave.is_valid_tower_kind(kind):
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
		"detail": "%s 攻击 +12%%，最多 5 级" % String(weapon.get("display_name", "武器")),
		"cost": scaled_price(120, wave),
		"bought_text": "%s锻造至 %d 级" % [String(weapon.get("display_name", "武器")), next_level],
		"icon": "res://assets/generated/ui/shop-forge.png",
	}, &"trainer")


func _skill_slot(hero_kind: StringName, current_level: int, wave: int, pack_id: StringName = &"") -> Dictionary:
	var cap := _skill_cap(hero_kind)
	var at_cap := current_level >= cap
	var title := "技能 满级" if at_cap else "技能提升"
	var detail := "提升当前英雄技能"
	if hero_kind == &"assassin":
		detail = "影分身数量 +1，最多 6 个"
	elif HeroPackCatalog.transform_into(pack_id) != &"" or HeroPackCatalog.form_base_id(pack_id) != &"":
		detail = "限时变身；变身后伤害、攻击范围、体型稍微变大"
	else:
		detail = "冲刺伤害、攻击范围、体型"
	var bought := "技能已满级" if at_cap else "技能已提升"
	return _with_vendor({
		"kind": &"skill",
		"payload": hero_kind,
		"title": title,
		"detail": detail,
		"cost": scaled_price(140, wave),
		"bought_text": bought,
		"icon": "res://assets/generated/ui/shop-dualwield.png",
	}, &"trainer")


func _vitality_slot(current_level: int, wave: int) -> Dictionary:
	var at_cap := current_level >= VITALITY_CAP
	var cycle := current_level % 3
	var title := "导师 满级" if at_cap else ("导师·生命" if cycle == 0 else "导师·能量" if cycle == 1 else "导师·护盾")
	var detail := "依次提升生命 / 冲刺回复 / 护甲"
	var payload := &"hp" if cycle == 0 else (&"energy" if cycle == 1 else &"shield")
	return _with_vendor({
		"kind": &"vitality",
		"payload": payload,
		"title": title,
		"detail": detail,
		"cost": scaled_price(70, wave),
		"bought_text": "导师成长至 %d 级" % mini(current_level + 1, VITALITY_CAP),
		"icon": "res://assets/generated/ui/shop-vitality.png",
	}, &"trainer")


func _mech_repair_slot(current_level: int, wave: int) -> Dictionary:
	return _with_vendor({
		"kind": &"mech_repair",
		"payload": &"repair_all",
		"title": "机械修复 Lv%d" % (current_level + 1),
		"detail": "修复场上全部炮台/掩体血量，并提升机械等级",
		"cost": scaled_price(90, wave),
		"bought_text": "全场机械已修复",
		"icon": "res://assets/generated/ui/shop-mech-repair.png",
	}, &"mechanic")


func _summon_slot(wave: int) -> Dictionary:
	return _with_vendor({
		"kind": &"summon",
		"payload": &"random",
		"title": "召唤师",
		"detail": "随机：金矿 / 回血 / 小爆 / 金币袋",
		"cost": scaled_price(50, wave),
		"bought_text": "召唤师已施法",
		"icon": "res://assets/generated/ui/shop-summon.png",
	}, &"summoner")


func _half_price_slot(wave: int) -> Dictionary:
	return _with_vendor({
		"kind": &"half_price",
		"payload": &"talent",
		"title": "半价天赋",
		"detail": "本局商店价格永久 50%",
		"cost": scaled_price(200, wave),
		"bought_text": "半价天赋已激活",
		"icon": "res://assets/generated/ui/shop-half-price.png",
	}, &"summoner")


func _tower_icon(kind: StringName) -> String:
	return EmberTower.icon_path_for(kind)

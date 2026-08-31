class_name WeaponCatalog
extends RefCounted

## Weapon numbers, hold icons, and attack FX. IDs must have files in
## assets/generated/weapons and assets/generated/weapon-fx (starter sword uses pickups/hold-sword).

static var _CACHE: Dictionary = {}


static func get_def(weapon_id: StringName) -> Dictionary:
	_ensure()
	if _CACHE.has(weapon_id):
		return (_CACHE[weapon_id] as Dictionary).duplicate(true)
	return (_CACHE[&"sword"] as Dictionary).duplicate(true)


static func is_ranged(weapon_id: StringName) -> bool:
	## Empty hands are unarmed melee. Do not treat "" as the sword fallback.
	if weapon_id == &"" or not has_id(weapon_id):
		return false
	return get_def(weapon_id)["kind"] != &"melee"


static func all_ids() -> Array[StringName]:
	_ensure()
	var ids: Array[StringName] = []
	for key: Variant in _CACHE.keys():
		ids.append(key as StringName)
	return ids


static func random_basic_weapon(rng: RandomNumberGenerator) -> StringName:
	_ensure()
	var pool: Array[StringName] = [
		&"pistol", &"revolver", &"smg", &"short-shotgun", &"dagger",
		&"short-sword", &"steel-sword", &"wood-bow", &"frost-staff",
		&"shuriken", &"ember-blade", &"ion-pistol",
	]
	return pool[rng.randi() % pool.size()]


static func random_boss_weapon(rng: RandomNumberGenerator) -> StringName:
	_ensure()
	var pool: Array[StringName] = [
		&"pistol_plus", &"shotgun_plus", &"plasma-cannon", &"inferno-cannon",
		&"gilded-bow", &"azure-blade", &"void-pistol", &"chainsaw",
		&"gold-gauntlet", &"rainbow-gun",
	]
	return pool[rng.randi() % pool.size()]


static func has_id(weapon_id: StringName) -> bool:
	_ensure()
	return _CACHE.has(weapon_id)


static func _ensure() -> void:
	if not _CACHE.is_empty():
		return
	for def: Dictionary in _build_table():
		_fit_visuals(def)
		_CACHE[def["id"]] = def


static func _fit_visuals(def: Dictionary) -> void:
	if def["id"] == &"sword":
		def["fx_scale"] = 1.08
		return
	var kind: StringName = def["kind"]
	var hold_path := String(def.get("hold_path", ""))
	var fx_path := String(def.get("fx_path", ""))
	var hold_len := _tex_long_axis(hold_path)
	var hold_target := 28.0
	var fx_target := 16.0
	match kind:
		&"melee":
			hold_target = 34.0
			fx_target = 42.0
		&"shotgun":
			hold_target = 34.0
			fx_target = 28.0
		&"launcher":
			hold_target = 38.0
			fx_target = 32.0
		&"bow":
			hold_target = 32.0
			fx_target = 26.0
		&"staff":
			hold_target = 34.0
			fx_target = 26.0
		&"thrown":
			hold_target = 22.0
			fx_target = 26.0
		&"pistol":
			if hold_len >= 100.0:
				hold_target = 36.0
				fx_target = 30.0
			else:
				hold_target = 28.0
				fx_target = 28.0
		_:
			hold_target = 28.0
			fx_target = 26.0
	def["hold_scale"] = _fit_scale(hold_path, hold_target, hold_len, float(def.get("hold_scale", 0.36)))
	def["fx_scale"] = clampf(_fit_scale(fx_path, fx_target, _tex_long_axis(fx_path), float(def.get("fx_scale", 0.22))) * 2.20, 0.42, 1.20)
	def["pickup_scale"] = clampf(float(def["hold_scale"]) * 1.15, 0.28, 0.42)


static func _tex_long_axis(path: String) -> float:
	if path.is_empty():
		return 0.0
	var tex := load(path) as Texture2D
	if tex == null:
		return 0.0
	return maxf(float(tex.get_width()), float(tex.get_height()))


static func _fit_scale(path: String, target_px: float, long_axis: float, fallback: float) -> float:
	if path.is_empty() or long_axis < 8.0:
		return fallback
	return clampf(target_px / long_axis, 0.14, 0.50)


static func _build_table() -> Array[Dictionary]:
	var table: Array[Dictionary] = [
		_legacy_sword(),
		_melee("dagger", "匕首", 38, 0.10, 108.0, 50),
		_melee("short-sword", "短剑", 42, 0.11, 112.0, 55),
		_melee("crimson-blade", "赤刃", 48, 0.12, 118.0, 70),
		_melee("steel-sword", "钢剑", 46, 0.12, 118.0, 70),
		_melee("azure-blade", "碧蓝剑", 50, 0.12, 120.0, 75),
		_melee("ember-blade", "余烬剑", 52, 0.13, 120.0, 80),
		_melee("violet-blade", "紫刃", 50, 0.12, 118.0, 75),
		_melee("jade-blade", "翠刃", 48, 0.12, 118.0, 70),
		_melee("pink-saber", "粉刃", 44, 0.11, 114.0, 65),
		_melee("chainsaw", "链锯", 56, 0.16, 104.0, 85),
		_melee("mallet", "大锤", 60, 0.20, 96.0, 85),
		_melee("crystal-mace", "晶锤", 58, 0.18, 100.0, 85),
		_melee("sun-mace", "日冕锤", 62, 0.20, 100.0, 90),
		_melee("gold-gauntlet", "金拳套", 54, 0.14, 92.0, 80),
		_gun("pistol", "手枪", &"pistol", 18, 0.28, 1, 3.5, 700.0, 420.0, 18, 16.0, 3.2, 60, 0.80, 0.48, 16.0),
		_gun("revolver", "左轮", &"pistol", 24, 0.38, 1, 2.4, 680.0, 400.0, 24, 20.0, 4.0, 70, 0.78, 0.46, 16.0),
		_gun("sawed-pistol", "锯管手枪", &"shotgun", 26, 0.55, 1, 14.0, 540.0, 220.0, 16, 22.0, 6.0, 70, 0.74, 0.42, 22.0),
		_gun("smg", "冲锋枪", &"pistol", 9, 0.11, 1, 6.0, 720.0, 360.0, 9, 10.0, 4.5, 65, 0.76, 0.40, 14.0),
		_gun("ion-pistol", "离子枪", &"pistol", 20, 0.30, 1, 3.0, 740.0, 440.0, 20, 14.0, 3.0, 70, 0.78, 0.50, 16.0),
		_gun("flare-blaster", "信号枪", &"pistol", 22, 0.34, 1, 4.0, 640.0, 380.0, 18, 18.0, 4.0, 70, 0.76, 0.50, 16.0),
		_gun("plasma-pistol", "等离子手枪", &"pistol", 21, 0.32, 1, 3.2, 700.0, 430.0, 21, 15.0, 3.4, 75, 0.78, 0.50, 16.0),
		_gun("chrome-pistol", "铬金手枪", &"pistol", 19, 0.26, 1, 3.0, 720.0, 420.0, 19, 14.0, 3.0, 70, 0.78, 0.48, 16.0),
		_gun("void-pistol", "虚空手枪", &"pistol", 23, 0.30, 1, 2.8, 760.0, 460.0, 23, 16.0, 3.2, 80, 0.78, 0.52, 16.0),
		_gun("short-shotgun", "短管霰弹", &"shotgun", 28, 0.70, 1, 16.0, 560.0, 240.0, 16, 28.0, 6.0, 75, 0.72, 0.42, 24.0),
		_gun("drum-rifle", "鼓轮步枪", &"shotgun", 16, 0.22, 3, 10.0, 620.0, 360.0, 10, 18.0, 5.0, 80, 0.70, 0.38, 16.0),
		_gun("gatling", "加特林", &"pistol", 8, 0.09, 1, 7.0, 680.0, 340.0, 8, 8.0, 5.5, 85, 0.68, 0.40, 16.0),
		_gun("rocket-launcher", "火箭筒", &"launcher", 36, 0.90, 1, 2.0, 380.0, 520.0, 36, 32.0, 2.0, 95, 0.62, 0.52, 22.0),
		_gun("ember-cannon", "余烬炮", &"launcher", 34, 0.85, 1, 2.5, 400.0, 500.0, 34, 30.0, 2.2, 95, 0.62, 0.52, 22.0),
		_gun("plasma-cannon", "等离子炮", &"launcher", 38, 0.92, 1, 2.0, 420.0, 540.0, 38, 30.0, 2.0, 100, 0.62, 0.54, 22.0),
		_gun("frost-cannon", "霜冻炮", &"launcher", 32, 0.88, 1, 2.2, 400.0, 510.0, 32, 28.0, 2.0, 95, 0.62, 0.52, 22.0),
		_gun("inferno-cannon", "炼狱炮", &"launcher", 40, 0.96, 1, 2.0, 360.0, 500.0, 40, 34.0, 2.4, 105, 0.62, 0.54, 24.0),
		_gun("heavy-launcher", "重型发射器", &"launcher", 30, 0.80, 1, 3.0, 340.0, 480.0, 24, 26.0, 3.0, 90, 0.64, 0.50, 20.0),
		_gun("wood-bow", "木弓", &"bow", 22, 0.48, 1, 1.5, 620.0, 500.0, 22, 12.0, 1.5, 70, 0.58, 0.48, 16.0),
		_gun("leaf-bow", "叶弓", &"bow", 24, 0.46, 1, 1.4, 640.0, 520.0, 24, 12.0, 1.4, 75, 0.58, 0.48, 16.0),
		_gun("royal-bow", "王室弓", &"bow", 28, 0.50, 1, 1.2, 660.0, 540.0, 28, 14.0, 1.2, 85, 0.58, 0.50, 16.0),
		_gun("dark-bow", "暗弓", &"bow", 26, 0.48, 1, 1.3, 650.0, 530.0, 26, 13.0, 1.3, 80, 0.58, 0.48, 16.0),
		_gun("gilded-bow", "金弓", &"bow", 32, 0.52, 1, 1.0, 680.0, 560.0, 32, 16.0, 1.0, 95, 0.58, 0.52, 16.0),
		_gun("frost-staff", "霜杖", &"staff", 20, 0.40, 1, 2.0, 500.0, 440.0, 20, 10.0, 2.0, 80, 0.52, 0.50, 16.0),
		_gun("ember-staff", "余烬杖", &"staff", 22, 0.42, 1, 2.0, 510.0, 450.0, 22, 10.0, 2.0, 85, 0.52, 0.50, 16.0),
		_gun("void-staff", "虚空杖", &"staff", 24, 0.44, 1, 1.8, 540.0, 470.0, 24, 10.0, 1.8, 90, 0.52, 0.52, 16.0),
		_gun("ice-staff", "冰杖", &"staff", 21, 0.40, 1, 2.0, 520.0, 450.0, 21, 10.0, 2.0, 80, 0.52, 0.50, 16.0),
		_gun("nature-staff", "自然杖", &"staff", 19, 0.38, 1, 2.2, 500.0, 430.0, 19, 9.0, 2.0, 80, 0.52, 0.50, 16.0),
		_gun("hex-tome", "咒书", &"staff", 23, 0.46, 1, 2.5, 480.0, 420.0, 23, 8.0, 2.2, 85, 0.50, 0.50, 16.0),
		_gun("shuriken", "手里剑", &"thrown", 14, 0.22, 1, 4.0, 640.0, 280.0, 14, 8.0, 2.0, 55, 0.52, 0.46, 14.0),
		_gun("boomerang", "回旋镖", &"thrown", 16, 0.36, 1, 3.0, 480.0, 300.0, 16, 10.0, 2.5, 60, 0.52, 0.48, 16.0),
		_gun("grenade", "手雷", &"thrown", 28, 0.80, 1, 2.0, 320.0, 240.0, 22, 18.0, 3.0, 70, 0.50, 0.48, 22.0),
		_gun("dynamite", "炸药", &"thrown", 30, 0.85, 1, 2.0, 300.0, 230.0, 24, 18.0, 3.0, 75, 0.50, 0.48, 22.0),
		_gun("molotov", "燃烧瓶", &"thrown", 24, 0.70, 1, 3.0, 340.0, 250.0, 18, 16.0, 3.0, 70, 0.50, 0.48, 20.0),
		_gun("shock-mine", "震爆雷", &"thrown", 26, 0.75, 1, 2.0, 280.0, 220.0, 20, 16.0, 3.0, 70, 0.50, 0.48, 22.0),
		_gun("green-potion", "绿瓶", &"thrown", 18, 0.50, 1, 3.0, 360.0, 240.0, 14, 12.0, 2.5, 55, 0.50, 0.46, 16.0),
		_gun("red-potion", "红瓶", &"thrown", 18, 0.50, 1, 3.0, 360.0, 240.0, 14, 12.0, 2.5, 55, 0.50, 0.46, 16.0),
		_gun("fish", "咸鱼", &"thrown", 12, 0.28, 1, 6.0, 420.0, 260.0, 12, 14.0, 4.0, 50, 0.52, 0.48, 16.0),
		_gun("carrot", "胡萝卜", &"thrown", 12, 0.26, 1, 5.0, 440.0, 260.0, 12, 12.0, 3.5, 50, 0.52, 0.46, 16.0),
		_gun("rainbow-gun", "彩虹枪", &"pistol", 20, 0.24, 1, 4.0, 700.0, 420.0, 20, 16.0, 3.5, 90, 0.74, 0.50, 16.0),
		_gun("unicorn-gun", "独角兽枪", &"pistol", 21, 0.26, 1, 3.5, 680.0, 430.0, 21, 16.0, 3.5, 90, 0.72, 0.50, 16.0),
		_gun("wolf-gun", "狼头枪", &"pistol", 22, 0.28, 1, 3.2, 660.0, 400.0, 22, 18.0, 3.8, 90, 0.72, 0.50, 16.0),
		_gun("shark-gun", "鲨鱼枪", &"shotgun", 30, 0.72, 1, 12.0, 520.0, 260.0, 18, 24.0, 5.0, 95, 0.70, 0.48, 22.0),
	]
	var pistol := get_from_list(table, &"pistol")
	pistol["id"] = &"pistol_plus"
	pistol["display_name"] = "强化手枪"
	pistol["damage"] = 23
	pistol["falloff_damage"] = 23
	pistol["shop_cost"] = 90
	table.append(pistol)
	var shotgun := get_from_list(table, &"short-shotgun")
	shotgun["id"] = &"shotgun"
	shotgun["display_name"] = "霰弹"
	shotgun["pickup_path"] = "res://assets/generated/weapons/short-shotgun.png"
	shotgun["hold_path"] = "res://assets/generated/weapons/short-shotgun.png"
	shotgun["fx_path"] = "res://assets/generated/weapon-fx/short-shotgun.png"
	table.append(shotgun)
	var shotgun_plus := shotgun.duplicate(true)
	shotgun_plus["id"] = &"shotgun_plus"
	shotgun_plus["display_name"] = "强化霰弹"
	shotgun_plus["damage"] = 36
	shotgun_plus["falloff_damage"] = 22
	shotgun_plus["shop_cost"] = 100
	table.append(shotgun_plus)
	return table


static func get_from_list(table: Array[Dictionary], weapon_id: StringName) -> Dictionary:
	for item: Dictionary in table:
		if item["id"] == weapon_id:
			return item.duplicate(true)
	return {}


static func _legacy_sword() -> Dictionary:
	return {
		"id": &"sword",
		"display_name": "大宝剑",
		"kind": &"melee",
		"damage": 46,
		"cooldown": 0.12,
		"pellet_count": 0,
		"spread_degrees": 0.0,
		"speed": 0.0,
		"max_range": 118.0,
		"falloff_range": 118.0,
		"falloff_damage": 46,
		"recoil": 0.0,
		"bloom": 0.0,
		"shop_cost": 0,
		"hold_scale": 0.48,
		"hold_offset": Vector2(29.0, 0.0),
		"hold_position": Vector2(18.0, -22.0),
		"hold_attack_position": Vector2(24.0, -20.0),
		"fx_scale": 0.76,
		"fx_offset": Vector2(54.0, -4.0),
		"hit_radius": 16.0,
		"pickup_path": "res://assets/generated/pickups/hold-sword.png",
		"hold_path": "res://assets/generated/pickups/hold-sword.png",
		"fx_path": "res://assets/generated/weapon-fx/sword.png",
	}


static func _melee(id: String, display_name: String, damage: int, cooldown: float, reach: float, shop_cost: int) -> Dictionary:
	return {
		"id": StringName(id),
		"display_name": display_name,
		"kind": &"melee",
		"damage": damage,
		"cooldown": cooldown,
		"pellet_count": 0,
		"spread_degrees": 0.0,
		"speed": 0.0,
		"max_range": reach,
		"falloff_range": reach,
		"falloff_damage": damage,
		"recoil": 0.0,
		"bloom": 0.0,
		"shop_cost": shop_cost,
		"hold_scale": 0.46,
		"fx_scale": 0.58,
		"hit_radius": 18.0,
		"pickup_path": "res://assets/generated/weapons/%s.png" % id,
		"hold_path": "res://assets/generated/weapons/%s.png" % id,
		"fx_path": "res://assets/generated/weapon-fx/%s.png" % id,
	}


static func _gun(
	id: String,
	display_name: String,
	kind: StringName,
	damage: int,
	cooldown: float,
	pellets: int,
	spread: float,
	speed: float,
	max_range: float,
	falloff_damage: int,
	recoil: float,
	bloom: float,
	shop_cost: int,
	hold_scale: float,
	fx_scale: float,
	hit_radius: float
) -> Dictionary:
	return {
		"id": StringName(id),
		"display_name": display_name,
		"kind": kind,
		"damage": damage,
		"cooldown": cooldown,
		"pellet_count": pellets,
		"spread_degrees": spread,
		"speed": speed,
		"max_range": max_range,
		"falloff_range": max_range,
		"falloff_damage": falloff_damage,
		"recoil": recoil,
		"bloom": bloom,
		"shop_cost": shop_cost,
		"hold_scale": hold_scale,
		"fx_scale": fx_scale,
		"hit_radius": hit_radius,
		"pickup_path": "res://assets/generated/weapons/%s.png" % id,
		"hold_path": "res://assets/generated/weapons/%s.png" % id,
		"fx_path": "res://assets/generated/weapon-fx/%s.png" % id,
	}

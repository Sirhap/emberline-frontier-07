class_name EmberTower
extends Node2D

signal fired(tower: EmberTower, target: FrontierEnemy)
signal upgraded(tower: EmberTower, level: int)

var selected := false
var kind: StringName = &"pulse"
var weapon_id: StringName = &""
var level := 1
var pad_index := -1
var attack_range := 205.0
var attack_damage := 24
var attack_cooldown := 0.72
var place_cost := 80

var _cooldown_left := 0.0
var _game: Node
var _sprite: Sprite2D
var _idle := 0.0
var _kick := 0.0
var _rest_scale := Vector2.ONE
var _rest_y := -22.0

func configure(game: Node, tower_kind: StringName = &"pulse", planted_weapon: StringName = &"") -> void:
	_game = game
	if planted_weapon != &"" and WeaponCatalog.has_id(planted_weapon):
		weapon_id = planted_weapon
		kind = tower_kind if EmberRunSave.is_valid_tower_kind(tower_kind) else &"pulse"
		_apply_weapon_stats()
	else:
		weapon_id = &""
		kind = tower_kind
		_apply_level_stats()
	queue_redraw()


func mount_weapon(next_weapon: StringName) -> StringName:
	var previous := weapon_id
	if next_weapon != &"" and WeaponCatalog.has_id(next_weapon):
		weapon_id = next_weapon
		_apply_weapon_stats()
	else:
		weapon_id = &""
		_apply_level_stats()
	queue_redraw()
	return previous


func refresh_weapon_stats() -> void:
	if weapon_id != &"":
		_apply_weapon_stats()
		queue_redraw()

func _ready() -> void:
	_build_sprite()
	if weapon_id != &"":
		_apply_weapon_stats()
	else:
		_apply_level_stats()
	queue_redraw()

func _process(delta: float) -> void:
	_idle += delta
	_kick = maxf(_kick - delta * 7.0, 0.0)
	_update_motion()
	if _game == null:
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _cooldown_left > 0.0:
		return
	var target: FrontierEnemy = _game.find_enemy_in_range(global_position, attack_range)
	if target == null:
		return
	_cooldown_left = attack_cooldown
	_kick = 1.0
	if weapon_id != &"":
		_fire_planted_weapon(target)
	else:
		_game.spawn_projectile(global_position + Vector2(0.0, -32.0), target, attack_damage, kind)
	fired.emit(self, target)

func upgrade() -> bool:
	if weapon_id != &"" or level >= 3:
		return false
	level += 1
	_apply_level_stats()
	upgraded.emit(self, level)
	queue_redraw()
	return true

func get_upgrade_cost() -> int:
	if weapon_id != &"":
		return 0
	match kind:
		&"burst":
			return 140 if level == 1 else 210 if level == 2 else 0
		&"frost":
			return 120 if level == 1 else 190 if level == 2 else 0
		_:
			return 110 if level == 1 else 180 if level == 2 else 0

func get_level_label() -> String:
	if weapon_id != &"":
		return String(WeaponCatalog.get_def(weapon_id).get("display_name", "武器"))
	return "等级 %d  /  %s" % [level, kind_display_name(kind, level)]

func get_stats_text() -> String:
	return "伤害 %02d   范围 %03d   间隔 %.2f 秒" % [attack_damage, int(attack_range), attack_cooldown]

static func build_cost(tower_kind: StringName) -> int:
	match tower_kind:
		&"burst":
			return 110
		&"frost":
			return 90
		_:
			return 80

static func sell_refund(tower_kind: StringName) -> int:
	return int(floor(float(build_cost(tower_kind)) * 0.60))

func sell_value() -> int:
	if weapon_id != &"":
		return int(floor(float(maxi(place_cost, 1)) * 0.60))
	return sell_refund(kind)

func restore_level(saved_level: int) -> void:
	level = clampi(saved_level, 1, 3)
	_apply_level_stats()

static func kind_display_name(tower_kind: StringName, tower_level: int = 1) -> String:
	match tower_kind:
		&"burst":
			return "爆裂塔" if tower_level == 1 else "榴霰炮" if tower_level == 2 else "炎爆核心"
		&"frost":
			return "霜钉塔" if tower_level == 1 else "寒冰炮" if tower_level == 2 else "霜狱核心"
		_:
			return "脉冲塔" if tower_level == 1 else "聚能炮" if tower_level == 2 else "雷霆核心"

func _apply_weapon_stats() -> void:
	var weapon := WeaponCatalog.get_def(weapon_id)
	attack_range = maxf(float(weapon.get("max_range", 180.0)), 90.0)
	var base := float(weapon.get("damage", 18))
	var mult := 1.0
	if _game != null and _game.has_method("weapon_forge_mult"):
		mult = float(_game.call("weapon_forge_mult", weapon_id))
	attack_damage = maxi(1, int(round(base * mult)))
	attack_cooldown = maxf(float(weapon.get("cooldown", 0.55)), 0.40)
	place_cost = int(weapon.get("shop_cost", 60))
	_update_sprite()

func _fire_planted_weapon(target: FrontierEnemy) -> void:
	if _game == null or not is_instance_valid(target):
		return
	var weapon := WeaponCatalog.get_def(weapon_id)
	var origin := global_position + Vector2(0.0, -22.0)
	var aim := origin.direction_to(target.hurt_center() if target.has_method("hurt_center") else target.global_position)
	if aim.is_zero_approx():
		aim = Vector2.RIGHT
	if WeaponCatalog.is_ranged(weapon_id):
		if _game.has_method("spawn_muzzle_flash"):
			_game.spawn_muzzle_flash(origin, aim)
		var pellets := maxi(int(weapon.get("pellet_count", 1)), 1)
		var spread := deg_to_rad(float(weapon.get("spread_degrees", 0.0)))
		var base := aim.angle()
		if pellets <= 1:
			_game.spawn_hero_projectile(origin, Vector2.from_angle(base), weapon)
			return
		for index: int in range(pellets):
			var t := (float(index) / float(pellets - 1)) * 2.0 - 1.0
			_game.spawn_hero_projectile(origin, Vector2.from_angle(base + t * spread), weapon)
		return
	target.take_damage(attack_damage, &"hero")
	if _game.has_method("_spawn_melee_slash"):
		_game._spawn_melee_slash(origin, 1 if aim.x >= 0.0 else -1, weapon)

func _apply_level_stats() -> void:
	place_cost = build_cost(kind)
	match kind:
		&"burst":
			match level:
				1:
					attack_range = 190.0
					attack_damage = 16
					attack_cooldown = 0.90
				2:
					attack_range = 210.0
					attack_damage = 24
					attack_cooldown = 0.76
				_:
					attack_range = 230.0
					attack_damage = 36
					attack_cooldown = 0.64
		&"frost":
			match level:
				1:
					attack_range = 200.0
					attack_damage = 10
					attack_cooldown = 0.80
				2:
					attack_range = 220.0
					attack_damage = 14
					attack_cooldown = 0.68
				_:
					attack_range = 240.0
					attack_damage = 20
					attack_cooldown = 0.56
		_:
			match level:
				1:
					attack_range = 205.0
					attack_damage = 24
					attack_cooldown = 0.72
				2:
					attack_range = 230.0
					attack_damage = 38
					attack_cooldown = 0.58
				_:
					attack_range = 255.0
					attack_damage = 58
					attack_cooldown = 0.46
	_update_sprite()

func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "TowerSprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

func _texture_path() -> String:
	if weapon_id != &"":
		var weapon := WeaponCatalog.get_def(weapon_id)
		var hold_path := String(weapon.get("hold_path", ""))
		if hold_path.is_empty():
			hold_path = String(weapon.get("pickup_path", ""))
		return hold_path
	match kind:
		&"burst":
			return "res://assets/generated/towers/burst-lv%d.png" % level
		&"frost":
			return "res://assets/generated/towers/frost-lv%d.png" % level
		_:
			return "res://assets/generated/towers/tower-lv%d.png" % level

func _update_sprite() -> void:
	if _sprite == null:
		return
	var path := _texture_path()
	_sprite.texture = load(path) as Texture2D if path != "" else null
	if _sprite.texture == null:
		return
	var tex_h := float(_sprite.texture.get_height())
	var visual_scale := 0.48 if level == 1 else 0.46
	if weapon_id != &"":
		var hold_scale := float(WeaponCatalog.get_def(weapon_id).get("hold_scale", 0.46))
		visual_scale = clampf(hold_scale * 1.55, 0.38, 0.72)
	_rest_scale = Vector2.ONE * visual_scale
	var half_h := tex_h * visual_scale * 0.5
	_rest_y = -half_h + 2.0
	_sprite.scale = _rest_scale
	_sprite.position = Vector2(0.0, _rest_y)

func _update_motion() -> void:
	if _sprite == null:
		return
	var bob := sin(_idle * 3.2 + global_position.x * 0.02) * 1.6
	var kick_y := _kick * 6.0
	var squash := 1.0 + _kick * 0.18
	_sprite.position = Vector2(sin(_idle * 1.7) * 0.6, _rest_y + bob - kick_y)
	_sprite.scale = _rest_scale * Vector2(2.0 - squash, squash)
	_sprite.rotation = sin(_idle * 1.4) * 0.03 + _kick * -0.12

func _draw() -> void:
	if selected:
		draw_circle(Vector2.ZERO, attack_range, Color(0.10, 0.80, 0.80, 0.035))
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 96, Color(0.25, 0.93, 0.87, 0.42), 2.0)
	draw_shadow_ellipse(Vector2(0.0, 3.0), Vector2(14.0 if level < 3 else 16.0, 3.5), Color(0.01, 0.02, 0.06, 0.64))
	var ring_color := Color("#d7b15a") if selected else Color("#6a5428")
	draw_arc(Vector2(0.0, 2.0), 12.0 if level < 3 else 14.0, 0.0, TAU, 32, ring_color, 1.0)

func draw_shadow_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

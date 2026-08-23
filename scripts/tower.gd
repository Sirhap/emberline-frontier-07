class_name EmberTower
extends Node2D

signal fired(tower: EmberTower, target: FrontierEnemy)
signal upgraded(tower: EmberTower, level: int)

var selected := false
var kind: StringName = &"pulse"
var level := 1
var pad_index := -1
var attack_range := 205.0
var attack_damage := 24
var attack_cooldown := 0.72

var _cooldown_left := 0.0
var _game: Node
var _sprite: Sprite2D
var _idle := 0.0
var _kick := 0.0
var _rest_scale := Vector2.ONE
var _rest_y := -22.0

func configure(game: Node, tower_kind: StringName = &"pulse") -> void:
	_game = game
	kind = tower_kind
	_apply_level_stats()
	queue_redraw()

func _ready() -> void:
	_build_sprite()
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
	_game.spawn_projectile(global_position + Vector2(0.0, -32.0), target, attack_damage, kind)
	fired.emit(self, target)

func upgrade() -> bool:
	if level >= 3:
		return false
	level += 1
	_apply_level_stats()
	upgraded.emit(self, level)
	queue_redraw()
	return true

func get_upgrade_cost() -> int:
	match kind:
		&"burst":
			return 140 if level == 1 else 210 if level == 2 else 0
		&"frost":
			return 120 if level == 1 else 190 if level == 2 else 0
		_:
			return 110 if level == 1 else 180 if level == 2 else 0

func get_level_label() -> String:
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

func _apply_level_stats() -> void:
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
	_sprite.texture = load(_texture_path()) as Texture2D
	var visual_scale := 0.48 if level == 1 else 0.46
	_rest_scale = Vector2.ONE * visual_scale
	_rest_y = -22.0
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
	draw_shadow_ellipse(Vector2(0.0, 14.0), Vector2(18.0 if level < 3 else 20.0, 4.0), Color(0.01, 0.02, 0.06, 0.64))
	var ring_color := Color("#d7b15a") if selected else Color("#6a5428")
	draw_arc(Vector2(0.0, 10.0), 16.0 if level < 3 else 18.0, 0.0, TAU, 32, ring_color, 1.0)

func draw_shadow_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

class_name FrontierEnemy
extends Node2D

signal reached_base(enemy: FrontierEnemy)
signal defeated(enemy: FrontierEnemy, reward: int)
signal hit(enemy: FrontierEnemy, amount: int, source: StringName)
signal shot_fired(enemy: FrontierEnemy, direction: Vector2, damage: int)

@export var max_health: int = 80
@export var move_speed: float = 48.0
@export var reward: int = 22
@export var base_x: float = 1085.0
@export var lane_y: float = 380.0
@export var variant: StringName = &"scout"
@export var core_damage: int = 1
@export var contact_damage: int = 8

const AGGRO_RADIUS := 96.0
const LEASH_RADIUS := 144.0
const LEASH_DROP := 0.40
const CONTACT_HOLD := 26.0
const TOWER_CONTACT_RADIUS := 40.0
const MAGE_SHOT_COOLDOWN := 1.40

var health: int
var route_points := PackedVector2Array()
var _is_active := true
var _flash_time := 0.0
var _slow_left := 0.0
var _slow_factor := 1.0
var _sprite: Sprite2D
var _route_index := 1
var _walk_frames: Array[Texture2D] = []
var _attack_frames: Array[Texture2D] = []
var _walk_accum := 0.0
var _walk_index := 0
var _walk_step := 12.0
var _attacking := false
var _attack_accum := 0.0
var _attack_index := 0
const ATTACK_FPS := 10.0
const DIE_TIME := 0.38
var _rest_scale := Vector2.ONE
var _rest_sprite_y := -18.0
var _hurt_offset := Vector2(0.0, -18.0)
var _hurt_radius := 26.0
var _visual_top := -50.0
var _spawn_pop := 1.0
var _idle := 0.0
var _seek := false
var _goal := Vector2.ZERO
var _core_goal := Vector2.ZERO
var _aggro := false
var _leash_away := 0.0
var _game: Node
var _tower_target: EmberTower
var _contact_pending := false
var _shot_pending := false
var _shot_cd := 0.0
var _dying := false
var _die_left := 0.0

## Assigns a complete entrance-to-core route before the enemy enters the scene tree.
func configure_route(points: PackedVector2Array) -> void:
	_seek = false
	route_points = points.duplicate()
	_route_index = 1
	if not route_points.is_empty():
		position = route_points[0]
		lane_y = position.y
		base_x = route_points[route_points.size() - 1].x

func configure_seek(start: Vector2, goal: Vector2, game: Node = null) -> void:
	_seek = true
	_game = game
	route_points = PackedVector2Array()
	position = start
	_goal = goal
	_core_goal = goal
	_aggro = false
	_leash_away = 0.0
	lane_y = start.y
	base_x = goal.x

func _ready() -> void:
	health = max_health
	if not _seek:
		if route_points.is_empty():
			position.y = lane_y
		else:
			position = route_points[0]
	add_to_group("ember_enemies")
	_build_sprite()
	queue_redraw()

func _process(delta: float) -> void:
	if _dying:
		_advance_defeat(delta)
		return
	if not _is_active:
		return
	_flash_time = maxf(_flash_time - delta, 0.0)
	_slow_left = maxf(_slow_left - delta, 0.0)
	if _slow_left <= 0.0:
		_slow_factor = 1.0
	_idle += delta
	_spawn_pop = maxf(_spawn_pop - delta * 3.8, 0.0)
	if _attacking:
		_advance_attack(delta)
	if _sprite != null:
		_sprite.modulate = Color(1.0, 0.60, 0.52) if _flash_time > 0.0 else Color.WHITE
		var pop := 1.0 + _spawn_pop * 0.55
		_sprite.scale = _rest_scale * Vector2(pop, 2.0 - pop)
		_sprite.position.y = _rest_sprite_y + sin(_idle * 6.0 + position.x * 0.05) * (0.9 if _spawn_pop <= 0.0 else 0.0)
	if _seek:
		_update_aggro(delta)
		_follow_seek(_effective_speed() * delta)
		_tick_tower_contact()
	elif route_points.is_empty():
		var step := _effective_speed() * delta
		position.x += step
		_advance_walk(step, Vector2.RIGHT)
		if position.x >= base_x:
			_reach_base()
			return
	else:
		_follow_route(_effective_speed() * delta)
	_tick_ranged(delta)
	queue_redraw()

func _update_aggro(delta: float) -> void:
	var hero_pos := Vector2.INF
	if _game != null and _game.has_method("hero_seek_position"):
		hero_pos = _game.call("hero_seek_position") as Vector2
	if not hero_pos.is_finite():
		_aggro = false
		_leash_away = 0.0
		_goal = _core_goal
		return
	var dist := global_position.distance_to(hero_pos)
	if dist <= AGGRO_RADIUS:
		_aggro = true
		_leash_away = 0.0
		_goal = hero_pos
		return
	if _aggro and dist <= LEASH_RADIUS:
		_leash_away = 0.0
		_goal = hero_pos
		return
	if _aggro:
		_leash_away += delta
		if _leash_away >= LEASH_DROP:
			_aggro = false
			_leash_away = 0.0
			_goal = _core_goal
		else:
			_goal = hero_pos
		return
	_goal = _core_goal


func _maybe_lock_tower() -> void:
	if _aggro:
		_tower_target = null
		return
	var tower := _find_contact_tower()
	if tower != null:
		_tower_target = tower
		_goal = tower.global_position
	else:
		_tower_target = null


func _find_contact_tower() -> EmberTower:
	if _game != null and _game.has_method("find_tower_in_range"):
		var found: Variant = _game.call("find_tower_in_range", global_position, TOWER_CONTACT_RADIUS)
		if found is EmberTower and is_instance_valid(found):
			return found as EmberTower
	return null


func _tick_tower_contact() -> void:
	if _aggro or _dying or not _is_active:
		return
	var tower: EmberTower = _tower_target if (_tower_target != null and is_instance_valid(_tower_target)) else _find_contact_tower()
	if tower == null or not is_instance_valid(tower):
		return
	if global_position.distance_to(tower.global_position) > CONTACT_HOLD:
		return
	if not _attacking:
		play_attack(tower.global_position - global_position)
	if consume_contact_hit() and tower.has_method("take_damage"):
		tower.take_damage(contact_damage)


func _follow_seek(travel_distance: float) -> void:
	_maybe_lock_tower()
	if (not _aggro) and _tower_target == null and global_position.distance_to(_core_goal) <= 22.0:
		_reach_base()
		return
	var want := _goal
	if _game != null and _game.has_method("enemy_path_point"):
		want = _game.call("enemy_path_point", global_position, _goal) as Vector2
	var to_goal := want - global_position
	var tower_lock := _tower_target != null and is_instance_valid(_tower_target)
	var hold := CONTACT_HOLD if (_aggro or tower_lock) else 22.0
	var direction := Vector2.ZERO
	if to_goal.length() > hold:
		direction = to_goal.normalized()
	if (not tower_lock) and _game != null and _game.has_method("steer_enemy"):
		var steered: Variant = _game.call("steer_enemy", global_position, direction, self)
		if steered is Vector2:
			direction = steered
	if direction.is_zero_approx():
		return
	var next := global_position + direction * travel_distance
	if _game != null and _game.has_method("clamp_enemy_position"):
		next = _game.call("clamp_enemy_position", global_position, next, self) as Vector2
	global_position = next
	_advance_walk(travel_distance, direction)


func _follow_route(travel_distance: float) -> void:
	var remaining := maxf(travel_distance, 0.0)
	var last_direction := Vector2.LEFT
	while remaining > 0.0 and _route_index < route_points.size():
		var target_point := route_points[_route_index]
		var to_target := target_point - position
		if not to_target.is_zero_approx():
			last_direction = to_target
		var distance_to_target := position.distance_to(target_point)
		if distance_to_target <= remaining:
			position = target_point
			_advance_walk(distance_to_target, last_direction)
			remaining -= distance_to_target
			_route_index += 1
		else:
			position = position.move_toward(target_point, remaining)
			_advance_walk(remaining, last_direction)
			remaining = 0.0
	if _route_index >= route_points.size():
		_reach_base()

func is_ranged() -> bool:
	return variant == &"mage"


func play_attack(face: Vector2 = Vector2.ZERO, ranged: bool = false) -> void:
	if _sprite == null or _attack_frames.is_empty():
		return
	if absf(face.x) > 0.08:
		_sprite.flip_h = face.x < 0.0
	_attacking = true
	_attack_accum = 0.0
	_attack_index = 0
	_contact_pending = not ranged
	_shot_pending = ranged
	_sprite.texture = _attack_frames[0]


func consume_contact_hit() -> bool:
	if not _contact_pending:
		return false
	var hit_at := 3 if variant == &"boss" else 2
	if _attack_index < hit_at:
		return false
	_contact_pending = false
	return true


func _tick_ranged(delta: float) -> void:
	if not is_ranged() or not _is_active or _dying:
		return
	_shot_cd = maxf(_shot_cd - delta, 0.0)
	if _attacking or _shot_cd > 0.0:
		return
	var hero_pos := _hero_seek_pos()
	if not hero_pos.is_finite():
		return
	var dist := global_position.distance_to(hero_pos)
	if dist <= CONTACT_HOLD or dist > 176.0:
		return
	play_attack(hero_pos - global_position, true)
	_shot_cd = MAGE_SHOT_COOLDOWN


func _try_emit_shot() -> void:
	if not _shot_pending or _attack_index < 2:
		return
	_shot_pending = false
	var hero_pos := _hero_seek_pos()
	var dir := Vector2.LEFT
	if hero_pos.is_finite():
		dir = hero_pos - global_position
		if dir.is_zero_approx():
			dir = Vector2.LEFT
		else:
			dir = dir.normalized()
	elif _sprite != null:
		dir = Vector2.LEFT if _sprite.flip_h else Vector2.RIGHT
	shot_fired.emit(self, dir, maxi(contact_damage, 1))


func _hero_seek_pos() -> Vector2:
	if _game != null and _game.has_method("hero_seek_position"):
		return _game.call("hero_seek_position") as Vector2
	return Vector2.INF


func _advance_attack(delta: float) -> void:
	if _sprite == null or _attack_frames.is_empty():
		_attacking = false
		return
	_attack_accum += maxf(delta, 0.0)
	var step := 1.0 / ATTACK_FPS
	while _attacking and _attack_accum >= step:
		_attack_accum -= step
		_attack_index += 1
		_try_emit_shot()
		if _attack_index >= _attack_frames.size():
			_attacking = false
			_shot_pending = false
			if not _walk_frames.is_empty():
				_sprite.texture = _walk_frames[_walk_index]
			return
		_sprite.texture = _attack_frames[_attack_index]


func _advance_walk(travel: float, direction: Vector2) -> void:
	if _sprite == null:
		return
	if absf(direction.x) > 0.08:
		_sprite.flip_h = direction.x < 0.0
	if _attacking or _walk_frames.is_empty():
		return
	_walk_accum += maxf(travel, 0.0)
	while _walk_accum >= _walk_step:
		_walk_accum -= _walk_step
		_walk_index = (_walk_index + 1) % _walk_loop_len()
		_sprite.texture = _walk_frames[_walk_index]

func _walk_loop_len() -> int:
	var count := _walk_frames.size()
	if count >= 3:
		return count - 1
	return maxi(count, 1)

func _reach_base() -> void:
	if not _is_active:
		return
	_is_active = false
	reached_base.emit(self)
	queue_free()

## Applies damage and keeps the source available for feedback and analytics.
func take_damage(amount: int, source: StringName = &"tower") -> void:
	if not _is_active:
		return
	var safe_amount := maxi(amount, 0)
	health = maxi(health - safe_amount, 0)
	_flash_time = 0.10
	hit.emit(self, safe_amount, source)
	queue_redraw()
	if health <= 0:
		_begin_defeat()

func _begin_defeat() -> void:
	if _dying:
		return
	_is_active = false
	_attacking = false
	_contact_pending = false
	_shot_pending = false
	_dying = true
	_die_left = DIE_TIME
	defeated.emit(self, reward)
	queue_redraw()

func _advance_defeat(delta: float) -> void:
	_die_left -= delta
	if _sprite != null:
		var t := clampf(_die_left / DIE_TIME, 0.0, 1.0)
		_sprite.modulate = Color(1.0, 0.82, 0.72, t)
		_sprite.scale = _rest_scale * Vector2(1.0 + (1.0 - t) * 0.28, maxf(0.18, t))
	queue_redraw()
	if _die_left <= 0.0:
		queue_free()

func is_active() -> bool:
	return _is_active

func hurt_center() -> Vector2:
	var offset := _hurt_offset
	if _sprite != null and _sprite.flip_h:
		offset.x = -offset.x
	return global_position + offset

func hurt_radius() -> float:
	return _hurt_radius

func hurt_gap(point: Vector2) -> float:
	return point.distance_to(hurt_center()) - _hurt_radius

func apply_slow(factor: float, duration: float) -> void:
	if not _is_active:
		return
	var applied := 0.80 if variant == &"boss" else factor
	if _slow_left <= 0.0 or applied < _slow_factor:
		_slow_factor = applied
	_slow_left = maxf(_slow_left, duration)

func _effective_speed() -> float:
	return move_speed * _slow_factor if _slow_left > 0.0 else move_speed

func get_display_name() -> String:
	match variant:
		&"boss":
			return "前线主宰"
		&"brute":
			return "重装敌人"
		&"mage":
			return "余烬术士"
		&"runner":
			return "烬翼斥候"
		_:
			return "侦察敌人"

func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "EnemySprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_walk_frames.clear()
	var stem := "scout"
	if variant == &"boss":
		stem = "boss"
		_sprite.scale = Vector2(0.70, 0.70)
		_sprite.position = Vector2(0.0, -78.0)
		_walk_step = 16.0
	elif variant == &"brute":
		stem = "brute"
		_sprite.scale = Vector2(0.58, 0.58)
		_sprite.position = Vector2(0.0, -38.0)
		_walk_step = 15.0
	elif variant == &"mage":
		stem = "mage"
		_sprite.scale = Vector2(0.37, 0.37)
		_sprite.position = Vector2(0.0, -48.0)
		_walk_step = 13.0
	elif variant == &"runner":
		stem = "runner"
		_sprite.scale = Vector2(0.29, 0.29)
		_sprite.position = Vector2(0.0, -37.0)
		_walk_step = 9.0
	else:
		_sprite.scale = Vector2(0.65, 0.65)
		_sprite.position = Vector2(0.0, -30.0)
		_walk_step = 11.0
	for index: int in range(16):
		var frame_path := "res://assets/generated/enemies/%s-walk-%d.png" % [stem, index]
		if ResourceLoader.exists(frame_path):
			_walk_frames.append(load(frame_path) as Texture2D)
		var attack_path := "res://assets/generated/enemies/%s-attack-%d.png" % [stem, index]
		if ResourceLoader.exists(attack_path):
			_attack_frames.append(load(attack_path) as Texture2D)
	if variant == &"runner" and _walk_frames.size() >= 3:
		_walk_frames.remove_at(0)
	if _walk_frames.is_empty():
		_sprite.texture = load("res://assets/generated/enemies/%s.png" % stem) as Texture2D
	else:
		_sprite.texture = _walk_frames[0]
	add_child(_sprite)
	_cache_visual_geometry()

func _variant_hurt_floor() -> float:
	match variant:
		&"boss":
			return 42.0
		&"brute":
			return 32.0
		&"mage":
			return 28.0
		&"runner":
			return 24.0
		_:
			return 26.0

## Pins feet from walk frames so slash FX does not lift the health bar.
func _cache_visual_geometry() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	var visual_bounds := Rect2i()
	var has_visual_bounds := false
	var visual_frames: Array[Texture2D] = []
	visual_frames.append_array(_walk_frames)
	if visual_frames.is_empty():
		visual_frames.append_array(_attack_frames)
	if visual_frames.is_empty():
		visual_frames.append(_sprite.texture)
	for frame: Texture2D in visual_frames:
		var used := _texture_used_rect(frame)
		if used.size.x < 1 or used.size.y < 1:
			continue
		visual_bounds = used if not has_visual_bounds else visual_bounds.merge(used)
		has_visual_bounds = true
	if has_visual_bounds:
		var canvas_height := float(_sprite.texture.get_height())
		var scale_y := absf(_sprite.scale.y)
		_sprite.position.y = -(float(visual_bounds.end.y) - canvas_height * 0.5) * scale_y
		_visual_top = _sprite.position.y + (float(visual_bounds.position.y) - canvas_height * 0.5) * scale_y
	_rest_scale = _sprite.scale
	_rest_sprite_y = _sprite.position.y
	_cache_hurtbox()

## Returns the non-transparent texture bounds, or an empty rectangle when pixels are unavailable.
func _texture_used_rect(texture: Texture2D) -> Rect2i:
	if texture == null:
		return Rect2i()
	var image := texture.get_image()
	if image == null:
		return Rect2i()
	if image.is_compressed() and image.decompress() != OK:
		return Rect2i()
	return image.get_used_rect()

## Caches a circular target area from the visible pixels of the reference walk frame.
func _cache_hurtbox() -> void:
	_hurt_radius = _variant_hurt_floor()
	_hurt_offset = Vector2(0.0, _rest_sprite_y)
	if _sprite == null or _sprite.texture == null:
		return
	var used := _texture_used_rect(_sprite.texture)
	if used.size.x < 1.0 or used.size.y < 1.0:
		return
	var sx := absf(_sprite.scale.x)
	var sy := absf(_sprite.scale.y)
	var mid := Vector2(used.position) + Vector2(used.size) * 0.5
	var local := Vector2(
		(mid.x - float(_sprite.texture.get_width()) * 0.5) * sx,
		(mid.y - float(_sprite.texture.get_height()) * 0.5) * sy
	)
	_hurt_offset = _sprite.position + local
	var hw := used.size.x * 0.5 * sx
	var hh := used.size.y * 0.5 * sy
	_hurt_radius = maxf(_hurt_radius, minf(hw, hh) * 0.90)

func _draw() -> void:
	var is_boss := variant == &"boss"
	var is_brute := variant == &"brute"
	var is_mage := variant == &"mage"
	var bar_width := clampf(_hurt_radius * 1.55, 32.0, 62.0)
	var bar_y := _visual_top - 10.0
	var shadow_width := clampf(_hurt_radius * 0.66, 14.0, 32.0)
	draw_shadow_ellipse(Vector2(0.0, 3.0), Vector2(shadow_width, maxf(4.0, shadow_width * 0.22)), Color(0.01, 0.02, 0.06, 0.58))
	draw_rect(Rect2(-bar_width * 0.5 - 2.0, bar_y - 2.0, bar_width + 4.0, 7.0), Color(0.01, 0.02, 0.06, 0.88))
	var health_ratio := clampf(float(health) / float(maxi(max_health, 1)), 0.0, 1.0)
	var bar_color := Color("#ff6a4a") if is_boss else Color("#ffb24f") if is_brute else Color("#c084fc") if is_mage else Color("#f36eb5")
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width * health_ratio, 3.0), bar_color)
	draw_line(Vector2(-bar_width * 0.5, bar_y + 4.0), Vector2(bar_width * 0.5, bar_y + 4.0), Color(0.40, 0.73, 0.76, 0.35), 1.0)

func draw_shadow_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

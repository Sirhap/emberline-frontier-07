class_name HeroProjectile
extends Node2D

## Directional hero bullet. Hits the first live enemy whose body is within hit_radius.

var damage := 18
var speed := 700.0
var max_range := 420.0
var falloff_range := 420.0
var falloff_damage := 18
var _direction := Vector2.RIGHT
var _traveled := 0.0
var _game: Node
var _sprite: Sprite2D
var _spent := false
var _sprite_scale := 0.22
var hit_radius := 16.0


func configure(
	direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float,
	new_falloff_range: float,
	new_falloff_damage: int,
	game: Node,
	texture_path: String,
	sprite_scale: float = 0.22,
	new_hit_radius: float = 16.0
) -> void:
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	damage = new_damage
	speed = new_speed
	max_range = new_max_range
	falloff_range = new_falloff_range
	falloff_damage = new_falloff_damage
	_game = game
	_spent = false
	_traveled = 0.0
	_sprite_scale = sprite_scale
	hit_radius = new_hit_radius
	visible = true
	set_process(true)
	rotation = _direction.angle()
	if _sprite == null:
		_build_sprite(texture_path)
	else:
		_sprite.texture = load(texture_path) as Texture2D
		_sprite.scale = Vector2(_sprite_scale, _sprite_scale)


func reset() -> void:
	_spent = false
	_traveled = 0.0
	_direction = Vector2.RIGHT
	hit_radius = 16.0
	visible = false
	set_process(false)


func _build_sprite(texture_path: String) -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "HeroBulletSprite"
	_sprite.texture = load(texture_path) as Texture2D
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(_sprite_scale, _sprite_scale)
	add_child(_sprite)


func _process(delta: float) -> void:
	if _spent:
		return
	var step := speed * delta
	global_position += _direction * step
	_traveled += step
	var hit := _first_enemy_in_radius(hit_radius)
	if hit != null:
		var applied := falloff_damage if _traveled > falloff_range else damage
		hit.take_damage(applied, &"hero")
		if _game != null:
			_game.spawn_hit_effect(hit.hurt_center(), 0.16)
		_spent = true
		_retire()
		return
	if _traveled >= max_range:
		_retire()


func _retire() -> void:
	if _game != null and _game.has_method("recycle_bullet"):
		_game.call("recycle_bullet", self)
		return
	queue_free()


func _first_enemy_in_radius(radius: float) -> FrontierEnemy:
	if _game == null or not _game.has_method("get_active_enemies"):
		return null
	var closest: FrontierEnemy
	var closest_distance := radius
	for enemy: FrontierEnemy in _game.get_active_enemies():
		var gap := enemy.hurt_gap(global_position)
		if gap <= closest_distance:
			closest = enemy
			closest_distance = gap
	return closest

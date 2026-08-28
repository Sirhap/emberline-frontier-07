class_name EnemyProjectile
extends Node2D

## Directional enemy bullet. Hits the hero; recycled through the shared FIFO 120 pool.

var damage := 10
var speed := 380.0
var max_range := 420.0
var hit_radius := 18.0
var _direction := Vector2.RIGHT
var _traveled := 0.0
var _game: Node
var _sprite: Sprite2D
var _spent := false
var _sprite_scale := 0.40


func configure(
	direction: Vector2,
	new_damage: int,
	game: Node,
	texture_path: String = "res://assets/generated/fx/projectile.png",
	sprite_scale: float = 0.40,
	new_speed: float = 380.0,
	new_max_range: float = 420.0,
	new_hit_radius: float = 18.0
) -> void:
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	damage = maxi(new_damage, 1)
	speed = new_speed
	max_range = new_max_range
	hit_radius = new_hit_radius
	_game = game
	_spent = false
	_traveled = 0.0
	_sprite_scale = sprite_scale
	visible = true
	set_process(true)
	rotation = _direction.angle()
	if _sprite == null:
		_build_sprite(texture_path)
	else:
		_sprite.texture = load(texture_path) as Texture2D
		_sprite.scale = Vector2(_sprite_scale, _sprite_scale)
	if _sprite != null:
		_sprite.modulate = Color(0.78, 0.48, 1.0, 1.0)


func reset() -> void:
	_spent = false
	_traveled = 0.0
	_direction = Vector2.RIGHT
	hit_radius = 18.0
	visible = false
	set_process(false)


func _build_sprite(texture_path: String) -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "EnemyBulletSprite"
	_sprite.texture = load(texture_path) as Texture2D
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(_sprite_scale, _sprite_scale)
	_sprite.modulate = Color(0.78, 0.48, 1.0, 1.0)
	add_child(_sprite)


func _process(delta: float) -> void:
	if _spent:
		return
	var step := speed * delta
	global_position += _direction * step
	_traveled += step
	if _hits_hero():
		if _game != null and _game.has_method("hurt_hero"):
			_game.call("hurt_hero", damage, global_position)
		_spent = true
		_retire()
		return
	if _traveled >= max_range:
		_retire()


func _hits_hero() -> bool:
	if _game == null or not _game.has_method("hero_seek_position"):
		return false
	var hero_pos: Vector2 = _game.call("hero_seek_position") as Vector2
	if not hero_pos.is_finite():
		return false
	return global_position.distance_to(hero_pos) <= hit_radius + 16.0


func _retire() -> void:
	if _game != null and _game.has_method("recycle_bullet"):
		_game.call("recycle_bullet", self)
		return
	queue_free()

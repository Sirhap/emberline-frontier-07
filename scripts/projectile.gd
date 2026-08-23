class_name EmberProjectile
extends Node2D

var target: FrontierEnemy
var damage := 24
var speed := 620.0
var splash_radius := 0.0
var splash_ratio := 0.0
var slow_factor := 1.0
var slow_duration := 0.0
var _game: Node
var _sprite: Sprite2D
var _trail: Array[Vector2] = []

func configure(new_target: FrontierEnemy, new_damage: int, game: Node) -> void:
	target = new_target
	damage = new_damage
	_game = game

func set_burst(radius: float, ratio: float) -> void:
	splash_radius = radius
	splash_ratio = ratio

func set_frost(factor: float, duration: float) -> void:
	slow_factor = factor
	slow_duration = duration

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "ProjectileSprite"
	_sprite.texture = load("res://assets/generated/fx/projectile.png") as Texture2D
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(0.18, 0.18)
	add_child(_sprite)

func reset() -> void:
	target = null
	damage = 24
	splash_radius = 0.0
	splash_ratio = 0.0
	slow_factor = 1.0
	slow_duration = 0.0
	_trail.clear()
	visible = false
	set_process(false)


func _retire() -> void:
	if _game != null and _game.has_method("recycle_bullet"):
		_game.call("recycle_bullet", self)
		return
	queue_free()


func _process(delta: float) -> void:
	if not is_instance_valid(target) or not target.is_active():
		_retire()
		return
	var target_position := target.global_position + Vector2(0.0, -18.0)
	var direction := global_position.direction_to(target_position)
	_trail.push_front(global_position)
	if _trail.size() > 5:
		_trail.pop_back()
	global_position += direction * speed * delta
	if _sprite != null:
		_sprite.rotation = direction.angle() + PI
	if global_position.distance_to(target_position) <= 18.0:
		target.take_damage(damage, &"tower")
		if slow_duration > 0.0:
			target.apply_slow(slow_factor, slow_duration)
		if _game != null:
			if splash_radius > 0.0:
				_game.apply_splash(target, splash_radius, int(floor(float(damage) * splash_ratio)), &"tower")
			_game.spawn_hit_effect(target.global_position, 0.16)
		_retire()
		return
	queue_redraw()

func _draw() -> void:
	for index: int in range(_trail.size()):
		var alpha := 0.28 * (1.0 - float(index) / 6.0)
		draw_circle(to_local(_trail[index]), maxf(1.5, 3.5 - float(index) * 0.45), Color(0.20, 0.94, 0.92, alpha))


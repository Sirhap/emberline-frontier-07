class_name EmberPickup
extends Node2D

signal collected(pickup: EmberPickup)

const PICKUP_RADIUS := 28.0
const LIFETIME := 20.0

var pickup_kind: StringName = &"weapon"
var payload: StringName = &"pistol"
var scrap_value := 0
var _life_left := LIFETIME
var _sprite: Sprite2D


func configure(
	kind: StringName,
	new_payload: StringName,
	texture_path: String,
	sprite_scale: float = 0.36,
	new_scrap_value: int = 0,
	lifetime: float = LIFETIME
) -> void:
	pickup_kind = kind
	payload = new_payload
	scrap_value = new_scrap_value
	_life_left = lifetime
	_sprite = Sprite2D.new()
	_sprite.name = "PickupSprite"
	_sprite.texture = load(texture_path) as Texture2D
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(sprite_scale, sprite_scale)
	_sprite.position = Vector2(0.0, -10.0)
	add_child(_sprite)


func _process(delta: float) -> void:
	_life_left -= delta
	if _sprite != null:
		_sprite.position.y = -10.0 + sin(Time.get_ticks_msec() * 0.008) * 4.0
		_sprite.rotation = sin(Time.get_ticks_msec() * 0.005) * 0.25
		_sprite.modulate.a = 1.0 if _life_left > 3.0 else maxf(_life_left / 3.0, 0.2)
	if _life_left <= 0.0:
		queue_free()
	queue_redraw()


func try_collect(hero_position: Vector2) -> bool:
	if global_position.distance_to(hero_position) > PICKUP_RADIUS:
		return false
	collected.emit(self)
	queue_free()
	return true


func _draw() -> void:
	draw_circle(Vector2(0.0, 8.0), 11.0, Color(0.98, 0.82, 0.32, 0.16))
	draw_arc(Vector2(0.0, 8.0), 14.0, 0.0, TAU, 20, Color(0.98, 0.82, 0.32, 0.55), 1.5)

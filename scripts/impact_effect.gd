class_name ImpactEffect
extends Node2D

## Short-lived pixel burst used for projectile hits, hero strikes, and core damage.

var _sprite: Sprite2D
var _duration := 0.28
var _elapsed := 0.0
var _base_scale := Vector2.ONE
var _texture_path := "res://assets/generated/fx/hit-burst.png"
var _lead_forward := false

func configure(scale_factor: float = 0.18, duration: float = 0.28, texture_path: String = "", lead_forward: bool = false) -> void:
	_base_scale = Vector2.ONE * scale_factor
	_duration = maxf(duration, 0.08)
	_lead_forward = lead_forward
	if not texture_path.is_empty():
		_texture_path = texture_path
	_apply_sprite()

func _ready() -> void:
	_apply_sprite()

func _apply_sprite() -> void:
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "HitBurstSprite"
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_sprite)
	_sprite.texture = load(_texture_path) as Texture2D
	_sprite.scale = _base_scale
	_sprite.centered = true
	_sprite.offset = Vector2.ZERO
	if _lead_forward and _sprite.texture != null:
		# Whole crescent sits on +X of the pivot, so it leads the blade.
		_sprite.offset = Vector2(float(_sprite.texture.get_width()) * 0.42, 0.0)

func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	if _sprite != null:
		_sprite.scale = _base_scale * (0.76 + progress * 0.44)
		_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - progress)
	if progress >= 1.0:
		queue_free()

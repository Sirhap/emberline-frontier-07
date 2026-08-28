class_name EmberPickup
extends Node2D

signal collected(pickup: EmberPickup)
signal expired(pickup: EmberPickup)

const PICKUP_RADIUS := 28.0
const INTERACT_RADIUS := 48.0
const CLICK_RADIUS := 36.0
## Ground drops wait this long, then go to 仓库 instead of vanishing.
const LIFETIME := 20.0

const UiFont := preload("res://scripts/ember_ui_font.gd")

var pickup_kind: StringName = &"weapon"
var payload: StringName = &"pistol"
var scrap_value := 0
var _life_left := LIFETIME
var _sprite: Sprite2D
var _caption: Label
var _targeted := false
var _resolved := false


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
	var fitted := sprite_scale
	if _sprite.texture != null:
		var longest := maxf(float(_sprite.texture.get_width()), float(_sprite.texture.get_height()))
		if longest > 1.0:
			var shown := longest * sprite_scale
			var max_shown := 64.0 if kind == &"scrap" else 36.0
			var min_shown := 52.0 if kind == &"scrap" else 22.0
			if shown > max_shown:
				fitted = max_shown / longest
			elif shown < min_shown:
				fitted = min_shown / longest
	_sprite.scale = Vector2(fitted, fitted)
	_sprite.position = Vector2(0.0, -10.0)
	add_child(_sprite)
	if kind == &"scrap":
		_caption = Label.new()
		_caption.name = "PickupCaption"
		_caption.text = "+%d 废料" % maxi(scrap_value, 0)
		_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_caption.position = Vector2(-48.0, 16.0)
		_caption.size = Vector2(96.0, 20.0)
		_caption.add_theme_font_override("font", UiFont.bundled())
		_caption.add_theme_font_size_override("font_size", 13)
		_caption.add_theme_color_override("font_color", Color("#ffe07a"))
		_caption.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.01, 0.95))
		_caption.add_theme_constant_override("outline_size", 5)
		_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_caption)


func _process(delta: float) -> void:
	if _resolved:
		return
	_life_left -= delta
	if _sprite != null:
		var bob := 6.0 if pickup_kind == &"scrap" else 4.0
		_sprite.position.y = -10.0 + sin(Time.get_ticks_msec() * 0.008) * bob
		_sprite.rotation = sin(Time.get_ticks_msec() * 0.005) * (0.18 if pickup_kind == &"scrap" else 0.25)
		_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if _targeted:
			_sprite.modulate = Color(1.12, 1.08, 0.82)
	if _caption != null:
		_caption.position.y = 16.0 + sin(Time.get_ticks_msec() * 0.008) * 2.0
	if _life_left <= 0.0:
		stash_away()
		return
	queue_redraw()


## Walk-over no longer collects. Kept as a radius probe so old callers cannot vacuum.
func try_collect(hero_position: Vector2) -> bool:
	return global_position.distance_to(hero_position) <= INTERACT_RADIUS


func collect_now() -> bool:
	if _resolved:
		return false
	_resolved = true
	collected.emit(self)
	queue_free()
	return true


func stash_away() -> bool:
	if _resolved:
		return false
	_resolved = true
	expired.emit(self)
	queue_free()
	return true


func set_targeted(on: bool) -> void:
	_targeted = on
	queue_redraw()


func is_targeted() -> bool:
	return _targeted


func _draw() -> void:
	var is_scrap := pickup_kind == &"scrap"
	var glow := Color(1.0, 0.86, 0.28, 0.50) if is_scrap else Color(0.98, 0.82, 0.32, 0.16)
	var ring := Color(1.0, 0.94, 0.42, 0.95) if is_scrap else Color(0.98, 0.82, 0.32, 0.55)
	var radius := 18.0 if is_scrap else 11.0
	draw_circle(Vector2(0.0, 8.0), radius, glow)
	draw_arc(Vector2(0.0, 8.0), radius + 5.0, 0.0, TAU, 24, ring, 2.6 if is_scrap else 1.5)
	if _targeted:
		draw_arc(Vector2(0.0, 8.0), radius + 11.0, 0.0, TAU, 24, Color(1.0, 0.97, 0.62, 1.0), 3.2)

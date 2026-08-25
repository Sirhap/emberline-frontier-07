class_name SpawnPortal
extends Node2D

## Looping vortex at a north/south/east enemy mouth.

const FRAME_COUNT := 8
const FPS := 10.0
# Main applies a 0.62 world scale; this keeps the visible vortex near 147 px tall.
const VISUAL_SCALE := 0.42

var _sprite: Sprite2D
var _frames: Array[Texture2D] = []
var _accum := 0.0
var _index := 0
var hole_active := true

func set_hole_active(on: bool) -> void:
	hole_active = on
	modulate = Color.WHITE if on else Color(0.42, 0.32, 0.55, 0.72)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite = Sprite2D.new()
	_sprite.name = "PortalSprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	for index: int in range(FRAME_COUNT):
		var path := "res://assets/generated/fx/portal/frame_%d.png" % index
		var tex := load(path) as Texture2D
		if tex == null:
			var img := Image.new()
			if img.load(ProjectSettings.globalize_path(path)) == OK:
				tex = ImageTexture.create_from_image(img)
		if tex != null:
			_frames.append(tex)
	if not _frames.is_empty():
		_sprite.texture = _frames[0]
	add_child(_sprite)

func _process(delta: float) -> void:
	if _frames.size() < 2:
		return
	_accum += delta
	var step := 1.0 / FPS
	while _accum >= step:
		_accum -= step
		_index = (_index + 1) % _frames.size()
		_sprite.texture = _frames[_index]

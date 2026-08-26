class_name SpawnPortal
extends Node2D

## Vortex in a wall-hole arch. Inactive holes show a sealed stone plug.

const FRAME_COUNT := 8
const FPS := 10.0
const VISUAL_SCALE := 0.28
const ARCH_PATH := "res://assets/generated/fx/portal/arch.png"
const SEALED_PATH := "res://assets/generated/fx/portal/sealed.png"

var _sprite: Sprite2D
var _arch: Sprite2D
var _sealed: Sprite2D
var _frames: Array[Texture2D] = []
var _accum := 0.0
var _index := 0
var hole_active := true

func set_hole_active(on: bool) -> void:
	hole_active = on
	modulate = Color.WHITE
	if _sprite != null:
		_sprite.visible = on
	if _sealed != null:
		_sealed.visible = not on

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_arch = Sprite2D.new()
	_arch.name = "PortalArch"
	_arch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_arch.texture = _load_tex(ARCH_PATH)
	_arch.scale = Vector2(1.35, 1.35)
	_arch.z_index = -1
	add_child(_arch)
	_sprite = Sprite2D.new()
	_sprite.name = "PortalSprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(0.26, 0.26)
	for index: int in range(FRAME_COUNT):
		var tex := _load_tex("res://assets/generated/fx/portal/frame_%d.png" % index)
		if tex != null:
			_frames.append(tex)
	if not _frames.is_empty():
		_sprite.texture = _frames[0]
	add_child(_sprite)
	_sealed = Sprite2D.new()
	_sealed.name = "PortalSealed"
	_sealed.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sealed.texture = _load_tex(SEALED_PATH)
	_sealed.scale = Vector2(1.28, 1.28)
	_sealed.visible = false
	add_child(_sealed)

func _load_tex(path: String) -> Texture2D:
	var tex := load(path) as Texture2D
	if tex != null:
		return tex
	var img := Image.new()
	if img.load(ProjectSettings.globalize_path(path)) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _process(delta: float) -> void:
	if not hole_active or _frames.size() < 2:
		return
	_accum += delta
	var step := 1.0 / FPS
	while _accum >= step:
		_accum -= step
		_index = (_index + 1) % _frames.size()
		_sprite.texture = _frames[_index]

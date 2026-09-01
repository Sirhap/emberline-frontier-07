class_name HomeRoom
extends Node2D

## Home-only visual layer. The furnished hall is baked into floor-room.png.

const HOME_DIR := "res://assets/generated/home/"


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fill_void()
	_stamp_floor()


func _fill_void() -> void:
	var void_rect := ColorRect.new()
	void_rect.name = "Void"
	void_rect.position = Vector2.ZERO
	void_rect.size = Vector2(1280, 720)
	void_rect.color = Color("07080c")
	void_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	void_rect.z_index = -2
	add_child(void_rect)


func _stamp_floor() -> void:
	var floor := Sprite2D.new()
	floor.name = "Floor"
	floor.texture = load(HOME_DIR + "floor-room.png") as Texture2D
	floor.centered = true
	floor.position = Vector2(640, 360)
	floor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	floor.z_index = 0
	if floor.texture != null:
		floor.scale = Vector2(1280.0 / float(floor.texture.get_width()), 720.0 / float(floor.texture.get_height()))
	add_child(floor)

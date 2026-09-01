class_name HomeRoom
extends Node2D

## Empty hall + the user's office sprites. Never farm furniture, never the whole layout-ref.

const HOME_DIR := "res://assets/generated/home/"
const MANIFEST_PATH := "res://assets/generated/home/office-manifest.json"

const CODER_POS := Vector2(620, 344)
const PLANT_POS := Vector2(348, 96)
const FRIDGE_POS := Vector2(888, 98)
const COFFEE_POS := Vector2(1148, 268)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fill_void()
	_stamp_floor()
	_stamp_pack_furniture()
	_stamp_office_furniture()


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
	var floor := _sprite("Floor", HOME_DIR + "floor-room.png", Vector2(640, 360), 720.0)
	floor.z_index = 0
	var tex: Texture2D = floor.texture
	if tex != null:
		floor.scale = Vector2(1280.0 / float(tex.get_width()), 720.0 / float(tex.get_height()))


func _stamp_pack_furniture() -> void:
	_sprite("Plant", HOME_DIR + "plant.png", PLANT_POS, 67.0).z_index = 2
	_sprite("Fridge", HOME_DIR + "vending.png", FRIDGE_POS, 140.0).z_index = 2
	_sprite("CoderDesk", HOME_DIR + "desk-coder.png", CODER_POS, 220.0).z_index = 2
	_sprite("Coffee", HOME_DIR + "coffee.png", COFFEE_POS, 129.0).z_index = 2


func _stamp_office_furniture() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return
	for item: Variant in parsed:
		if not item is Dictionary:
			continue
		var spec: Dictionary = item
		var sprite := Sprite2D.new()
		sprite.name = String(spec.get("name", "Prop"))
		sprite.texture = load(HOME_DIR + String(spec.get("file", ""))) as Texture2D
		sprite.centered = true
		sprite.position = Vector2(float(spec.get("x", 0.0)), float(spec.get("y", 0.0)))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 2
		add_child(sprite)


func _sprite(node_name: String, path: String, pos: Vector2, target_h: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(path) as Texture2D
	sprite.centered = true
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if sprite.texture != null and sprite.texture.get_height() > 0:
		var sc := target_h / float(sprite.texture.get_height())
		sprite.scale = Vector2(sc, sc)
	add_child(sprite)
	return sprite

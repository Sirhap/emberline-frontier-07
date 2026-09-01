class_name HomeRoom
extends Node2D

## Empty industrial hall. Clean pack sprites stamped like the layout reference.

const HOME_DIR := "res://assets/generated/home/"

const PLANT_POS := Vector2(348, 96)
const FRIDGE_POS := Vector2(888, 98)
const WORKBENCH_POS := Vector2(980, 94)
const MONUMENT_POS := Vector2(1068, 90)
const CODER_POS := Vector2(620, 344)
const BESTIARY_POS := Vector2(180, 390)
const COFFEE_POS := Vector2(1148, 268)
const CHICKEN_POS := Vector2(976, 367)
const BULL_POS := Vector2(298, 478)
const FLOOR_PLANT_POS := Vector2(582, 589)
const PET_NEST_POS := Vector2(233, 635)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fill_void()
	_stamp_floor()
	_stamp_furniture()


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


func _stamp_furniture() -> void:
	_sprite("Plant", HOME_DIR + "plant.png", PLANT_POS, 67.0).z_index = 2
	_sprite("Fridge", HOME_DIR + "vending.png", FRIDGE_POS, 140.0).z_index = 2
	_sprite("Bookshelf", HOME_DIR + "bookshelf.png", WORKBENCH_POS, 150.0).z_index = 2
	_sprite("Monument", HOME_DIR + "monument.png", MONUMENT_POS, 140.0).z_index = 2
	_sprite("CoderDesk", HOME_DIR + "desk-coder.png", CODER_POS, 220.0).z_index = 2
	_sprite("Bestiary", HOME_DIR + "bestiary.png", BESTIARY_POS, 160.0).z_index = 2
	_sprite("Coffee", HOME_DIR + "coffee.png", COFFEE_POS, 129.0).z_index = 2
	_sprite("Chicken", HOME_DIR + "rubber-chicken.png", CHICKEN_POS, 150.0).z_index = 2
	_sprite("Bull", HOME_DIR + "cow-plush.png", BULL_POS, 140.0).z_index = 2
	_sprite("FloorPlant", HOME_DIR + "plant.png", FLOOR_PLANT_POS, 70.0).z_index = 2
	_sprite("PetBed", HOME_DIR + "sofa.png", PET_NEST_POS, 120.0).z_index = 2


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

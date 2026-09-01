class_name HomeRoom
extends Node2D

## Home-only visual layer. Never loads combat battlefield textures.

const HOME_DIR := "res://assets/generated/home/"
const PORTAL_ARCH := "res://assets/generated/fx/portal/arch.png"
const PORTAL_VORTEX := "res://assets/generated/fx/portal/frame_0.png"

const PORTAL_POS := Vector2(640, 100)
const KNIGHT_POS := Vector2(500, 575)
const ASSASSIN_POS := Vector2(790, 575)
const WEAPON_CODEX_POS := Vector2(1084, 168)
const ENEMY_CODEX_POS := Vector2(1088, 540)
const RECORDS_POS := Vector2(210, 250)
const PET_NEST_POS := Vector2(210, 520)
const PREVIEW_POS := Vector2(640, 598)
const CODER_POS := Vector2(627, 379)
const WORKBENCH_POS := Vector2(1084, 144)
const COFFEE_POS := Vector2(1090, 425)
const PLANT_POS := Vector2(772, 119)


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
	_sprite("CoderDesk", HOME_DIR + "desk-coder.png", CODER_POS, 220.0).z_index = 2
	_sprite("Bookshelf", HOME_DIR + "workbench.png", WORKBENCH_POS, 153.0).z_index = 2
	_sprite("Coffee", HOME_DIR + "coffee.png", COFFEE_POS, 129.0).z_index = 2
	_sprite("Plant", HOME_DIR + "plant.png", PLANT_POS, 67.0).z_index = 2
	_sprite("Bestiary", HOME_DIR + "vending.png", ENEMY_CODEX_POS + Vector2(0, -18), 150.0).z_index = 2
	_sprite("Monument", HOME_DIR + "tech-pad.png", RECORDS_POS + Vector2(0, -8), 88.0).z_index = 2
	_sprite("PetBed", HOME_DIR + "rubber-chicken.png", PET_NEST_POS + Vector2(0, -24), 150.0).z_index = 2
	_sprite("KnightPlinth", HOME_DIR + "tech-pad.png", KNIGHT_POS + Vector2(0, 10), 72.0).z_index = 2
	_sprite("AssassinPlinth", HOME_DIR + "tech-pad.png", ASSASSIN_POS + Vector2(0, 10), 72.0).z_index = 2
	_stamp_portal()


func _stamp_portal() -> void:
	var portal := Node2D.new()
	portal.name = "PortalVisual"
	portal.position = PORTAL_POS
	portal.z_index = 3
	add_child(portal)
	var arch := Sprite2D.new()
	arch.name = "Arch"
	arch.texture = load(PORTAL_ARCH) as Texture2D
	arch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arch.scale = Vector2(1.15, 1.15)
	arch.position = Vector2(0.0, 8.0)
	portal.add_child(arch)
	var vortex := Sprite2D.new()
	vortex.name = "Vortex"
	vortex.texture = load(PORTAL_VORTEX) as Texture2D
	vortex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vortex.scale = Vector2(0.22, 0.22)
	vortex.position = Vector2(0.0, -4.0)
	portal.add_child(vortex)


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

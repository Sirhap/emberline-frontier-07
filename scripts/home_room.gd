class_name HomeRoom
extends Node2D

## Home-only visual layer. Never loads combat battlefield textures.

const HOME_DIR := "res://assets/generated/home/"
const PORTAL_ARCH := "res://assets/generated/fx/portal/arch.png"
const PORTAL_VORTEX := "res://assets/generated/fx/portal/frame_0.png"

const ROOM := Rect2(96, 72, 1088, 568)
const PORTAL_POS := Vector2(640, 118)
const KNIGHT_POS := Vector2(480, 520)
const ASSASSIN_POS := Vector2(620, 520)
const WEAPON_CODEX_POS := Vector2(1040, 245)
const ENEMY_CODEX_POS := Vector2(1040, 405)
const RECORDS_POS := Vector2(220, 245)
const PET_NEST_POS := Vector2(220, 475)
const PREVIEW_POS := Vector2(640, 355)


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
	void_rect.color = Color("070604")
	void_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	void_rect.z_index = -2
	add_child(void_rect)


func _stamp_floor() -> void:
	var floor := _sprite("Floor", HOME_DIR + "floor-room.png", Vector2(640, 360), 720.0)
	floor.z_index = 0
	# Fill the 1280x720 view; slight non-uniform scale is acceptable for a menu hall.
	var tex: Texture2D = floor.texture
	if tex != null:
		floor.scale = Vector2(1280.0 / float(tex.get_width()), 720.0 / float(tex.get_height()))


func _stamp_furniture() -> void:
	_sprite("Rug", HOME_DIR + "rug.png", PREVIEW_POS + Vector2(0, 8), 168.0).z_index = 1
	_sprite("Table", HOME_DIR + "table.png", PREVIEW_POS + Vector2(0, -6), 88.0).z_index = 2
	_sprite("Bookshelf", HOME_DIR + "bookshelf.png", WEAPON_CODEX_POS + Vector2(0, -18), 150.0).z_index = 2
	_sprite("Bestiary", HOME_DIR + "bestiary.png", ENEMY_CODEX_POS + Vector2(0, -10), 150.0).z_index = 2
	_sprite("Monument", HOME_DIR + "monument.png", RECORDS_POS + Vector2(0, -16), 150.0).z_index = 2
	_sprite("PetBed", HOME_DIR + "pet-bed.png", PET_NEST_POS + Vector2(0, 6), 110.0).z_index = 2
	_sprite("KnightPlinth", HOME_DIR + "pedestal.png", KNIGHT_POS + Vector2(0, 6), 58.0).z_index = 2
	_sprite("AssassinPlinth", HOME_DIR + "pedestal.png", ASSASSIN_POS + Vector2(0, 6), 58.0).z_index = 2
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
	arch.scale = Vector2(1.2, 1.2)
	arch.position = Vector2(0.0, 8.0)
	portal.add_child(arch)
	var vortex := Sprite2D.new()
	vortex.name = "Vortex"
	vortex.texture = load(PORTAL_VORTEX) as Texture2D
	vortex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vortex.scale = Vector2(0.22, 0.22)
	vortex.position = Vector2(0.0, -6.0)
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

class_name HomeRoom
extends Node2D

## Home-only visual layer. Never loads combat battlefield textures.

const HOME_DIR := "res://assets/generated/home/"
const PORTAL_ARCH := "res://assets/generated/fx/portal/arch.png"
const PORTAL_VORTEX := "res://assets/generated/fx/portal/frame_0.png"

const ROOM := Rect2(48, 18, 1184, 622)
const PORTAL_POS := Vector2(640, 108)
const KNIGHT_POS := Vector2(500, 580)
const ASSASSIN_POS := Vector2(790, 580)
const WEAPON_CODEX_POS := Vector2(1105, 235)
const ENEMY_CODEX_POS := Vector2(1105, 505)
const RECORDS_POS := Vector2(175, 250)
const PET_NEST_POS := Vector2(175, 520)
const PREVIEW_POS := Vector2(640, 345)


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
	void_rect.color = Color("142010")
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
	_sprite("TreeWest", HOME_DIR + "tree.png", Vector2(78, 78), 150.0).z_index = 2
	_sprite("TreeEast", HOME_DIR + "tree-b.png", Vector2(1204, 78), 150.0).z_index = 2
	_sprite("TreeSouthWest", HOME_DIR + "tree-b.png", Vector2(90, 655), 130.0).z_index = 2
	_sprite("TreeSouthEast", HOME_DIR + "tree.png", Vector2(1190, 655), 130.0).z_index = 2
	_sprite("Rug", HOME_DIR + "rug.png", PREVIEW_POS + Vector2(0, 18), 210.0).z_index = 1
	_sprite("Table", HOME_DIR + "table.png", PREVIEW_POS + Vector2(0, -8), 170.0).z_index = 2
	_sprite("ChairWest", HOME_DIR + "chair.png", PREVIEW_POS + Vector2(-118, 10), 96.0).z_index = 2
	_sprite("ChairEast", HOME_DIR + "chair.png", PREVIEW_POS + Vector2(118, 10), 96.0).z_index = 2
	_sprite("Sofa", HOME_DIR + "sofa.png", Vector2(900, 240), 150.0).z_index = 2
	_sprite("Bookshelf", HOME_DIR + "bookshelf.png", WEAPON_CODEX_POS + Vector2(0, -22), 270.0).z_index = 2
	_sprite("Bestiary", HOME_DIR + "bestiary.png", ENEMY_CODEX_POS + Vector2(0, -12), 250.0).z_index = 2
	_sprite("Monument", HOME_DIR + "monument.png", RECORDS_POS + Vector2(0, -18), 250.0).z_index = 2
	_sprite("PetBed", HOME_DIR + "pet-bed.png", PET_NEST_POS + Vector2(0, 4), 220.0).z_index = 2
	_sprite("KnightPlinth", HOME_DIR + "stone-pad.png", KNIGHT_POS + Vector2(0, 10), 108.0).z_index = 2
	_sprite("AssassinPlinth", HOME_DIR + "stone-pad.png", ASSASSIN_POS + Vector2(0, 10), 108.0).z_index = 2
	_stamp_portal()


func _stamp_portal() -> void:
	var portal := Node2D.new()
	portal.name = "PortalVisual"
	portal.position = PORTAL_POS
	portal.z_index = 3
	add_child(portal)
	var ring := Sprite2D.new()
	ring.name = "StoneRing"
	ring.texture = load(HOME_DIR + "stone-ring.png") as Texture2D
	ring.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ring.centered = true
	ring.position = Vector2(0.0, 36.0)
	if ring.texture != null and ring.texture.get_height() > 0:
		var sc := 96.0 / float(ring.texture.get_height())
		ring.scale = Vector2(sc, sc)
	portal.add_child(ring)
	var arch := Sprite2D.new()
	arch.name = "Arch"
	arch.texture = load(PORTAL_ARCH) as Texture2D
	arch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arch.scale = Vector2(1.55, 1.55)
	arch.position = Vector2(0.0, 10.0)
	portal.add_child(arch)
	var vortex := Sprite2D.new()
	vortex.name = "Vortex"
	vortex.texture = load(PORTAL_VORTEX) as Texture2D
	vortex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vortex.scale = Vector2(0.30, 0.30)
	vortex.position = Vector2(0.0, -8.0)
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

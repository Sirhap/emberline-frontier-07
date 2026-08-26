extends Node2D

const UiFont := preload("res://scripts/ember_ui_font.gd")

## Blit rooms from the combat atlas so shops read as the same dungeon, not debug rects.
const ATLAS_PATH := "res://assets/generated/grid-battlefield-v6.png"
const DOOR_FRAME_PATH := "res://assets/generated/fx/door-frame.png"
const MOUTH_FRAME_PATH := "res://assets/generated/fx/mouth-frame.png"
const WALL_H_TEX_PATH := "res://assets/generated/fx/wall-h.png"
const WALL_V_TEX_PATH := "res://assets/generated/fx/wall-v.png"
const JAMB_L_PATH := "res://assets/generated/fx/door-jamb-l.png"
const JAMB_R_PATH := "res://assets/generated/fx/door-jamb-r.png"
const SX := 1280.0 / 1536.0
const SY := 720.0 / 1024.0
const TILE := 64.0
const FLOOR_SRC := Rect2(384, 320, 256, 256)
const WALL_H_SRC := Rect2(200, 32, 128, 80)
const WALL_V_SRC := Rect2(8, 150, 40, 256)
const JAMB_SRC := Rect2(248, 32, 56, 80)
const WOOD := Color("#3a2a1c")
const WOOD_LIGHT := Color("#6a4a28")
const TRIM := Color("#c4a06a")

var merchant_room := Rect2(108.0, -280.0, 904.0, 296.0)
var trainer_room := Rect2(108.0, -280.0, 904.0, 296.0)
var merchant_door := Rect2(496.0, 16.0, 144.0, 56.0)
var trainer_door := Rect2(496.0, 16.0, 144.0, 56.0)
var north_wall := Rect2(76.0, 16.0, 1010.0, 56.0)
var expand_floors: Array = []
var expand_h_walls: Array = []
var expand_v_walls: Array = []
var extra_doors: Array = []
var east_door := Rect2()
var cover_voids: Array = []
var portal_holes: Array = []
var spawn_hole := Rect2()
var mouth_jambs: Array = []
var shelf_spots: Array[Vector2] = []
var shelf_sold: Array[bool] = []
var shelf_filled: Array[bool] = []
var gate_open := 1.0
var _atlas: Texture2D
var _door_tex: Texture2D
var _mouth_tex: Texture2D
var _wall_h_tex: Texture2D
var _wall_v_tex: Texture2D
var _jamb_l: Texture2D
var _jamb_r: Texture2D
var _door_tex_tried := false
var _label_font_cache: Font
var shelf_captions: Array[String] = []
var bottom_booth := Rect2()
var gate_x_min := 0.0
var gate_x_max := 0.0
var bottom_rail_y := 0.0

var _tile_w := TILE * SX
var _tile_h := TILE * SY
var _grid_ox := SX * 4.0
var _grid_oy := -8.0 + SY * 42.0
var _wall_h := 80.0 * SY
var _wall_v := 40.0 * SX

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_atlas = load(ATLAS_PATH) as Texture2D
	_door_tex = load(DOOR_FRAME_PATH) as Texture2D
	_mouth_tex = load(MOUTH_FRAME_PATH) as Texture2D
	_wall_h_tex = load(WALL_H_TEX_PATH) as Texture2D
	_wall_v_tex = load(WALL_V_TEX_PATH) as Texture2D
	_jamb_l = load(JAMB_L_PATH) as Texture2D
	_jamb_r = load(JAMB_R_PATH) as Texture2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _atlas == null:
		_atlas = load(ATLAS_PATH) as Texture2D
	if _atlas == null:
		return
	for cover: Rect2 in cover_voids:
		if cover.size.x > 1.0 and cover.size.y > 1.0:
			draw_rect(cover, Color("#111318"), true)
	for extra: Rect2 in expand_floors:
		_draw_floor_rect(extra)
	_draw_spawn_hole()
	for wall: Rect2 in expand_h_walls:
		_stamp_h(wall, WALL_H_SRC)
	for wall: Rect2 in expand_v_walls:
		_stamp_v(wall, WALL_V_SRC)
	for door: Rect2 in extra_doors:
		_draw_floor_rect(door)
		_draw_mouth_frame(door)
	_draw_east_door(east_door)
	for jamb: Rect2 in mouth_jambs:
		if jamb.size.y >= jamb.size.x:
			_stamp_v(jamb, JAMB_SRC)
		else:
			_stamp_h(jamb, JAMB_SRC)
	for hole: Rect2 in portal_holes:
		_draw_portal_hole(hole)
		if hole.size.x > hole.size.y:
			_draw_end_portal_frame(hole)
	var hall := merchant_room.merge(trainer_room)
	var door := merchant_door.merge(trainer_door)
	_draw_floor_rect(hall)
	if door.position.y > hall.end.y:
		_draw_floor_rect(Rect2(hall.position.x, hall.end.y, hall.size.x, door.position.y - hall.end.y))
	_draw_floor_rect(door)
	_draw_room_shell(hall, door)
	_draw_shop_south_wall(hall, door)
	_draw_label(hall.position + Vector2(16.0, 36.0), "商人")
	_draw_label(Vector2(hall.end.x - 72.0, hall.position.y + 36.0), "训练师")
	for index: int in range(shelf_spots.size()):
		if index < shelf_filled.size() and not shelf_filled[index]:
			continue
		var sold := index < shelf_sold.size() and shelf_sold[index]
		_draw_crate(shelf_spots[index], sold)
		if index < shelf_captions.size() and not shelf_captions[index].is_empty():
			_draw_label(shelf_spots[index] + Vector2(-28.0, 18.0), shelf_captions[index])

func _draw_floor_rect(area: Rect2) -> void:
	if area.size.x <= 1.0 or area.size.y <= 1.0:
		return
	var x: float = floorf((area.position.x - _grid_ox) / _tile_w) * _tile_w + _grid_ox
	while x < area.end.x:
		var y: float = floorf((area.position.y - _grid_oy) / _tile_h) * _tile_h + _grid_oy
		while y < area.end.y:
			var dest := Rect2(x, y, _tile_w, _tile_h).intersection(area)
			if dest.size.x > 0.5 and dest.size.y > 0.5:
				var ix := posmod(int(floorf((x - _grid_ox) / _tile_w)), 4)
				var iy := posmod(int(floorf((y - _grid_oy) / _tile_h)), 4)
				var src_pos := Vector2(FLOOR_SRC.position.x + float(ix) * TILE, FLOOR_SRC.position.y + float(iy) * TILE)
				var u0: float = (dest.position.x - x) / _tile_w
				var v0: float = (dest.position.y - y) / _tile_h
				var src := Rect2(
					src_pos.x + u0 * TILE,
					src_pos.y + v0 * TILE,
					dest.size.x / _tile_w * TILE,
					dest.size.y / _tile_h * TILE
				)
				draw_texture_rect_region(_atlas, dest, src)
			y += _tile_h
		x += _tile_w

func _draw_room_shell(room: Rect2, door: Rect2 = Rect2()) -> void:
	var south_y := door.position.y if door.size.y > 1.0 else room.end.y
	var wall_top := room.position.y - _wall_h
	var wall_h := south_y + _wall_h - wall_top
	var wv := _tile_w
	var n := Rect2(room.position.x - wv, room.position.y - _wall_h, room.size.x + wv * 2.0, _wall_h)
	var w := Rect2(room.position.x - wv, wall_top, wv, wall_h)
	var e := Rect2(room.end.x, wall_top, wv, wall_h)
	var s := Rect2(room.position.x - wv, south_y, room.size.x + wv * 2.0, _wall_h)
	_stamp_h(n, WALL_H_SRC)
	_stamp_v(w, WALL_V_SRC)
	_stamp_v(e, WALL_V_SRC)
	_stamp_h_with_gap(s, door)

func _draw_spawn_hole() -> void:
	_draw_portal_hole(spawn_hole)

func _stamp_h_with_gap(wall: Rect2, door: Rect2) -> void:
	if door.size.x <= 1.0 or door.size.y <= 1.0:
		_stamp_h(wall, WALL_H_SRC)
		return
	var gap := wall.intersection(Rect2(door.position.x, wall.position.y, door.size.x, wall.size.y))
	if gap.size.x <= 1.0:
		_stamp_h(wall, WALL_H_SRC)
		return
	_stamp_h(Rect2(wall.position, Vector2(gap.position.x - wall.position.x, wall.size.y)), WALL_H_SRC)
	_stamp_h(Rect2(Vector2(gap.end.x, wall.position.y), Vector2(wall.end.x - gap.end.x, wall.size.y)), WALL_H_SRC)

func _draw_shop_south_wall(room: Rect2, door: Rect2) -> void:
	if room.size.x <= 1.0 or door.size.y <= 1.0:
		return
	if _door_tex == null and not _door_tex_tried:
		_door_tex_tried = true
		_door_tex = load(DOOR_FRAME_PATH) as Texture2D
	if _door_tex != null:
		var dest := Rect2(door.position.x - _tile_w, door.position.y, 5.0 * _tile_w, _wall_h)
		draw_texture_rect(_door_tex, dest, false)
	else:
		_draw_atlas_jambs(door)

func _draw_mouth_frame(door: Rect2) -> void:
	if door.size.x <= 1.0:
		return
	if _mouth_tex == null:
		_mouth_tex = load(MOUTH_FRAME_PATH) as Texture2D
	if _mouth_tex != null:
		var dest := Rect2(door.position.x - _tile_w, door.position.y, 7.0 * _tile_w, _wall_h)
		draw_texture_rect(_mouth_tex, dest, false)
	else:
		_draw_atlas_jambs(door)

func _draw_end_portal_frame(hole: Rect2) -> void:
	if _door_tex == null and not _door_tex_tried:
		_door_tex_tried = true
		_door_tex = load(DOOR_FRAME_PATH) as Texture2D
	if _door_tex == null:
		return
	var dest := Rect2(hole.position.x - _tile_w, hole.position.y, 5.0 * _tile_w, _wall_h)
	draw_texture_rect(_door_tex, dest, false)

func _draw_east_door(door: Rect2) -> void:
	if door.size.x <= 1.0 or door.size.y <= 1.0:
		return
	var jamb_w := 16.0
	draw_rect(Rect2(door.position.x + jamb_w, door.position.y, door.size.x - jamb_w * 2.0, door.size.y), Color("#05060a"), true)
	if _jamb_l != null:
		var src_w := float(_jamb_l.get_width())
		var src_h := float(_jamb_l.get_height())
		draw_texture_rect_region(_jamb_l, Rect2(door.position.x, door.position.y, jamb_w, door.size.y), Rect2(src_w - 22.0, 0.0, 22.0, src_h))
	if _jamb_r != null:
		var src_w := float(_jamb_r.get_width())
		var src_h := float(_jamb_r.get_height())
		draw_texture_rect_region(_jamb_r, Rect2(door.end.x - jamb_w, door.position.y, jamb_w, door.size.y), Rect2(0.0, 0.0, 22.0, src_h))
	var cap := 10.0
	if _wall_h_tex != null:
		draw_texture_rect_region(_wall_h_tex, Rect2(door.position.x, door.position.y, door.size.x, cap), Rect2(0.0, 0.0, float(_wall_h_tex.get_width()), 18.0))
		draw_texture_rect_region(_wall_h_tex, Rect2(door.position.x, door.end.y - cap, door.size.x, cap), Rect2(0.0, float(_wall_h_tex.get_height()) - 18.0, float(_wall_h_tex.get_width()), 18.0))

func _draw_portal_hole(hole: Rect2) -> void:
	if hole.size.x <= 1.0 or hole.size.y <= 1.0:
		return
	draw_rect(hole, Color("#05060a"), true)

func _carve_opening(door: Rect2) -> void:
	if _wall_h_tex == null:
		return
	var jamb_w := 14.0
	var cap_h := 8.0
	var src_w := float(_wall_h_tex.get_width())
	var src_h := float(_wall_h_tex.get_height())
	var left := Rect2(door.position.x - jamb_w, door.position.y, jamb_w, _wall_h)
	var right := Rect2(door.end.x, door.position.y, jamb_w, _wall_h)
	var cap := Rect2(door.position.x - jamb_w, door.position.y, door.size.x + jamb_w * 2.0, cap_h)
	draw_texture_rect_region(_wall_h_tex, left, Rect2(0.0, 0.0, 22.0, src_h))
	draw_texture_rect_region(_wall_h_tex, right, Rect2(src_w - 22.0, 0.0, 22.0, src_h))
	draw_texture_rect_region(_wall_h_tex, cap, Rect2(0.0, 0.0, src_w, 14.0))

func _draw_atlas_jambs(door: Rect2) -> void:
	var jamb_w := maxf(_wall_v * 0.90, 22.0)
	_blit(JAMB_SRC, Rect2(door.position.x - jamb_w * 0.45, door.position.y, jamb_w, maxf(door.size.y, _wall_h)))
	_blit(JAMB_SRC, Rect2(door.end.x - jamb_w * 0.55, door.position.y, jamb_w, maxf(door.size.y, _wall_h)))

func _draw_door_frame(door: Rect2) -> void:
	_draw_atlas_jambs(door)

func _draw_door_jambs(door: Rect2) -> void:
	_draw_door_frame(door)

func _stamp_h(dest: Rect2, src: Rect2) -> void:
	if dest.size.x <= 1.0 or dest.size.y <= 1.0:
		return
	if _wall_h_tex != null:
		_stamp_tex_h(_wall_h_tex, dest)
		return
	var world_w := src.size.x * SX
	var x := dest.position.x
	while x < dest.end.x:
		var dw := minf(world_w, dest.end.x - x)
		var src_w := dw / SX
		_blit(Rect2(src.position.x, src.position.y, src_w, src.size.y), Rect2(x, dest.position.y, dw, dest.size.y))
		x += world_w

func _stamp_v(dest: Rect2, src: Rect2) -> void:
	if dest.size.x <= 1.0 or dest.size.y <= 1.0:
		return
	if _wall_v_tex != null:
		_stamp_tex_v(_wall_v_tex, dest)
		return
	var world_h := src.size.y * SY
	var y := dest.position.y
	while y < dest.end.y:
		var dh := minf(world_h, dest.end.y - y)
		var src_h := dh / SY
		_blit(Rect2(src.position.x, src.position.y, src.size.x, src_h), Rect2(dest.position.x, y, dest.size.x, dh))
		y += world_h

func _stamp_tex_h(tex: Texture2D, dest: Rect2) -> void:
	var world_w := float(tex.get_width()) * SX
	var x := dest.position.x
	while x < dest.end.x:
		var dw := minf(world_w, dest.end.x - x)
		var src_w := dw / SX
		draw_texture_rect_region(tex, Rect2(x, dest.position.y, dw, dest.size.y), Rect2(0.0, 0.0, src_w, float(tex.get_height())))
		x += world_w

func _stamp_tex_v(tex: Texture2D, dest: Rect2) -> void:
	var world_h := float(tex.get_height()) * SY
	var y := dest.position.y
	while y < dest.end.y:
		var dh := minf(world_h, dest.end.y - y)
		var src_h := dh / SY
		draw_texture_rect_region(tex, Rect2(dest.position.x, y, dest.size.x, dh), Rect2(0.0, 0.0, float(tex.get_width()), src_h))
		y += world_h

func _blit(src: Rect2, dest: Rect2) -> void:
	draw_texture_rect_region(_atlas, dest, src)

func _draw_label(at: Vector2, title: String) -> void:
	draw_string(_label_font(), at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.78, 0.62, 0.90))

func _label_font() -> Font:
	if _label_font_cache != null:
		return _label_font_cache
	_label_font_cache = UiFont.bundled()
	return _label_font_cache

func _draw_crate(center: Vector2, sold: bool) -> void:
	var crate := Rect2(center - Vector2(22.0, 13.0), Vector2(44.0, 26.0))
	draw_rect(crate, WOOD, true)
	draw_rect(Rect2(crate.position.x + 3.0, crate.position.y + 3.0, crate.size.x - 6.0, crate.size.y - 6.0), WOOD_LIGHT, true)
	draw_rect(crate, TRIM, false, 2.0)
	if sold:
		draw_rect(crate, Color(0.02, 0.03, 0.04, 0.55), true)

extends Node2D

## Blit rooms from the combat atlas so shops read as the same dungeon, not debug rects.
const ATLAS_PATH := "res://assets/generated/grid-battlefield-v6.png"
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
var spawn_hole := Rect2()
var mouth_jambs: Array = []
var shelf_spots: Array[Vector2] = []
var shelf_sold: Array[bool] = []
var shelf_filled: Array[bool] = []
var gate_open := 1.0
var _atlas: Texture2D
var _label_font_cache: Font
var bottom_booth := Rect2()
var gate_x_min := 0.0
var gate_x_max := 0.0
var bottom_rail_y := 0.0

var _tile_w := TILE * SX
var _tile_h := TILE * SY
var _grid_ox := 0.0
var _grid_oy := -8.0
var _wall_h := 80.0 * SY
var _wall_v := 40.0 * SX

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_atlas = load(ATLAS_PATH) as Texture2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _atlas == null:
		_atlas = load(ATLAS_PATH) as Texture2D
	if _atlas == null:
		return
	for extra: Rect2 in expand_floors:
		_draw_floor_rect(extra)
	_draw_spawn_hole()
	for wall: Rect2 in expand_h_walls:
		_stamp_h(wall, WALL_H_SRC)
	for wall: Rect2 in expand_v_walls:
		_stamp_v(wall, WALL_V_SRC)
	for door: Rect2 in extra_doors:
		_draw_floor_rect(door)
		_draw_door_jambs(door)
	for jamb: Rect2 in mouth_jambs:
		if jamb.size.y >= jamb.size.x:
			_stamp_v(jamb, JAMB_SRC)
		else:
			_stamp_h(jamb, JAMB_SRC)
	var hall := merchant_room.merge(trainer_room)
	var door := merchant_door.merge(trainer_door)
	_draw_floor_rect(hall)
	_draw_floor_rect(door)
	_draw_room_shell(hall)
	_draw_door_jambs(door)
	_draw_label(hall.position + Vector2(16.0, 36.0), "商人")
	_draw_label(Vector2(hall.end.x - 72.0, hall.position.y + 36.0), "训练师")
	for index: int in range(shelf_spots.size()):
		if index < shelf_filled.size() and not shelf_filled[index]:
			continue
		var sold := index < shelf_sold.size() and shelf_sold[index]
		_draw_crate(shelf_spots[index], sold)

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

func _draw_room_shell(room: Rect2) -> void:
	var n := Rect2(room.position.x - _wall_v, room.position.y - _wall_h, room.size.x + _wall_v * 2.0, _wall_h)
	var w := Rect2(room.position.x - _wall_v, room.position.y, _wall_v, room.size.y)
	var e := Rect2(room.end.x, room.position.y, _wall_v, room.size.y)
	_stamp_h(n, WALL_H_SRC)
	_stamp_v(w, WALL_V_SRC)
	_stamp_v(e, WALL_V_SRC)

func _draw_spawn_hole() -> void:
	if spawn_hole.size.x <= 1.0 or spawn_hole.size.y <= 1.0:
		return
	draw_rect(spawn_hole, Color("#05060a"), true)
	var center := spawn_hole.get_center()
	var radius := minf(spawn_hole.size.x, spawn_hole.size.y) * 0.46
	draw_circle(center, radius * 1.12, Color(0.04, 0.04, 0.06, 0.95))
	draw_circle(center, radius, Color("#000000"))
	draw_arc(center, radius * 0.82, 0.0, TAU, 40, Color(0.16, 0.12, 0.09, 0.85), 3.0)
	draw_arc(center, radius * 0.58, 0.0, TAU, 32, Color(0.08, 0.05, 0.07, 0.90), 2.0)
	var mouth := Rect2(spawn_hole.position.x - 8.0, spawn_hole.position.y + 24.0, 16.0, spawn_hole.size.y - 48.0)
	draw_rect(mouth, Color("#05060a"), true)
	_stamp_h(Rect2(spawn_hole.position.x, spawn_hole.position.y, 18.0, _wall_h * 0.55), JAMB_SRC)
	_stamp_h(Rect2(spawn_hole.position.x, spawn_hole.end.y - _wall_h * 0.55, 18.0, _wall_h * 0.55), JAMB_SRC)

func _draw_door_jambs(door: Rect2) -> void:
	var jw := _tile_w * 0.25
	_blit(JAMB_SRC, Rect2(door.position.x - jw, door.position.y, jw, door.size.y))
	_blit(JAMB_SRC, Rect2(door.end.x, door.position.y, jw, door.size.y))

func _stamp_h(dest: Rect2, src: Rect2) -> void:
	if dest.size.x <= 1.0 or dest.size.y <= 1.0:
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
	var world_h := src.size.y * SY
	var y := dest.position.y
	while y < dest.end.y:
		var dh := minf(world_h, dest.end.y - y)
		var src_h := dh / SY
		_blit(Rect2(src.position.x, src.position.y, src.size.x, src_h), Rect2(dest.position.x, y, dest.size.x, dh))
		y += world_h

func _blit(src: Rect2, dest: Rect2) -> void:
	draw_texture_rect_region(_atlas, dest, src)

func _draw_label(at: Vector2, title: String) -> void:
	draw_string(_label_font(), at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.78, 0.62, 0.90))

func _label_font() -> Font:
	if _label_font_cache != null:
		return _label_font_cache
	var path := "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
	if FileAccess.file_exists(path):
		var loaded := FontFile.new()
		if loaded.load_dynamic_font(path) == OK:
			_label_font_cache = loaded
			return _label_font_cache
	_label_font_cache = ThemeDB.fallback_font
	return _label_font_cache

func _draw_crate(center: Vector2, sold: bool) -> void:
	var crate := Rect2(center - Vector2(22.0, 13.0), Vector2(44.0, 26.0))
	draw_rect(crate, WOOD, true)
	draw_rect(Rect2(crate.position.x + 3.0, crate.position.y + 3.0, crate.size.x - 6.0, crate.size.y - 6.0), WOOD_LIGHT, true)
	draw_rect(crate, TRIM, false, 2.0)
	if sold:
		draw_rect(crate, Color(0.02, 0.03, 0.04, 0.55), true)

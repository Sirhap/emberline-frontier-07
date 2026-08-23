extends Node2D

const STONE := Color("#24323c")
const STONE_LIGHT := Color("#354650")
const WOOD := Color("#3a2a1c")
const WOOD_LIGHT := Color("#6a4a28")
const TRIM := Color("#c4a06a")
const JAMB := Color("#6a4a28")

var merchant_room := Rect2(108.0, -280.0, 424.0, 280.0)
var trainer_room := Rect2(588.0, -280.0, 424.0, 280.0)
var merchant_door := Rect2(268.0, 0.0, 104.0, 112.0)
var trainer_door := Rect2(748.0, 0.0, 104.0, 112.0)
var north_wall := Rect2(76.0, 0.0, 1010.0, 112.0)
var shelf_spots: Array[Vector2] = []
var shelf_sold: Array[bool] = []
var shelf_filled: Array[bool] = []
var gate_open := 1.0
var _label_font_cache: Font
var bottom_booth := Rect2()
var gate_x_min := 0.0
var gate_x_max := 0.0
var bottom_rail_y := 0.0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_stone(Rect2(76.0, -400.0, 1010.0, 512.0))
	_draw_room(merchant_room, merchant_door, Color("#2a2218"), "商人")
	_draw_room(trainer_room, trainer_door, Color("#18242c"), "训练师")
	draw_rect(merchant_door, Color("#2a2218"), true)
	draw_rect(trainer_door, Color("#18242c"), true)
	_draw_door_frame(merchant_door)
	_draw_door_frame(trainer_door)
	for index: int in range(shelf_spots.size()):
		if index < shelf_filled.size() and not shelf_filled[index]:
			continue
		var sold := index < shelf_sold.size() and shelf_sold[index]
		_draw_crate(shelf_spots[index], sold)

func _draw_stone(rect: Rect2) -> void:
	draw_rect(rect, STONE, true)
	var tile := 32.0
	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.16, 0.22, 0.26, 0.50), 1.0)
		x += tile
	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.16, 0.22, 0.26, 0.36), 1.0)
		y += tile
	draw_rect(rect, Color("#1c2830"), false, 2.0)

func _draw_door_frame(door: Rect2) -> void:
	draw_rect(Rect2(door.position.x - 6.0, door.position.y, 6.0, door.size.y), JAMB, true)
	draw_rect(Rect2(door.end.x, door.position.y, 6.0, door.size.y), JAMB, true)
	draw_rect(Rect2(door.position.x, door.end.y - 8.0, door.size.x, 8.0), TRIM, true)
	draw_line(Vector2(door.position.x, door.position.y), Vector2(door.position.x, door.end.y), Color("#8ec8d4"), 2.0)
	draw_line(Vector2(door.end.x, door.position.y), Vector2(door.end.x, door.end.y), Color("#8ec8d4"), 2.0)

func _draw_room(room: Rect2, door: Rect2, floor_color: Color, title: String) -> void:
	draw_rect(room, floor_color, true)
	var tile := 48.0
	var x := room.position.x
	while x <= room.end.x:
		draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color(0.22, 0.30, 0.36, 0.22), 1.0)
		x += tile
	var y := room.position.y
	while y <= room.end.y:
		draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color(0.22, 0.30, 0.36, 0.16), 1.0)
		y += tile
	draw_rect(room, Color("#6aa0b0"), false, 2.0)
	draw_rect(Rect2(door.position.x, room.end.y - 8.0, door.size.x, 8.0), floor_color, true)
	draw_string(_label_font(), room.position + Vector2(14.0, 42.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d8efe8"))
	var rug := Rect2(room.position + Vector2(28.0, 56.0), Vector2(room.size.x - 56.0, 36.0))
	draw_rect(rug, Color(0.12, 0.08, 0.16, 0.45), true)

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

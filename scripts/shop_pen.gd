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
const ATLAS_W := 1536.0
const ATLAS_H := 1024.0
const ATLAS_OY := -8.0
## One painted tile, grout-to-grout (~65×64 atlas), scaled onto each world cell.
const FLOOR_SRC := Rect2(772.0, 490.0, 65.0, 64.0)
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
## Original painted floor only. Pit / north-wall band / anything outside uses wrapped tiles.
var painted_floor := Rect2()
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
## SK combat-room lane walls (gold). Empty = none. X span leaves an east walk gap.
var rail_ys: Array[float] = []
var rail_x0 := 90.0
var rail_x1 := 900.0
var gate_open := 1.0:
	set(value):
		if is_equal_approx(gate_open, value):
			return
		gate_open = value
		queue_redraw()
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
var _rail_tex: Texture2D
var _pedestal_tex: Texture2D

func _ready() -> void:
	set_process(false)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_atlas = load(ATLAS_PATH) as Texture2D
	_door_tex = load(DOOR_FRAME_PATH) as Texture2D
	_mouth_tex = load(MOUTH_FRAME_PATH) as Texture2D
	_wall_h_tex = load(WALL_H_TEX_PATH) as Texture2D
	_wall_v_tex = load(WALL_V_TEX_PATH) as Texture2D
	_jamb_l = load(JAMB_L_PATH) as Texture2D
	_jamb_r = load(JAMB_R_PATH) as Texture2D
	_rail_tex = _load_tex("res://assets/generated/fx/gold-rail.png")
	_pedestal_tex = _load_tex("res://assets/generated/ui/shop-pedestal.png")


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func apply_shelf_state(sold: Array, filled: Array, captions: Array) -> void:
	shelf_sold = []
	shelf_filled = []
	shelf_captions = []
	for flag: Variant in sold:
		shelf_sold.append(bool(flag))
	for flag: Variant in filled:
		shelf_filled.append(bool(flag))
	for caption: Variant in captions:
		shelf_captions.append(String(caption))
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
	if hall.size.x > 1.0 and hall.size.y > 1.0:
		_draw_floor_rect(hall)
		if door.position.y > hall.end.y and door.size.y > 1.0:
			_draw_floor_rect(Rect2(hall.position.x, hall.end.y, hall.size.x, door.position.y - hall.end.y))
		_draw_floor_rect(door)
		_draw_room_shell(hall, door)
		_draw_shop_south_wall(hall, door)
		_draw_label(hall.position + Vector2(16.0, 36.0), "客厅")
	_draw_shop_rails()
	_draw_vendor_tags()
	for index: int in range(shelf_spots.size()):
		if index < shelf_filled.size() and not shelf_filled[index]:
			continue
		var sold := index < shelf_sold.size() and shelf_sold[index]
		_draw_crate(shelf_spots[index], sold)
		if index < shelf_captions.size() and not shelf_captions[index].is_empty():
			_draw_shelf_caption(shelf_spots[index], shelf_captions[index])

func _draw_vendor_tags(_hall: Rect2 = Rect2()) -> void:
	## Nameplates on SK top/bottom stall bands inside the combat room.
	var tags: Array = [
		{"at": Vector2(160.0, 78.0), "t": "机械师"},
		{"at": Vector2(340.0, 78.0), "t": "商人"},
		{"at": Vector2(160.0, 526.0), "t": "召唤师"},
		{"at": Vector2(420.0, 526.0), "t": "军官"},
		{"at": Vector2(480.0, 526.0), "t": "导师"},
	]
	for tag: Dictionary in tags:
		var at: Vector2 = tag["at"]
		var title: String = tag["t"]
		var font := _label_font()
		var text_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		var world := at + Vector2(-text_size.x * 0.5, 0.0)
		draw_string(font, world + Vector2(1.0, 1.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.05, 0.04, 0.03, 0.90))
		draw_string(font, world, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.88, 0.70, 0.96))

func _draw_shop_rails() -> void:
	## SK endless gold lane walls — stop short of the east edge so you can walk 上下.
	if rail_ys.is_empty():
		return
	if _rail_tex == null:
		_rail_tex = _load_tex("res://assets/generated/fx/gold-rail.png")
	var x0 := rail_x0
	var x1 := rail_x1
	if x1 <= x0 + 8.0:
		return
	for rail_y: float in rail_ys:
		var x := x0
		## SK gold lane walls read as short block walls, not hairline floor paint.
		var rail_h := 28.0 if _rail_tex != null else 18.0
		while x < x1:
			var dw := minf(64.0, x1 - x)
			if _rail_tex != null:
				draw_texture_rect(_rail_tex, Rect2(x, rail_y - rail_h * 0.55, dw, rail_h), false)
			else:
				draw_rect(Rect2(x, rail_y - 8.0, dw, 16.0), Color("#c4a04a"), true)
			x += 64.0

func _painted_floor_rect() -> Rect2:
	if painted_floor.size.x > 1.0 and painted_floor.size.y > 1.0:
		return painted_floor
	return Rect2(0.0, ATLAS_OY, ATLAS_W * SX, ATLAS_H * SY)


func _draw_floor_rect(area: Rect2) -> void:
	if area.size.x <= 1.0 or area.size.y <= 1.0:
		return
	var painted := _painted_floor_rect()
	var x: float = floorf((area.position.x - _grid_ox) / _tile_w) * _tile_w + _grid_ox
	while x < area.end.x:
		var y: float = floorf((area.position.y - _grid_oy) / _tile_h) * _tile_h + _grid_oy
		while y < area.end.y:
			var dest := Rect2(x, y, _tile_w, _tile_h).intersection(area)
			if dest.size.x > 0.5 and dest.size.y > 0.5:
				_blit_floor_dest(dest, painted)
			y += _tile_h
		x += _tile_w


func _blit_floor_dest(dest: Rect2, painted: Rect2) -> void:
	var inside := dest.intersection(painted)
	if inside.size.x > 0.5 and inside.size.y > 0.5:
		var src := Rect2(
			inside.position.x / SX,
			(inside.position.y - ATLAS_OY) / SY,
			inside.size.x / SX,
			inside.size.y / SY
		)
		draw_texture_rect_region(_atlas, inside, src)
	for leftover: Rect2 in _rect_subtract(dest, painted):
		_blit_floor_wrapped(leftover)


func _rect_subtract(area: Rect2, cut: Rect2) -> Array:
	var hit := area.intersection(cut)
	if hit.size.x <= 0.5 or hit.size.y <= 0.5:
		return [area]
	var out: Array = []
	if area.position.y < hit.position.y - 0.5:
		out.append(Rect2(area.position.x, area.position.y, area.size.x, hit.position.y - area.position.y))
	if area.end.y > hit.end.y + 0.5:
		out.append(Rect2(area.position.x, hit.end.y, area.size.x, area.end.y - hit.end.y))
	if area.position.x < hit.position.x - 0.5:
		out.append(Rect2(area.position.x, hit.position.y, hit.position.x - area.position.x, hit.size.y))
	if area.end.x > hit.end.x + 0.5:
		out.append(Rect2(hit.end.x, hit.position.y, area.end.x - hit.end.x, hit.size.y))
	return out


func _blit_floor_wrapped(dest: Rect2) -> void:
	if dest.size.x <= 0.5 or dest.size.y <= 0.5:
		return
	var x0: float = floorf((dest.position.x - _grid_ox) / _tile_w) * _tile_w + _grid_ox
	var y0: float = floorf((dest.position.y - _grid_oy) / _tile_h) * _tile_h + _grid_oy
	var src := Rect2(
		FLOOR_SRC.position.x + (dest.position.x - x0) / _tile_w * FLOOR_SRC.size.x,
		FLOOR_SRC.position.y + (dest.position.y - y0) / _tile_h * FLOOR_SRC.size.y,
		dest.size.x / _tile_w * FLOOR_SRC.size.x,
		dest.size.y / _tile_h * FLOOR_SRC.size.y
	)
	draw_texture_rect_region(_atlas, dest, src)

func _draw_room_shell(room: Rect2, south_door: Rect2 = Rect2(), north_door: Rect2 = Rect2()) -> void:
	var south_y := south_door.position.y if south_door.size.y > 1.0 else room.end.y
	var wall_top := room.position.y - _wall_h
	var wall_h := south_y + _wall_h - wall_top
	var wv := _tile_w
	var n := Rect2(room.position.x - wv, room.position.y - _wall_h, room.size.x + wv * 2.0, _wall_h)
	var w := Rect2(room.position.x - wv, wall_top, wv, wall_h)
	var e := Rect2(room.end.x, wall_top, wv, wall_h)
	var s := Rect2(room.position.x - wv, south_y, room.size.x + wv * 2.0, _wall_h)
	_stamp_h_with_gap(n, north_door)
	_stamp_v(w, WALL_V_SRC)
	_stamp_v(e, WALL_V_SRC)
	_stamp_h_with_gap(s, south_door)

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

## Price/name floats above the pedestal icon.
func _draw_shelf_caption(crate_center: Vector2, title: String) -> void:
	var label := title
	var font := _label_font()
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	var world := crate_center + Vector2(-text_size.x * 0.5, -44.0)
	draw_string(font, world + Vector2(1.0, 1.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.06, 0.05, 0.04, 0.88))
	draw_string(font, world, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.93, 0.86, 0.68, 0.96))



func _in_shop_hall() -> bool:
	## Stalls live in the combat room now; treat combat as the shop hall for caption/cam helpers.
	var hall := merchant_room.merge(trainer_room)
	if hall.size.x <= 1.0:
		hall = Rect2(76.0, 72.0, 1100.0, 568.0)
	hall = hall.grow(80.0)
	var cam := get_viewport().get_camera_2d()
	if cam != null and hall.has_point(cam.get_screen_center_position()):
		return true
	return false

func _label_font() -> Font:
	if _label_font_cache != null:
		return _label_font_cache
	_label_font_cache = UiFont.bundled()
	return _label_font_cache

func _draw_crate(center: Vector2, sold: bool) -> void:
	## Gold-rim pedestal under floating shelf icons (SK counter look).
	if _pedestal_tex == null:
		_pedestal_tex = _load_tex("res://assets/generated/ui/shop-pedestal.png")
	if _pedestal_tex != null:
		var size := Vector2(float(_pedestal_tex.get_width()), float(_pedestal_tex.get_height()))
		var dest := Rect2(center - size * 0.5 + Vector2(0.0, 4.0), size)
		draw_texture_rect(_pedestal_tex, dest, false)
		if sold:
			draw_rect(dest, Color(0.02, 0.03, 0.04, 0.45), true)
		return
	var crate := Rect2(center - Vector2(22.0, 13.0), Vector2(44.0, 26.0))
	draw_rect(crate, WOOD, true)
	draw_rect(Rect2(crate.position.x + 3.0, crate.position.y + 3.0, crate.size.x - 6.0, crate.size.y - 6.0), WOOD_LIGHT, true)
	draw_rect(crate, TRIM, false, 2.0)
	if sold:
		draw_rect(crate, Color(0.02, 0.03, 0.04, 0.55), true)

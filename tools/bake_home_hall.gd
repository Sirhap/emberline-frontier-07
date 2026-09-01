extends SceneTree

## Bake a 1280x720 home hall + yard from the user tilesets, and crop furniture.

const YARD_PATH := "/workspace/assets/generated/home/tileset-yard.png"
const INTERIOR_PATH := "/workspace/assets/generated/home/tileset-interior.png"
const FURN_PATH := "/workspace/assets/generated/home/furniture-pack.png"
const DST := "/workspace/assets/generated/home"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DST)
	var yard := _load(YARD_PATH)
	var interior := _load(INTERIOR_PATH)
	var furn := _load(FURN_PATH)
	var yard_bg: Color = yard.get_pixel(0, 0)
	var interior_bg: Color = interior.get_pixel(0, 0)

	# Source sheets live in DST; do not rewrite them each bake.

	var grass := _cell(yard, Vector2i(22, 18), 127, 0, 0, yard_bg)
	var grass_flower := _cell(yard, Vector2i(22, 18), 127, 1, 0, yard_bg)
	var grass_b := _cell(yard, Vector2i(22, 18), 127, 0, 1, yard_bg)
	var wood := _cell(interior, Vector2i(24, 32), 129, 0, 0, interior_bg)
	var wood_vert := _cell(interior, Vector2i(24, 32), 129, 1, 0, interior_bg)
	var wall := _cell(interior, Vector2i(24, 32), 129, 0, 1, interior_bg)
	var wall_window := _cell(interior, Vector2i(24, 32), 129, 1, 1, interior_bg)
	var door := _cell(interior, Vector2i(24, 32), 129, 0, 2, interior_bg)
	var door_tall := _tight(interior.get_region(Rect2i(24, 32 + 129 * 2, 129, 150)), interior_bg, 1)
	if door_tall.get_height() > door.get_height():
		door = door_tall
	print("tiles grass=%s wood=%s wall=%s door=%s" % [_sz(grass), _sz(wood), _sz(wall), _sz(door)])

	_save_guttered(grass, yard_bg, DST + "/tile-grass.png")
	_save_guttered(wood, interior_bg, DST + "/tile-wood.png")
	_save_guttered(wall, interior_bg, DST + "/tile-wall.png")
	_save_guttered(door, interior_bg, DST + "/tile-door.png")

	_extract_furn(furn, Rect2i(189, 159, 109, 123), DST + "/bookshelf.png")
	_extract_furn(furn, Rect2i(323, 161, 90, 130), DST + "/bestiary.png")
	_extract_furn(furn, Rect2i(86, 10, 92, 139), DST + "/table.png")
	_extract_furn(furn, Rect2i(20, 473, 162, 95), DST + "/rug.png")
	_extract_furn(furn, Rect2i(1171, 927, 90, 119), DST + "/monument.png")
	_extract_furn(furn, Rect2i(27, 914, 113, 156), DST + "/pet-bed.png")
	_extract_furn(furn, Rect2i(1160, 38, 157, 111), DST + "/sofa.png")
	_extract_furn(furn, Rect2i(21, 780, 105, 145), DST + "/tree.png")
	_extract_furn(furn, Rect2i(249, 786, 124, 144), DST + "/tree-b.png")
	_extract_furn(furn, Rect2i(350, 35, 81, 107), DST + "/chair.png")
	_extract_furn(furn, Rect2i(199, 476, 150, 91), DST + "/rug-blue.png")

	_extract_pads(yard, yard_bg)

	var hall := _bake_hall(grass, grass_flower, grass_b, wood, wood_vert, wall, wall_window, door, yard_bg, interior_bg)
	var err := hall.save_png(DST + "/floor-room.png")
	assert(err == OK, "save floor-room")
	print("BAKED floor-room %dx%d" % [hall.get_width(), hall.get_height()])
	print("HOME HALL BAKE ok")
	quit()


func _extract_pads(yard: Image, bg: Color) -> void:
	var boxes := {
		"wood-pad.png": Rect2i(30, 998, 84, 78),
		"wood-round.png": Rect2i(126, 998, 95, 78),
		"hay-pad.png": Rect2i(235, 998, 92, 78),
		"stone-pad.png": Rect2i(340, 998, 92, 78),
	}
	for key: Variant in boxes.keys():
		var box: Rect2i = boxes[key]
		var crop := _tight(yard.get_region(box), bg, 1)
		_knockout_gutter(crop, bg)
		crop.save_png(DST + "/" + String(key))
		print("PAD %s %s" % [String(key), _sz(crop)])
	var ring := _tight(yard.get_region(Rect2i(24, 930, 92, 70)), bg, 1)
	_knockout_gutter(ring, bg)
	ring.save_png(DST + "/stone-ring.png")
	print("PAD stone-ring.png %s" % _sz(ring))


func _bake_hall(
		grass: Image, grass_flower: Image, grass_b: Image,
		wood: Image, wood_vert: Image,
		wall: Image, wall_window: Image, door: Image,
		yard_bg: Color, interior_bg: Color
	) -> Image:
	var hall := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	var fill: Color = grass.get_pixel(grass.get_width() / 2, grass.get_height() / 2)
	hall.fill(fill)
	_stamp_field(hall, [grass, grass_flower, grass_b], Rect2i(0, 0, 1280, 720), 92, 7, yard_bg)
	# Large hall, grass porch on all sides (deeper at the south).
	var house := Rect2i(48, 18, 1184, 622)
	_fill_wood(hall, wood, wood_vert, house)
	var wall_y: int = house.position.y - 6
	var door_w: int = maxi(80, door.get_width())
	var door_left: int = 640 - door_w / 2
	_stamp_row(hall, wall, wall_window, house.position.x, wall_y, door_left - house.position.x - 4, true, interior_bg)
	_stamp_row(hall, wall, wall_window, door_left + door_w + 4, wall_y, house.end.x - (door_left + door_w + 4), true, interior_bg)
	_blit_center(hall, door, Vector2i(640, wall_y + door.get_height() / 2 + 4), interior_bg)
	return hall


func _stamp_field(dst: Image, tiles: Array, rect: Rect2i, step: int, seed_n: int, bg: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	var y: int = rect.position.y - 18
	var row: int = 0
	while y < rect.end.y:
		var x: int = rect.position.x - 18 + (row % 2) * (step / 2)
		while x < rect.end.x:
			var tile: Image = tiles[rng.randi_range(0, tiles.size() - 1)]
			_blit_ignore_gutter(dst, tile, Vector2i(x, y), bg)
			x += step
		y += step - 14
		row += 1


func _fill_wood(dst: Image, a: Image, b: Image, rect: Rect2i) -> void:
	var inset: int = 3
	var tw: int = maxi(8, a.get_width() - inset * 2)
	var th: int = maxi(8, a.get_height() - inset * 2)
	var btw: int = maxi(8, b.get_width() - inset * 2)
	var bth: int = maxi(8, b.get_height() - inset * 2)
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var use_b: bool = ((x / tw) + (y / th)) % 2 == 1
			var src: Image = b if use_b else a
			var w: int = btw if use_b else tw
			var h: int = bth if use_b else th
			var px: int = inset + posmod(x - rect.position.x, w)
			var py: int = inset + posmod(y - rect.position.y, h)
			if px >= src.get_width() or py >= src.get_height():
				continue
			dst.set_pixel(x, y, src.get_pixel(px, py))


func _stamp_row(dst: Image, a: Image, b: Image, x0: int, y0: int, width: int, with_windows: bool, bg: Color) -> void:
	var step: int = maxi(48, a.get_width() - 4)
	var x: int = x0
	var i: int = 0
	while x < x0 + width:
		var tile: Image = b if (with_windows and i % 3 == 1) else a
		_blit_ignore_gutter(dst, tile, Vector2i(x, y0), bg)
		x += step
		i += 1


func _blit_center(dst: Image, src: Image, center: Vector2i, bg: Color) -> void:
	var pos := Vector2i(center.x - src.get_width() / 2, center.y - src.get_height() / 2)
	_blit_ignore_gutter(dst, src, pos, bg)


func _blit_ignore_gutter(dst: Image, src: Image, pos: Vector2i, bg: Color) -> void:
	var sw: int = src.get_width()
	var sh: int = src.get_height()
	var dw: int = dst.get_width()
	var dh: int = dst.get_height()
	for y: int in sh:
		var dy: int = pos.y + y
		if dy < 0 or dy >= dh:
			continue
		for x: int in sw:
			var dx: int = pos.x + x
			if dx < 0 or dx >= dw:
				continue
			var c: Color = src.get_pixel(x, y)
			if _is_gutter(c, bg):
				continue
			dst.set_pixel(dx, dy, c)


func _cell(img: Image, origin: Vector2i, pitch: int, col: int, row: int, bg: Color) -> Image:
	var box := Rect2i(origin.x + col * pitch, origin.y + row * pitch, pitch - 6, pitch - 6)
	box = box.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	return _tight(img.get_region(box), bg, 1)


func _tight(img: Image, bg: Color, pad: int) -> Image:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var min_x: int = w
	var min_y: int = h
	var max_x: int = -1
	var max_y: int = -1
	for y: int in h:
		for x: int in w:
			if _is_gutter(img.get_pixel(x, y), bg):
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x:
		return img
	min_x = maxi(0, min_x - pad)
	min_y = maxi(0, min_y - pad)
	max_x = mini(w - 1, max_x + pad)
	max_y = mini(h - 1, max_y + pad)
	return img.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))


func _extract_furn(sheet: Image, box: Rect2i, path: String) -> void:
	box = box.intersection(Rect2i(0, 0, sheet.get_width(), sheet.get_height()))
	var crop := _tight(sheet.get_region(box), Color(0, 0, 0, 0), 3)
	_knockout_paint_bg(crop)
	crop.save_png(path)
	print("FURN %s %s" % [path.get_file(), _sz(crop)])


func _save_guttered(img: Image, bg: Color, path: String) -> void:
	var copy: Image = img.duplicate()
	_knockout_gutter(copy, bg)
	copy.save_png(path)


func _knockout_gutter(img: Image, bg: Color) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			if _is_gutter(img.get_pixel(x, y), bg):
				img.set_pixel(x, y, Color(0, 0, 0, 0))


func _knockout_paint_bg(img: Image) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.12 or (c.r < 0.04 and c.g < 0.04 and c.b < 0.04):
				img.set_pixel(x, y, Color(0, 0, 0, 0))


func _is_gutter(c: Color, bg: Color) -> bool:
	if c.a < 0.12:
		return true
	return absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) < 0.09


func _load(path: String) -> Image:
	var img := Image.new()
	var err := img.load(path)
	assert(err == OK, "load %s" % path)
	img.convert(Image.FORMAT_RGBA8)
	return img


func _sz(img: Image) -> String:
	return "%dx%d" % [img.get_width(), img.get_height()]

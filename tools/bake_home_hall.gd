extends SceneTree

## Empty hall floor from floor-base. Furniture from black-bg packs, never from layout-ref.

const FLOOR_BASE := "/workspace/assets/generated/home/floor-base.png"
const STATION_PATH := "/workspace/assets/generated/home/station-pack.png"
const TECH_PATH := "/workspace/assets/generated/home/tech-pack.png"
const YARD_PATH := "/workspace/assets/generated/home/tileset-yard.png"
const DST := "/workspace/assets/generated/home"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DST)
	var floor := _load(FLOOR_BASE)
	floor.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	assert(floor.save_png(DST + "/floor-room.png") == OK, "save floor-room")
	print("BAKED floor-room %s from empty hall" % _sz(floor))

	var station := _load(STATION_PATH)
	_extract_furn(station, Rect2i(592, 352, 456, 288), DST + "/desk-coder.png")
	_extract_furn(station, Rect2i(1208, 88, 416, 200), DST + "/workbench.png")
	_extract_furn(station, Rect2i(1328, 472, 192, 168), DST + "/coffee.png")
	_extract_furn(station, Rect2i(984, 112, 48, 88), DST + "/plant.png")

	var tech := _load(TECH_PATH)
	_extract_furn(tech, Rect2i(24, 16, 556, 364), DST + "/desk.png")
	_extract_furn(tech, Rect2i(1000, 380, 200, 280), DST + "/vending.png")
	_extract_furn(tech, Rect2i(856, 36, 96, 236), DST + "/rubber-chicken.png")
	_extract_furn(tech, Rect2i(608, 68, 220, 175), DST + "/cow-plush.png")
	_extract_furn(tech, Rect2i(16, 796, 120, 126), DST + "/tech-pad.png")

	if FileAccess.file_exists(YARD_PATH):
		var yard := _load(YARD_PATH)
		_extract_pads(yard, yard.get_pixel(0, 0))

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

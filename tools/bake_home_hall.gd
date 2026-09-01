extends SceneTree

## Empty hall floor. Stamp the user's office packs; cut unique layout-ref props without the floor.

const FLOOR_BASE := "/workspace/assets/generated/home/floor-base.png"
const LAYOUT_REF := "/workspace/assets/generated/home/layout-ref.png"
const STATION_PATH := "/workspace/assets/generated/home/station-pack.png"
const TECH_PATH := "/workspace/assets/generated/home/tech-pack.png"
const YARD_PATH := "/workspace/assets/generated/home/tileset-yard.png"
const DST := "/workspace/assets/generated/home"
const OFFICE_DIR := "/workspace/assets/generated/home/office"
const DIFF_THRESH := 0.16
const FLOOR_PUNCH := 0.08


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DST)
	DirAccess.make_dir_recursive_absolute(OFFICE_DIR)
	_clear_dir(OFFICE_DIR)
	var empty := _load(FLOOR_BASE)
	var floor := empty.duplicate()
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
	_extract_furn(tech, Rect2i(1139, 664, 148, 117), DST + "/pet-cushion.png")

	_extract_office_props(empty, _load(LAYOUT_REF))

	if FileAccess.file_exists(YARD_PATH):
		var yard := _load(YARD_PATH)
		_extract_pads(yard, yard.get_pixel(0, 0))

	print("HOME HALL BAKE ok")
	quit()


func _extract_office_props(empty: Image, furnished: Image) -> void:
	var bounds := Rect2i(0, 0, mini(empty.get_width(), furnished.get_width()), mini(empty.get_height(), furnished.get_height()))
	var sx := 1280.0 / float(bounds.size.x)
	var sy := 720.0 / float(bounds.size.y)
	var cuts: Array = [
		{"name": "OvertimeSign", "box": Rect2i(70, 30, 140, 190)},
		{"name": "SlackScreen", "box": Rect2i(180, 20, 230, 170)},
		{"name": "Panda", "box": Rect2i(200, 270, 170, 170)},
		{"name": "Bestiary", "box": Rect2i(190, 440, 130, 160)},
		{"name": "Bull", "box": Rect2i(280, 530, 220, 190)},
		{"name": "CoffeeTable", "box": Rect2i(20, 720, 200, 200)},
		{"name": "PetBed", "box": Rect2i(230, 760, 230, 180)},
		{"name": "BookStack", "box": Rect2i(420, 700, 220, 180)},
		{"name": "FloorPlant", "box": Rect2i(680, 680, 160, 180)},
		{"name": "Bookshelf", "box": Rect2i(1160, 80, 130, 180)},
		{"name": "Monument", "box": Rect2i(1220, 10, 140, 160)},
		{"name": "WaterCooler", "box": Rect2i(1500, 40, 160, 230)},
		{"name": "Chicken", "box": Rect2i(1160, 370, 230, 220)},
		{"name": "HobbyPile", "box": Rect2i(1040, 670, 520, 260)},
		{"name": "BallBox", "box": Rect2i(820, 690, 240, 180)},
	]
	var manifest: Array = []
	for cut: Dictionary in cuts:
		var item: Variant = _cut_office(empty, furnished, String(cut["name"]), cut["box"], bounds, sx, sy)
		if item is Dictionary:
			manifest.append(item)
	var json := FileAccess.open(DST + "/office-manifest.json", FileAccess.WRITE)
	assert(json != null, "write office-manifest")
	json.store_string(JSON.stringify(manifest))
	json.close()
	print("OFFICE PROP COUNT %d" % manifest.size())


func _cut_office(empty: Image, furnished: Image, node_name: String, box: Rect2i, bounds: Rect2i, sx: float, sy: float) -> Variant:
	box = box.intersection(bounds)
	if box.size.x < 8 or box.size.y < 8:
		return null
	var furn := furnished.get_region(box)
	var base := empty.get_region(box)
	var w: int = furn.get_width()
	var h: int = furn.get_height()
	var solid := PackedByteArray()
	solid.resize(w * h)
	var hits := 0
	for y in h:
		for x in w:
			if _color_dist(base.get_pixel(x, y), furn.get_pixel(x, y)) <= DIFF_THRESH:
				continue
			solid[y * w + x] = 1
			hits += 1
	if hits < 80:
		print("SKIP %s (too little paint)" % node_name)
		return null
	solid = _dilate(solid, w, h, 1)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	hits = 0
	for y in h:
		for x in w:
			if solid[y * w + x] == 0:
				continue
			if _color_dist(base.get_pixel(x, y), furn.get_pixel(x, y)) < FLOOR_PUNCH:
				continue
			out.set_pixel(x, y, furn.get_pixel(x, y))
			hits += 1
	if hits < 80:
		print("SKIP %s (punched empty)" % node_name)
		return null
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	for y in h:
		for x in w:
			if out.get_pixel(x, y).a < 0.12:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x:
		print("SKIP %s (empty)" % node_name)
		return null
	min_x = maxi(0, min_x - 1)
	min_y = maxi(0, min_y - 1)
	max_x = mini(w - 1, max_x + 1)
	max_y = mini(h - 1, max_y + 1)
	out = out.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
	var dw: int = maxi(1, int(round(float(out.get_width()) * sx)))
	var dh: int = maxi(1, int(round(float(out.get_height()) * sy)))
	out.resize(dw, dh, Image.INTERPOLATE_LANCZOS)
	var path := "%s/%s.png" % [OFFICE_DIR, node_name]
	out.save_png(path)
	var cx := (float(box.position.x) + float(min_x) + float(out.get_width()) * 0.5 / sx) * sx
	var cy := (float(box.position.y) + float(min_y) + float(out.get_height()) * 0.5 / sy) * sy
	print("OFFICE %s %dx%d @ %.0f,%.0f" % [node_name, dw, dh, cx, cy])
	return {
		"name": node_name,
		"file": "office/%s.png" % node_name,
		"x": snapped(cx, 0.1),
		"y": snapped(cy, 0.1),
	}


func _tight_alpha(img: Image, pad: int) -> Image:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a < 0.12:
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


func _dilate(src: PackedByteArray, w: int, h: int, radius: int) -> PackedByteArray:
	var tmp := PackedByteArray()
	tmp.resize(w * h)
	var out := PackedByteArray()
	out.resize(w * h)
	for y in h:
		for x in w:
			var on := 0
			var x0: int = maxi(0, x - radius)
			var x1: int = mini(w - 1, x + radius)
			var row: int = y * w
			var i: int = x0
			while i <= x1:
				if src[row + i] == 1:
					on = 1
					break
				i += 1
			tmp[row + x] = on
	for y in h:
		for x in w:
			var on := 0
			var y0: int = maxi(0, y - radius)
			var y1: int = mini(h - 1, y + radius)
			var i: int = y0
			while i <= y1:
				if tmp[i * w + x] == 1:
					on = 1
					break
				i += 1
			out[y * w + x] = on
	return out


func _erode(src: PackedByteArray, w: int, h: int, radius: int) -> PackedByteArray:
	var inv := PackedByteArray()
	inv.resize(w * h)
	for i in w * h:
		inv[i] = 0 if src[i] == 1 else 1
	inv = _dilate(inv, w, h, radius)
	var out := PackedByteArray()
	out.resize(w * h)
	for i in w * h:
		out[i] = 0 if inv[i] == 1 else 1
	return out


func _clear_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname != "." and fname != ".." and not dir.current_is_dir():
			dir.remove(fname)
		fname = dir.get_next()
	dir.list_dir_end()


func _color_dist(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)


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

extends SceneTree

## Chroma-key magenta furniture and copy home art into assets/generated/home/.

const SRC := "/opt/cursor/artifacts/assets"
const DST := "/workspace/assets/generated/home"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DST)
	_copy_plain("home_floor_empty_room.png", "floor-room.png")
	_copy_plain("home_floor_tile.png", "floor-tile.png")
	_copy_plain("home_wall_north.png", "wall-north.png")
	_copy_plain("home_furniture_sheet.png", "furniture-sheet.png")
	var pieces := {
		"home_rug.png": "rug.png",
		"home_bookshelf.png": "bookshelf.png",
		"home_monument.png": "monument.png",
		"home_pet_bed.png": "pet-bed.png",
		"home_pedestal.png": "pedestal.png",
		"home_bestiary.png": "bestiary.png",
		"home_table.png": "table.png",
	}
	for src_name: Variant in pieces.keys():
		_chroma_crop("%s/%s" % [SRC, String(src_name)], "%s/%s" % [DST, String(pieces[src_name])])
	print("HOME ART PROCESS ok")
	quit()


func _copy_plain(src_name: String, dst_name: String) -> void:
	var img := Image.new()
	var err := img.load("%s/%s" % [SRC, src_name])
	assert(err == OK, "load %s" % src_name)
	err = img.save_png("%s/%s" % [DST, dst_name])
	assert(err == OK, "save %s" % dst_name)
	print("COPIED %s %dx%d" % [dst_name, img.get_width(), img.get_height()])


func _chroma_crop(src_path: String, dst_path: String) -> void:
	var img := Image.new()
	var err := img.load(src_path)
	assert(err == OK, "load %s" % src_path)
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if _is_magenta(c):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	assert(max_x >= min_x, "no opaque pixels in %s" % src_path)
	var pad := 4
	min_x = maxi(0, min_x - pad)
	min_y = maxi(0, min_y - pad)
	max_x = mini(w - 1, max_x + pad)
	max_y = mini(h - 1, max_y + pad)
	var cropped := img.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
	err = cropped.save_png(dst_path)
	assert(err == OK, "save %s" % dst_path)
	print("CHROMA %s %dx%d" % [dst_path.get_file(), cropped.get_width(), cropped.get_height()])


func _is_magenta(c: Color) -> bool:
	return c.r > 0.62 and c.b > 0.62 and c.g < 0.38

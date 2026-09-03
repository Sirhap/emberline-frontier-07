class_name HeroPackValidator
extends RefCounted

## Folder completeness gate. Same rules as tools/pack_validate.py.

const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")


static func validate_dir(pack_dir: String) -> Dictionary:
	var root := pack_dir
	if root.ends_with("/"):
		root = root.substr(0, root.length() - 1)
	var meta := _read_json("%s/pack.json" % root)
	var missing: Array[String] = []
	var pack_id := String(meta.get("id", root.get_file()))
	var base := String(meta.get("base", ""))
	if HeroPackSpec.template_for(base).is_empty():
		if not HeroPackSpec.template_for(pack_id).is_empty():
			base = pack_id
		elif pack_id == "ember_assassin":
			base = "assassin"
		else:
			missing.append("pack.json.base")
			base = "ember_hero"
	var view_mode := String(meta.get("view_mode", HeroPackSpec.VIEW_SIDE_FLIP if HeroPackSpec.is_builtin_side_flip(pack_id) else HeroPackSpec.VIEW_THREE))
	if view_mode != HeroPackSpec.VIEW_THREE and view_mode != HeroPackSpec.VIEW_SIDE_FLIP:
		missing.append("pack.json.view_mode")
		view_mode = HeroPackSpec.VIEW_THREE
	if view_mode == HeroPackSpec.VIEW_SIDE_FLIP and not HeroPackSpec.is_builtin_side_flip(pack_id):
		missing.append("view_mode: new packs must use three")
	var kind := String(meta.get("kind", "skin"))
	if kind != "skin" and kind != "hero":
		missing.append("pack.json.kind")
	if String(meta.get("title", "")) == "" and not HeroPackSpec.is_builtin_side_flip(pack_id):
		missing.append("pack.json.title")
	var template: Dictionary = HeroPackSpec.template_for(base)
	var required: Array = template.get("required", [])
	var optional: Array = template.get("optional", [])
	var views: Array[String] = []
	if view_mode == HeroPackSpec.VIEW_THREE:
		for view: String in HeroPackSpec.VIEWS:
			views.append(view)
	else:
		views.append("")
	var slots_out: Array = []
	for slot_value: Variant in required + optional:
		var slot := String(slot_value)
		var need := required.has(slot)
		var view_counts := {}
		var sizes: Dictionary = {}
		var slot_ok := true
		for view: String in views:
			var folder := "%s/%s" % [root, slot] if view == "" else "%s/%s/%s" % [root, slot, view]
			var frames: PackedStringArray = _list_pngs(folder)
			var label := slot if view == "" else "%s/%s" % [slot, view]
			view_counts[view if view != "" else "side"] = frames.size()
			if need and frames.is_empty():
				missing.append("missing %s" % label)
				slot_ok = false
				continue
			for frame_path: String in frames:
				var size: Vector2i = _png_size(frame_path)
				if size == Vector2i.ZERO:
					missing.append("unreadable %s" % frame_path.get_file())
					slot_ok = false
					continue
				sizes[size] = true
				if slot == "idle" and not _feet_ok(frame_path):
					missing.append("feet %s/%s" % [label, frame_path.get_file()])
					slot_ok = false
			if sizes.size() > 1:
				missing.append("size %s" % label)
				slot_ok = false
		slots_out.append({
			"slot": slot,
			"required": need,
			"ok": slot_ok if need else true,
			"frames": _sum_counts(view_counts),
			"views": view_counts,
		})
	if not FileAccess.file_exists("%s/portrait.png" % root):
		var idle_view := "side" if view_mode == HeroPackSpec.VIEW_THREE else ""
		var idle_dir := "%s/idle" % root if idle_view == "" else "%s/idle/%s" % [root, idle_view]
		if _list_pngs(idle_dir).is_empty():
			missing.append("portrait")
	return {
		"complete": missing.is_empty(),
		"id": pack_id,
		"kind": kind,
		"base": base,
		"title": String(meta.get("title", pack_id)),
		"view_mode": view_mode,
		"fps": int(meta.get("fps", 0)),
		"slot_fps": meta.get("slot_fps", {}),
		"anchorMode": String(meta.get("anchorMode", "canvas_bottom_center")),
		"slots": slots_out,
		"missing": missing,
		"root": root,
	}


static func _sum_counts(counts: Dictionary) -> int:
	var total := 0
	for key: Variant in counts.keys():
		total += int(counts[key])
	return total


static func _list_pngs(folder: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open(folder)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.to_lower().ends_with(".png"):
			out.append("%s/%s" % [folder, name])
		name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


static func _png_size(path: String) -> Vector2i:
	var image := Image.new()
	if image.load(_fs_path(path)) != OK:
		return Vector2i.ZERO
	return Vector2i(image.get_width(), image.get_height())


static func _feet_ok(path: String) -> bool:
	var image := Image.new()
	if image.load(_fs_path(path)) != OK:
		return true
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var height := image.get_height()
	var width := image.get_width()
	var scan := maxi(1, height / 10)
	for y in range(height - scan, height):
		for x in range(width):
			if image.get_pixel(x, y).a > 0.03:
				return true
	return false


static func _fs_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

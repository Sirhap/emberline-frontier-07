class_name HeroPackImporter
extends RefCounted

## Copy a validated pack into xsxb assets, append a profile, and register it.

const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")
const HeroPackValidator := preload("res://scripts/hero_pack_validator.gd")
const HeroPackCatalog := preload("res://scripts/hero_pack_catalog.gd")

const DEFAULT_CATALOG_PATH := "res://data/imported_hero_packs.json"


static func import_pack(pack_dir: String, opts: Dictionary = {}) -> Dictionary:
	var unpacked := pack_dir
	if pack_dir.to_lower().ends_with(".zip"):
		unpacked = _unzip(pack_dir, String(opts.get("unzip_dir", "user://pack_import_tmp")))
		if unpacked == "":
			return {"ok": false, "error": "zip", "report": {}}
	var report: Dictionary = HeroPackValidator.validate_dir(unpacked)
	if not bool(report.get("complete", false)):
		return {"ok": false, "error": "incomplete", "report": report}
	var pack_id := String(report.get("id", ""))
	var base := String(report.get("base", "ember_hero"))
	var view_mode := String(report.get("view_mode", HeroPackSpec.VIEW_THREE))
	var project_id := String(opts.get("project_id", _project_for_base(base)))
	var assets_root := String(opts.get("assets_root", "res://xsxb_frame_tuner/workspace/projects/%s/assets" % project_id))
	var dest_dir := "%s/%s" % [assets_root, pack_id]
	_copy_tree(unpacked, dest_dir)
	var manifest_path := String(opts.get("manifest_path", "res://xsxb_frame_tuner/data/projects/%s/animation_manifest.json" % project_id))
	var profile := _build_profile(pack_id, dest_dir, view_mode, base, report)
	_write_profile(manifest_path, profile)
	var portrait := _portrait_path(dest_dir, view_mode)
	var catalog_path := String(opts.get("catalog_path", DEFAULT_CATALOG_PATH))
	var kind := String(report.get("kind", "skin"))
	var pack_row := {
		"id": pack_id,
		"kind": kind,
		"title": String(report.get("title", pack_id)),
		"base": base,
		"view_mode": view_mode,
		"frame_project_id": project_id,
		"frame_profile_id": pack_id,
		"portrait": portrait,
		"complete": true,
	}
	if bool(report.get("hide_held_overlay", false)):
		pack_row["hide_held_overlay"] = true
	var into := String(report.get("transform_into", ""))
	if into != "":
		pack_row["transform_into"] = into
	if bool(report.get("selectable", true)) == false:
		pack_row["selectable"] = false
	_register_catalog(catalog_path, pack_row, kind == "hero")
	HeroPackCatalog.load_from(catalog_path)
	return {"ok": true, "error": "", "report": report, "pack": pack_row, "manifest": manifest_path}


static func is_builtin(pack_id: String) -> bool:
	return HeroPackSpec.is_builtin_side_flip(pack_id)


static func desktop_import_available() -> bool:
	return not OS.has_feature("web")


static func create_draft(pack_id: String, title: String, kind: String, base: String, opts: Dictionary = {}) -> Dictionary:
	var id := _sanitize_id(pack_id)
	if id == "" or is_builtin(id):
		return {"ok": false, "error": "id", "pack": {}}
	if kind != "skin" and kind != "hero":
		return {"ok": false, "error": "kind", "pack": {}}
	if HeroPackSpec.template_for(base).is_empty():
		return {"ok": false, "error": "base", "pack": {}}
	var dest := _resolve_dest(id, base, opts)
	if DirAccess.dir_exists_absolute(_abs(dest)) and not bool(opts.get("overwrite", false)):
		if FileAccess.file_exists("%s/pack.json" % dest):
			_ensure_slot_dirs(dest, base, HeroPackSpec.VIEW_THREE)
			var existing := _catalog_row_from_disk(id, dest, kind, title, base, opts)
			_register_catalog(String(opts.get("catalog_path", DEFAULT_CATALOG_PATH)), existing, false)
			HeroPackCatalog.load_from(String(opts.get("catalog_path", DEFAULT_CATALOG_PATH)))
			rebuild_profile(id, opts)
			return {"ok": true, "error": "", "pack": existing, "report": HeroPackValidator.validate_dir(dest)}
	DirAccess.make_dir_recursive_absolute(_abs(dest))
	var meta := {
		"id": id,
		"kind": kind,
		"title": title if title != "" else id,
		"base": base,
		"view_mode": HeroPackSpec.VIEW_THREE,
		"anchorMode": "canvas_bottom_center",
	}
	var meta_file := FileAccess.open("%s/pack.json" % dest, FileAccess.WRITE)
	if meta_file == null:
		return {"ok": false, "error": "write", "pack": {}}
	meta_file.store_string(JSON.stringify(meta))
	meta_file.close()
	_ensure_slot_dirs(dest, base, HeroPackSpec.VIEW_THREE)
	var pack_row := _catalog_row_from_disk(id, dest, kind, String(meta["title"]), base, opts)
	pack_row["complete"] = false
	_register_catalog(String(opts.get("catalog_path", DEFAULT_CATALOG_PATH)), pack_row, false)
	HeroPackCatalog.load_from(String(opts.get("catalog_path", DEFAULT_CATALOG_PATH)))
	rebuild_profile(id, opts)
	return {"ok": true, "error": "", "pack": pack_row, "report": HeroPackValidator.validate_dir(dest)}


static func add_frames(pack_id: String, slot: String, view: String, png_paths: PackedStringArray, mode: String = "append", opts: Dictionary = {}) -> Dictionary:
	if is_builtin(pack_id):
		return {"ok": false, "error": "builtin"}
	if png_paths.is_empty():
		return {"ok": false, "error": "empty"}
	var dest := _resolve_dest(pack_id, "", opts)
	var folder := _slot_folder(dest, slot, view, _view_mode_of(dest))
	DirAccess.make_dir_recursive_absolute(_abs(folder))
	if mode == "replace":
		for old_path: String in _list_png_names(folder):
			DirAccess.remove_absolute(_abs("%s/%s" % [folder, old_path]))
	var start := _list_png_names(folder).size()
	var copied := 0
	for i in range(png_paths.size()):
		var src := String(png_paths[i])
		if not FileAccess.file_exists(src) and not FileAccess.file_exists(_abs(src)):
			continue
		var dest_name := "frame_%04d.png" % (start + copied + 1)
		var to_path := "%s/%s" % [folder, dest_name]
		var err := DirAccess.copy_absolute(_abs(src), _abs(to_path))
		if err != OK:
			var bytes := FileAccess.get_file_as_bytes(_abs(src))
			var out := FileAccess.open(to_path, FileAccess.WRITE)
			if out == null:
				continue
			out.store_buffer(bytes)
			out.close()
		copied += 1
	if copied == 0:
		return {"ok": false, "error": "copy"}
	rebuild_profile(pack_id, opts)
	_sync_complete_flag(pack_id, opts)
	return {"ok": true, "error": "", "copied": copied, "frames": list_frames(pack_id, slot, view, opts)}


static func replace_frame(pack_id: String, slot: String, view: String, index: int, png_path: String, opts: Dictionary = {}) -> Dictionary:
	if is_builtin(pack_id):
		return {"ok": false, "error": "builtin"}
	var frames: PackedStringArray = list_frames(pack_id, slot, view, opts)
	if index < 0 or index >= frames.size():
		return {"ok": false, "error": "index"}
	var target := String(frames[index])
	var err := DirAccess.copy_absolute(_abs(png_path), _abs(target))
	if err != OK:
		var bytes := FileAccess.get_file_as_bytes(_abs(png_path))
		var out := FileAccess.open(target, FileAccess.WRITE)
		if out == null:
			return {"ok": false, "error": "copy"}
		out.store_buffer(bytes)
		out.close()
	rebuild_profile(pack_id, opts)
	_sync_complete_flag(pack_id, opts)
	return {"ok": true, "error": "", "path": target}


static func remove_frame(pack_id: String, slot: String, view: String, index: int, opts: Dictionary = {}) -> Dictionary:
	if is_builtin(pack_id):
		return {"ok": false, "error": "builtin"}
	var dest := _resolve_dest(pack_id, "", opts)
	var folder := _slot_folder(dest, slot, view, _view_mode_of(dest))
	var names := _list_png_names(folder)
	if index < 0 or index >= names.size():
		return {"ok": false, "error": "index"}
	DirAccess.remove_absolute(_abs("%s/%s" % [folder, names[index]]))
	names.remove_at(index)
	for i in range(names.size()):
		var want := "frame_%04d.png" % (i + 1)
		if names[i] == want:
			continue
		var from_path := "%s/%s" % [folder, names[i]]
		var to_path := "%s/%s" % [folder, want]
		DirAccess.rename_absolute(_abs(from_path), _abs(to_path))
		names[i] = want
	rebuild_profile(pack_id, opts)
	_sync_complete_flag(pack_id, opts)
	return {"ok": true, "error": "", "frames": list_frames(pack_id, slot, view, opts)}


static func set_portrait(pack_id: String, png_path: String, opts: Dictionary = {}) -> Dictionary:
	if is_builtin(pack_id):
		return {"ok": false, "error": "builtin"}
	var dest := _resolve_dest(pack_id, "", opts)
	var target := "%s/portrait.png" % dest
	var err := DirAccess.copy_absolute(_abs(png_path), _abs(target))
	if err != OK:
		var bytes := FileAccess.get_file_as_bytes(_abs(png_path))
		var out := FileAccess.open(target, FileAccess.WRITE)
		if out == null:
			return {"ok": false, "error": "copy"}
		out.store_buffer(bytes)
		out.close()
	var catalog_path := String(opts.get("catalog_path", DEFAULT_CATALOG_PATH))
	var pack: Dictionary = HeroPackCatalog.pack_by_id(StringName(pack_id))
	if pack.is_empty():
		pack = _catalog_row_from_disk(pack_id, dest, "skin", pack_id, "ember_hero", opts)
	pack["portrait"] = target
	_register_catalog(catalog_path, pack, false)
	HeroPackCatalog.load_from(catalog_path)
	return {"ok": true, "error": "", "portrait": target}


static func rebuild_profile(pack_id: String, opts: Dictionary = {}) -> Dictionary:
	var dest := _resolve_dest(pack_id, "", opts)
	if not FileAccess.file_exists("%s/pack.json" % dest):
		return {"ok": false, "error": "missing"}
	var report: Dictionary = HeroPackValidator.validate_dir(dest)
	var base := String(report.get("base", "ember_hero"))
	var view_mode := String(report.get("view_mode", HeroPackSpec.VIEW_THREE))
	var project_id := String(opts.get("project_id", _project_for_base(base)))
	var manifest_path := String(opts.get("manifest_path", "res://xsxb_frame_tuner/data/projects/%s/animation_manifest.json" % project_id))
	var profile := _build_profile(pack_id, dest, view_mode, base, report)
	_write_profile(manifest_path, profile)
	return {"ok": true, "error": "", "report": report, "manifest": manifest_path}


static func publish(pack_id: String, opts: Dictionary = {}) -> Dictionary:
	if is_builtin(pack_id):
		return {"ok": false, "error": "builtin", "report": {}}
	var dest := _resolve_dest(pack_id, "", opts)
	rebuild_profile(pack_id, opts)
	var report: Dictionary = HeroPackValidator.validate_dir(dest)
	if not bool(report.get("complete", false)):
		_sync_complete_flag(pack_id, opts)
		return {"ok": false, "error": "incomplete", "report": report}
	var catalog_path := String(opts.get("catalog_path", DEFAULT_CATALOG_PATH))
	HeroPackCatalog.load_from(catalog_path)
	var pack: Dictionary = HeroPackCatalog.pack_by_id(StringName(pack_id))
	if pack.is_empty():
		pack = _catalog_row_from_disk(pack_id, dest, String(report.get("kind", "skin")), String(report.get("title", pack_id)), String(report.get("base", "ember_hero")), opts)
	pack["complete"] = true
	pack["portrait"] = _portrait_path(dest, String(report.get("view_mode", HeroPackSpec.VIEW_THREE)))
	var kind := String(pack.get("kind", report.get("kind", "skin")))
	_register_catalog(catalog_path, pack, kind == "hero")
	HeroPackCatalog.load_from(catalog_path)
	return {"ok": true, "error": "", "report": report, "pack": pack}


static func delete_imported(pack_id: String, opts: Dictionary = {}) -> Dictionary:
	if is_builtin(pack_id):
		return {"ok": false, "error": "builtin"}
	var dest := _resolve_dest(pack_id, "", opts)
	var pack_meta := _read_json_file("%s/pack.json" % dest)
	var base := String(pack_meta.get("base", "ember_hero"))
	if base == "":
		base = "ember_hero"
	_rm_tree(dest)
	var catalog_path := String(opts.get("catalog_path", DEFAULT_CATALOG_PATH))
	_unregister_catalog(catalog_path, pack_id)
	var project_id := String(opts.get("project_id", _project_for_base(base)))
	var manifest_path := String(opts.get("manifest_path", "res://xsxb_frame_tuner/data/projects/%s/animation_manifest.json" % project_id))
	_remove_profile(manifest_path, pack_id)
	HeroPackCatalog.load_from(catalog_path)
	return {"ok": true, "error": ""}


static func list_frames(pack_id: String, slot: String, view: String, opts: Dictionary = {}) -> PackedStringArray:
	var dest := _resolve_dest(pack_id, "", opts)
	var folder := _slot_folder(dest, slot, view, _view_mode_of(dest))
	var out := PackedStringArray()
	for name: String in _list_png_names(folder):
		out.append("%s/%s" % [folder, name])
	return out


static func export_zip(pack_id: String, zip_path: String, opts: Dictionary = {}) -> Dictionary:
	var dest := _resolve_dest(pack_id, "", opts)
	if not DirAccess.dir_exists_absolute(_abs(dest)):
		return {"ok": false, "error": "missing"}
	DirAccess.make_dir_recursive_absolute(_abs(zip_path.get_base_dir()))
	var packer := ZIPPacker.new()
	if packer.open(_abs(zip_path)) != OK:
		return {"ok": false, "error": "zip"}
	_zip_tree(packer, _abs(dest), "")
	packer.close()
	return {"ok": true, "error": "", "path": zip_path}


static func pack_assets_dir(pack_id: String, opts: Dictionary = {}) -> String:
	return _resolve_dest(pack_id, "", opts)


static func set_title(pack_id: String, title: String, opts: Dictionary = {}) -> Dictionary:
	if is_builtin(pack_id):
		return {"ok": false, "error": "builtin"}
	var dest := _resolve_dest(pack_id, "", opts)
	var meta := _read_json_file("%s/pack.json" % dest)
	if meta.is_empty():
		return {"ok": false, "error": "missing"}
	meta["title"] = title.strip_edges() if title.strip_edges() != "" else pack_id
	var meta_file := FileAccess.open("%s/pack.json" % dest, FileAccess.WRITE)
	if meta_file == null:
		return {"ok": false, "error": "write"}
	meta_file.store_string(JSON.stringify(meta))
	meta_file.close()
	var catalog_path := String(opts.get("catalog_path", DEFAULT_CATALOG_PATH))
	HeroPackCatalog.load_from(catalog_path)
	var pack: Dictionary = HeroPackCatalog.pack_by_id(StringName(pack_id))
	if pack.is_empty():
		pack = _catalog_row_from_disk(pack_id, dest, String(meta.get("kind", "skin")), String(meta["title"]), String(meta.get("base", "ember_hero")), opts)
	pack["title"] = String(meta["title"])
	_register_catalog(catalog_path, pack, String(pack.get("kind", "skin")) == "hero" and bool(pack.get("complete", false)))
	HeroPackCatalog.load_from(catalog_path)
	return {"ok": true, "error": "", "pack": pack}


static func _project_for_base(base: String) -> String:
	return "emberline_enemies" if base == "assassin" else "emberline_frontier_07_final"


static func _unzip(zip_path: String, dest_root: String) -> String:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return ""
	var files: PackedStringArray = reader.get_files()
	var pack_json := ""
	for name: String in files:
		if name.ends_with("pack.json") and not name.ends_with("/"):
			pack_json = name
			break
	if pack_json == "":
		reader.close()
		return ""
	var prefix := pack_json.get_base_dir()
	var out_dir := "%s/%s" % [dest_root, pack_json.get_base_dir().get_file() if prefix != "" else zip_path.get_file().get_basename()]
	DirAccess.make_dir_recursive_absolute(_abs(out_dir))
	for name: String in files:
		if name.ends_with("/"):
			continue
		var rel := name
		if prefix != "" and name.begins_with(prefix + "/"):
			rel = name.substr(prefix.length() + 1)
		elif prefix != "" and name == pack_json:
			rel = "pack.json"
		var target := "%s/%s" % [out_dir, rel]
		DirAccess.make_dir_recursive_absolute(_abs(target.get_base_dir()))
		var bytes: PackedByteArray = reader.read_file(name)
		var file := FileAccess.open(target, FileAccess.WRITE)
		if file != null:
			file.store_buffer(bytes)
			file.close()
	reader.close()
	return out_dir


static func _copy_tree(src: String, dest: String) -> void:
	DirAccess.make_dir_recursive_absolute(_abs(dest))
	var dir := DirAccess.open(src)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var from_path := "%s/%s" % [src, name]
		var to_path := "%s/%s" % [dest, name]
		if dir.current_is_dir():
			_copy_tree(from_path, to_path)
		else:
			DirAccess.make_dir_recursive_absolute(_abs(to_path.get_base_dir()))
			DirAccess.copy_absolute(_abs(from_path), _abs(to_path))
		name = dir.get_next()
	dir.list_dir_end()


static func _build_profile(pack_id: String, dest_dir: String, view_mode: String, base: String, report: Dictionary) -> Dictionary:
	var animations: Array = []
	var template: Dictionary = HeroPackSpec.template_for(base)
	var slots: Array = []
	for item: Variant in template.get("required", []):
		slots.append(String(item))
	for item: Variant in template.get("optional", []):
		slots.append(String(item))
	var fps_override := int(report.get("fps", 0))
	var slot_fps: Dictionary = report.get("slot_fps", {}) if report.get("slot_fps", {}) is Dictionary else {}
	var anchor := String(report.get("anchorMode", "canvas_bottom_center"))
	var rel_root := dest_dir.trim_prefix("res://")
	if view_mode == HeroPackSpec.VIEW_THREE:
		for slot: String in slots:
			var slot_rate := _slot_fps(slot, fps_override, slot_fps)
			for view: String in HeroPackSpec.VIEWS:
				var folder := "%s/%s/%s" % [dest_dir, slot, view]
				var anim := _animation_from_folder("%s_%s" % [slot, view], folder, "%s/%s/%s" % [rel_root, slot, view], slot_rate, anchor, slot)
				if not anim.is_empty():
					animations.append(anim)
	else:
		for slot: String in slots:
			var slot_rate := _slot_fps(slot, fps_override, slot_fps)
			var folder := "%s/%s" % [dest_dir, slot]
			var anim := _animation_from_folder(slot, folder, "%s/%s" % [rel_root, slot], slot_rate, anchor, slot)
			if not anim.is_empty():
				animations.append(anim)
	return {
		"id": pack_id,
		"label": pack_id,
		"kind": "actor",
		"bodyScale": 1,
		"runtimeScale": 1,
		"animations": animations,
	}


static func _slot_fps(slot: String, fps_override: int, slot_fps: Dictionary) -> int:
	var per := int(slot_fps.get(slot, 0))
	if per > 0:
		return per
	if fps_override > 0:
		return fps_override
	return 0


static func _animation_from_folder(anim_id: String, folder: String, source: String, fps_override: int, anchor: String, slot: String) -> Dictionary:
	var frames: Array = []
	var dir := DirAccess.open(folder)
	if dir == null:
		return {}
	var names: PackedStringArray = PackedStringArray()
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.to_lower().ends_with(".png"):
			names.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	if names.is_empty():
		return {}
	for file_name: String in names:
		var path := "%s/%s" % [folder, file_name]
		var image := Image.new()
		var width := 0
		var height := 0
		if image.load(_abs(path)) == OK:
			width = image.get_width()
			height = image.get_height()
		frames.append({
			"id": file_name.get_basename(),
			"name": file_name,
			"path": path.trim_prefix("res://"),
			"assetRevision": 0,
			"duration": 1,
			"width": width,
			"height": height,
		})
	return {
		"id": anim_id,
		"name": anim_id,
		"type": "actor",
		"anchorMode": anchor if anchor != "" else "canvas_bottom_center",
		"fps": fps_override if fps_override > 0 else HeroPackSpec.default_fps(slot),
		"source": source.trim_prefix("res://"),
		"frames": frames,
	}


static func _write_profile(manifest_path: String, profile: Dictionary) -> void:
	var data := {"schemaVersion": 1, "profiles": []}
	if FileAccess.file_exists(manifest_path):
		var file := FileAccess.open(manifest_path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				data = parsed
	var profiles: Array = data.get("profiles", [])
	var next: Array = []
	var profile_id := String(profile.get("id", ""))
	for row: Variant in profiles:
		if row is Dictionary and String((row as Dictionary).get("id", "")) == profile_id:
			continue
		next.append(row)
	next.append(profile)
	data["profiles"] = next
	DirAccess.make_dir_recursive_absolute(_abs(manifest_path.get_base_dir()))
	var out := FileAccess.open(manifest_path, FileAccess.WRITE)
	if out == null:
		return
	out.store_string(JSON.stringify(data))
	out.close()


static func _portrait_path(dest_dir: String, view_mode: String) -> String:
	var direct := "%s/portrait.png" % dest_dir
	if FileAccess.file_exists(direct):
		return direct
	var idle := "%s/idle/side" % dest_dir if view_mode == HeroPackSpec.VIEW_THREE else "%s/idle" % dest_dir
	var dir := DirAccess.open(idle)
	if dir == null:
		return direct
	dir.list_dir_begin()
	var name := dir.get_next()
	var first := ""
	while name != "":
		if not dir.current_is_dir() and name.to_lower().ends_with(".png"):
			if first == "" or name < first:
				first = name
		name = dir.get_next()
	dir.list_dir_end()
	return "%s/%s" % [idle, first] if first != "" else direct


static func _register_catalog(catalog_path: String, pack_row: Dictionary, is_hero: bool) -> void:
	var data := {"packs": [], "heroes": []}
	if FileAccess.file_exists(catalog_path):
		var file := FileAccess.open(catalog_path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				data = parsed
	var pack_id := String(pack_row.get("id", ""))
	var packs: Array = []
	for row: Variant in data.get("packs", []):
		if row is Dictionary and String((row as Dictionary).get("id", "")) == pack_id:
			continue
		packs.append(row)
	packs.append(pack_row)
	data["packs"] = packs
	var heroes: Array = []
	for row: Variant in data.get("heroes", []):
		if row is Dictionary and String((row as Dictionary).get("id", "")) == pack_id:
			continue
		heroes.append(row)
	if is_hero:
		heroes.append({
			"id": pack_id,
			"title": String(pack_row.get("title", pack_id)),
			"base": String(pack_row.get("base", "ember_hero")),
		})
	data["heroes"] = heroes
	DirAccess.make_dir_recursive_absolute(_abs(catalog_path.get_base_dir()))
	var out := FileAccess.open(catalog_path, FileAccess.WRITE)
	if out == null:
		return
	out.store_string(JSON.stringify(data))
	out.close()


static func _abs(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path


static func _sanitize_id(raw: String) -> String:
	var text := raw.strip_edges().to_lower()
	var out := ""
	for i in range(text.length()):
		var ch := text.unicode_at(i)
		if (ch >= 97 and ch <= 122) or (ch >= 48 and ch <= 57) or ch == 95:
			out += char(ch)
		elif ch == 32 or ch == 45:
			out += "_"
	return out


static func _resolve_dest(pack_id: String, base: String, opts: Dictionary) -> String:
	var assets_root := String(opts.get("assets_root", ""))
	if assets_root != "":
		return "%s/%s" % [assets_root, pack_id]
	var catalog_path := String(opts.get("catalog_path", DEFAULT_CATALOG_PATH))
	HeroPackCatalog.load_from(catalog_path)
	var pack: Dictionary = HeroPackCatalog.pack_by_id(StringName(pack_id))
	if not pack.is_empty():
		var project_id := String(pack.get("frame_project_id", _project_for_base(String(pack.get("base", base)))))
		var folder := String(pack.get("frame_profile_id", pack_id))
		if folder == "":
			folder = pack_id
		return "res://xsxb_frame_tuner/workspace/projects/%s/assets/%s" % [project_id, folder]
	var use_base := base
	if use_base == "":
		var knight := "res://xsxb_frame_tuner/workspace/projects/emberline_frontier_07_final/assets/%s" % pack_id
		var assassin := "res://xsxb_frame_tuner/workspace/projects/emberline_enemies/assets/%s" % pack_id
		if FileAccess.file_exists("%s/pack.json" % knight):
			return knight
		if FileAccess.file_exists("%s/pack.json" % assassin):
			return assassin
		use_base = "ember_hero"
	var project := String(opts.get("project_id", _project_for_base(use_base)))
	return "res://xsxb_frame_tuner/workspace/projects/%s/assets/%s" % [project, pack_id]


static func _view_mode_of(dest: String) -> String:
	var meta := _read_json_file("%s/pack.json" % dest)
	var view_mode := String(meta.get("view_mode", HeroPackSpec.VIEW_THREE))
	if view_mode == "":
		return HeroPackSpec.VIEW_THREE
	return view_mode


static func _slot_folder(dest: String, slot: String, view: String, view_mode: String) -> String:
	if view_mode == HeroPackSpec.VIEW_THREE and view != "":
		return "%s/%s/%s" % [dest, slot, view]
	return "%s/%s" % [dest, slot]


static func _ensure_slot_dirs(dest: String, base: String, view_mode: String) -> void:
	var template: Dictionary = HeroPackSpec.template_for(base)
	var slots: Array = []
	for item: Variant in template.get("required", []):
		slots.append(String(item))
	for item: Variant in template.get("optional", []):
		slots.append(String(item))
	var views: Array[String] = []
	if view_mode == HeroPackSpec.VIEW_THREE:
		for view: String in HeroPackSpec.VIEWS:
			views.append(view)
	else:
		views.append("")
	for slot: String in slots:
		for view: String in views:
			var folder := _slot_folder(dest, slot, view, view_mode)
			DirAccess.make_dir_recursive_absolute(_abs(folder))


static func _catalog_row_from_disk(pack_id: String, dest: String, kind: String, title: String, base: String, opts: Dictionary) -> Dictionary:
	var meta := _read_json_file("%s/pack.json" % dest)
	var use_kind := String(meta.get("kind", kind))
	if use_kind == "":
		use_kind = kind
	var use_title := String(meta.get("title", title))
	if use_title == "":
		use_title = title if title != "" else pack_id
	var use_base := String(meta.get("base", base))
	if use_base == "":
		use_base = base if base != "" else "ember_hero"
	var view_mode := String(meta.get("view_mode", HeroPackSpec.VIEW_THREE))
	var project_id := String(opts.get("project_id", _project_for_base(use_base)))
	var row := {
		"id": pack_id,
		"kind": use_kind,
		"title": use_title,
		"base": use_base,
		"view_mode": view_mode if view_mode != "" else HeroPackSpec.VIEW_THREE,
		"frame_project_id": project_id,
		"frame_profile_id": pack_id,
		"portrait": _portrait_path(dest, view_mode if view_mode != "" else HeroPackSpec.VIEW_THREE),
		"complete": false,
	}
	if bool(meta.get("hide_held_overlay", false)):
		row["hide_held_overlay"] = true
	if bool(meta.get("selectable", true)) == false:
		row["selectable"] = false
	var into := String(meta.get("transform_into", ""))
	if into != "":
		row["transform_into"] = into
	return row


static func _list_png_names(folder: String) -> PackedStringArray:
	var names := PackedStringArray()
	var dir := DirAccess.open(folder)
	if dir == null:
		return names
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.to_lower().ends_with(".png") and not name.begins_with("."):
			names.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	return names


static func _sync_complete_flag(pack_id: String, opts: Dictionary) -> void:
	var dest := _resolve_dest(pack_id, "", opts)
	var report: Dictionary = HeroPackValidator.validate_dir(dest)
	var catalog_path := String(opts.get("catalog_path", DEFAULT_CATALOG_PATH))
	HeroPackCatalog.load_from(catalog_path)
	var pack: Dictionary = HeroPackCatalog.pack_by_id(StringName(pack_id))
	if pack.is_empty():
		return
	if bool(pack.get("complete", false)) and not bool(report.get("complete", false)):
		pack["complete"] = false
		_register_catalog(catalog_path, pack, false)
		HeroPackCatalog.load_from(catalog_path)


static func _unregister_catalog(catalog_path: String, pack_id: String) -> void:
	var data := {"packs": [], "heroes": []}
	if FileAccess.file_exists(catalog_path):
		var file := FileAccess.open(catalog_path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				data = parsed
	var packs: Array = []
	for row: Variant in data.get("packs", []):
		if row is Dictionary and String((row as Dictionary).get("id", "")) == pack_id:
			continue
		packs.append(row)
	var heroes: Array = []
	for row: Variant in data.get("heroes", []):
		if row is Dictionary and String((row as Dictionary).get("id", "")) == pack_id:
			continue
		heroes.append(row)
	data["packs"] = packs
	data["heroes"] = heroes
	var out := FileAccess.open(catalog_path, FileAccess.WRITE)
	if out == null:
		return
	out.store_string(JSON.stringify(data))
	out.close()


static func _remove_profile(manifest_path: String, pack_id: String) -> void:
	if not FileAccess.file_exists(manifest_path):
		return
	var data := {"schemaVersion": 1, "profiles": []}
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			data = parsed
	var next: Array = []
	for row: Variant in data.get("profiles", []):
		if row is Dictionary and String((row as Dictionary).get("id", "")) == pack_id:
			continue
		next.append(row)
	data["profiles"] = next
	var out := FileAccess.open(manifest_path, FileAccess.WRITE)
	if out == null:
		return
	out.store_string(JSON.stringify(data))
	out.close()


static func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


static func _rm_tree(path: String) -> void:
	var abs_path := _abs(path)
	if not DirAccess.dir_exists_absolute(abs_path) and not FileAccess.file_exists(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(abs_path)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		var child := "%s/%s" % [path, name]
		if dir.current_is_dir():
			_rm_tree(child)
		else:
			DirAccess.remove_absolute(_abs(child))
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(abs_path)


static func _zip_tree(packer: ZIPPacker, abs_dir: String, rel: String) -> void:
	var dir := DirAccess.open(abs_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name == "." or name == ".." or name.ends_with(".import") or name.begins_with("."):
			name = dir.get_next()
			continue
		var child_abs := "%s/%s" % [abs_dir, name]
		var child_rel := name if rel == "" else "%s/%s" % [rel, name]
		if dir.current_is_dir():
			_zip_tree(packer, child_abs, child_rel)
		else:
			packer.start_file(child_rel)
			packer.write_file(FileAccess.get_file_as_bytes(child_abs))
			packer.close_file()
		name = dir.get_next()
	dir.list_dir_end()

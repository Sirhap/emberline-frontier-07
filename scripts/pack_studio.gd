class_name PackStudio
extends CanvasLayer

## In-game hero/skin pack workshop. Desktop only.

signal catalog_changed
signal opened
signal closed

const EmberUiFont := preload("res://scripts/ember_ui_font.gd")
const HeroPackCatalog := preload("res://scripts/hero_pack_catalog.gd")
const HeroPackImporter := preload("res://scripts/hero_pack_importer.gd")
const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")
const HeroPackValidator := preload("res://scripts/hero_pack_validator.gd")

const STONE := Color("1a1410")
const GOLD := Color("d4a84b")
const INK := Color("f0d78c")
const MUTED := Color("cbbfa8")
const GREEN := Color("3cbf8f")
const RED := Color("c45c3e")

const ONE_SHOT := ["attack", "dash", "down", "jump", "attack_b", "skill_cast", "skill_bubble"]

var _pack_id := ""
var _slot := "idle"
var _view := "side"
var _frame_index := 0
var _held_pause := false
var _busy := false

var _pack_list: ItemList
var _slot_grid: GridContainer
var _frame_row: HBoxContainer
var _status: Label
var _missing: Label
var _title_edit: LineEdit
var _id_edit: LineEdit
var _draft_title: LineEdit
var _kind_opt: OptionButton
var _base_opt: OptionButton
var _preview_host: Control
var _actor: Node2D
var _readonly_note: Label
var _add_btn: Button
var _replace_btn: Button
var _remove_btn: Button
var _publish_btn: Button
var _delete_btn: Button
var _save_title_btn: Button
var _portrait_btn: Button
var _file_pngs: FileDialog
var _file_replace: FileDialog
var _file_zip: FileDialog
var _file_dir: FileDialog
var _file_portrait: FileDialog
var _file_export: FileDialog
var _png_mode := "append"


static func toggle_on(host: Node) -> void:
	if OS.has_feature("web") or host == null:
		return
	var existing := host.get_node_or_null("PackStudio")
	if existing == null:
		var packed := load("res://scenes/ui/pack_studio.tscn") as PackedScene
		if packed == null:
			return
		existing = packed.instantiate()
		existing.name = "PackStudio"
		existing.process_mode = Node.PROCESS_MODE_ALWAYS
		host.add_child(existing)
		if existing.has_method("open_studio"):
			existing.call("open_studio")
		return
	if existing.visible:
		existing.call("close_studio")
	else:
		existing.call("open_studio")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	visible = false
	_build()


func open_studio() -> void:
	if OS.has_feature("web"):
		return
	var tree := get_tree()
	if tree != null and not visible:
		_held_pause = tree.paused
		tree.paused = true
	visible = true
	HeroPackCatalog.load_from()
	_refresh_pack_list()
	opened.emit()


func close_studio() -> void:
	if not visible:
		return
	visible = false
	var tree := get_tree()
	if tree != null:
		tree.paused = _held_pause
	closed.emit()


func _build() -> void:
	var theme := Theme.new()
	theme.default_font = EmberUiFont.bundled()
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = theme
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	root.add_child(dim)

	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(24, 24)
	panel.size = Vector2(1232, 672)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = STONE
	panel_style.border_color = GOLD
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(panel)

	panel.add_child(_label("皮肤 / 英雄导入工坊", 22, INK, Vector2(16, 10), Vector2(520, 32)))

	var close_btn := _button("关闭", Vector2(1128, 10), Vector2(88, 32))
	close_btn.pressed.connect(close_studio)
	panel.add_child(close_btn)

	_pack_list = ItemList.new()
	_pack_list.name = "PackList"
	_pack_list.position = Vector2(16, 48)
	_pack_list.size = Vector2(240, 280)
	_pack_list.item_selected.connect(_on_pack_selected)
	panel.add_child(_pack_list)

	var import_dir := _button("整包文件夹", Vector2(16, 336), Vector2(116, 32))
	import_dir.pressed.connect(func() -> void: _file_dir.popup_centered_ratio(0.7))
	panel.add_child(import_dir)
	var import_zip := _button("整包 zip", Vector2(140, 336), Vector2(116, 32))
	import_zip.pressed.connect(func() -> void: _file_zip.popup_centered_ratio(0.7))
	panel.add_child(import_zip)

	panel.add_child(_label("新建草稿", 14, MUTED, Vector2(16, 376), Vector2(240, 20)))
	_id_edit = _line("gold_knight", Vector2(16, 396), Vector2(240, 28))
	_id_edit.placeholder_text = "id 字母数字"
	panel.add_child(_id_edit)
	_draft_title = _line("金甲骑士", Vector2(16, 428), Vector2(240, 28))
	_draft_title.placeholder_text = "中文标题"
	panel.add_child(_draft_title)
	_kind_opt = OptionButton.new()
	_kind_opt.position = Vector2(16, 460)
	_kind_opt.size = Vector2(116, 28)
	_kind_opt.add_item("皮肤", 0)
	_kind_opt.add_item("新英雄", 1)
	panel.add_child(_kind_opt)
	_base_opt = OptionButton.new()
	_base_opt.position = Vector2(140, 460)
	_base_opt.size = Vector2(116, 28)
	_base_opt.add_item("骑士", 0)
	_base_opt.add_item("刺客", 1)
	panel.add_child(_base_opt)
	var draft_btn := _button("建草稿", Vector2(16, 496), Vector2(240, 32))
	draft_btn.pressed.connect(_create_draft)
	panel.add_child(draft_btn)

	_readonly_note = _label("", 13, RED, Vector2(16, 536), Vector2(240, 40))
	_readonly_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_readonly_note)

	var slot_scroll := ScrollContainer.new()
	slot_scroll.position = Vector2(272, 48)
	slot_scroll.size = Vector2(640, 280)
	panel.add_child(slot_scroll)
	_slot_grid = GridContainer.new()
	_slot_grid.columns = 4
	_slot_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_scroll.add_child(_slot_grid)

	var frame_scroll := ScrollContainer.new()
	frame_scroll.position = Vector2(272, 336)
	frame_scroll.size = Vector2(640, 120)
	panel.add_child(frame_scroll)
	_frame_row = HBoxContainer.new()
	_frame_row.add_theme_constant_override("separation", 6)
	frame_scroll.add_child(_frame_row)

	_add_btn = _button("添加 PNG", Vector2(272, 464), Vector2(120, 32))
	_add_btn.pressed.connect(func() -> void:
		_png_mode = "append"
		_file_pngs.popup_centered_ratio(0.8)
	)
	panel.add_child(_add_btn)
	_replace_btn = _button("替换选中", Vector2(400, 464), Vector2(120, 32))
	_replace_btn.pressed.connect(func() -> void: _file_replace.popup_centered_ratio(0.8))
	panel.add_child(_replace_btn)
	_remove_btn = _button("删除选中", Vector2(528, 464), Vector2(120, 32))
	_remove_btn.pressed.connect(_remove_selected_frame)
	panel.add_child(_remove_btn)
	_portrait_btn = _button("立绘", Vector2(656, 464), Vector2(80, 32))
	_portrait_btn.pressed.connect(func() -> void: _file_portrait.popup_centered_ratio(0.8))
	panel.add_child(_portrait_btn)
	var replace_clip := _button("整段替换", Vector2(744, 464), Vector2(100, 32))
	replace_clip.pressed.connect(func() -> void:
		_png_mode = "replace"
		_file_pngs.popup_centered_ratio(0.8)
	)
	panel.add_child(replace_clip)

	_status = _label("", 14, MUTED, Vector2(272, 504), Vector2(640, 44))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_status)
	_missing = _label("", 13, RED, Vector2(272, 548), Vector2(640, 108))
	_missing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_missing)

	_preview_host = Control.new()
	_preview_host.name = "PreviewHost"
	_preview_host.position = Vector2(928, 56)
	_preview_host.size = Vector2(280, 272)
	_preview_host.clip_contents = true
	panel.add_child(_preview_host)
	var preview_bg := ColorRect.new()
	preview_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_bg.color = Color("0c1018")
	_preview_host.add_child(preview_bg)
	panel.add_child(_label("预览", 14, MUTED, Vector2(928, 36), Vector2(80, 20)))

	panel.add_child(_label("标题", 13, MUTED, Vector2(928, 336), Vector2(80, 20)))
	_title_edit = _line("", Vector2(928, 356), Vector2(196, 28))
	panel.add_child(_title_edit)
	_save_title_btn = _button("存", Vector2(1130, 356), Vector2(78, 28))
	_save_title_btn.pressed.connect(_save_title)
	panel.add_child(_save_title_btn)

	_publish_btn = _button("上架", Vector2(928, 396), Vector2(132, 36))
	_publish_btn.pressed.connect(_publish)
	panel.add_child(_publish_btn)
	var export_btn := _button("导出 zip", Vector2(1072, 396), Vector2(136, 36))
	export_btn.pressed.connect(func() -> void: _file_export.popup_centered_ratio(0.7))
	panel.add_child(export_btn)
	_delete_btn = _button("删除包", Vector2(928, 440), Vector2(280, 32))
	_delete_btn.pressed.connect(_delete_pack)
	panel.add_child(_delete_btn)

	_file_pngs = _make_dialog(FileDialog.FILE_MODE_OPEN_FILES, PackedStringArray(["*.png"]))
	_file_pngs.files_selected.connect(_on_pngs_picked)
	_file_replace = _make_dialog(FileDialog.FILE_MODE_OPEN_FILE, PackedStringArray(["*.png"]))
	_file_replace.file_selected.connect(_on_replace_picked)
	_file_zip = _make_dialog(FileDialog.FILE_MODE_OPEN_FILE, PackedStringArray(["*.zip"]))
	_file_zip.file_selected.connect(_on_pack_file)
	_file_dir = _make_dialog(FileDialog.FILE_MODE_OPEN_DIR, PackedStringArray())
	_file_dir.dir_selected.connect(_on_pack_file)
	_file_portrait = _make_dialog(FileDialog.FILE_MODE_OPEN_FILE, PackedStringArray(["*.png"]))
	_file_portrait.file_selected.connect(_on_portrait_picked)
	_file_export = _make_dialog(FileDialog.FILE_MODE_SAVE_FILE, PackedStringArray(["*.zip"]))
	_file_export.file_selected.connect(_on_export_picked)

	if OS.has_feature("web"):
		import_dir.visible = false
		import_zip.visible = false
		draft_btn.visible = false


func _make_dialog(mode: FileDialog.FileMode, filters: PackedStringArray) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.file_mode = mode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.unresizable = false
	for filter: String in filters:
		dialog.add_filter(filter, filter.trim_prefix("*."))
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialog)
	return dialog


func _refresh_pack_list() -> void:
	_pack_list.clear()
	var selected := _pack_id
	var idx := 0
	var pick := 0
	for row: Dictionary in HeroPackCatalog.all_packs():
		var pack_id := String(row.get("id", ""))
		var title := String(row.get("title", pack_id))
		var complete := bool(row.get("complete", false))
		var builtin := HeroPackImporter.is_builtin(pack_id)
		var mark := "内置" if builtin else ("完整" if complete else "草稿")
		_pack_list.add_item("%s  %s  [%s]" % [title, pack_id, mark])
		_pack_list.set_item_metadata(idx, pack_id)
		if pack_id == selected:
			pick = idx
		idx += 1
	if _pack_list.item_count == 0:
		_pack_id = ""
		return
	_pack_list.select(pick)
	_on_pack_selected(pick)


func _on_pack_selected(index: int) -> void:
	if index < 0 or index >= _pack_list.item_count:
		return
	_pack_id = String(_pack_list.get_item_metadata(index))
	_frame_index = 0
	var pack: Dictionary = HeroPackCatalog.pack_by_id(StringName(_pack_id))
	_title_edit.text = String(pack.get("title", _pack_id))
	var readonly := HeroPackImporter.is_builtin(_pack_id)
	_readonly_note.text = "内置包只读，避免覆盖默认骑士/刺客片。" if readonly else ""
	_set_edit_enabled(not readonly)
	_rebuild_slot_grid()
	_refresh_frames()
	_refresh_missing()
	_reload_preview()


func _set_edit_enabled(on: bool) -> void:
	_add_btn.disabled = not on
	_replace_btn.disabled = not on
	_remove_btn.disabled = not on
	_publish_btn.disabled = not on
	_delete_btn.disabled = not on
	_save_title_btn.disabled = not on
	_portrait_btn.disabled = not on
	_title_edit.editable = on


func _rebuild_slot_grid() -> void:
	var stale := _slot_grid.get_children()
	for child in stale:
		_slot_grid.remove_child(child)
		child.free()
	if _pack_id == "":
		return
	var dest := HeroPackImporter.pack_assets_dir(_pack_id)
	var report: Dictionary = HeroPackValidator.validate_dir(dest) if FileAccess.file_exists("%s/pack.json" % dest) else {}
	var pack: Dictionary = HeroPackCatalog.pack_by_id(StringName(_pack_id))
	var base := String(pack.get("base", "ember_hero"))
	if base == "assassin" or _pack_id == "assassin":
		base = "assassin"
	elif HeroPackImporter.is_builtin(_pack_id):
		base = "ember_hero" if _pack_id == "ember_hero" else "assassin"
	var template: Dictionary = HeroPackSpec.template_for(base)
	var slots: Array = []
	for item: Variant in template.get("required", []):
		slots.append({"id": String(item), "need": true})
	for item: Variant in template.get("optional", []):
		slots.append({"id": String(item), "need": false})
	var view_mode := String(pack.get("view_mode", HeroPackSpec.VIEW_THREE))
	var views: Array[String] = []
	if view_mode == HeroPackSpec.VIEW_THREE:
		for view: String in HeroPackSpec.VIEWS:
			views.append(view)
	else:
		views.append("")
	_slot_grid.add_child(_mini("动作", MUTED))
	for view: String in views:
		_slot_grid.add_child(_mini("侧面" if view == "" else view, MUTED))
	var slot_map := {}
	for row: Variant in report.get("slots", []):
		if row is Dictionary:
			slot_map[String((row as Dictionary).get("slot", ""))] = row
	if _slot == "" and not slots.is_empty():
		_slot = String((slots[0] as Dictionary)["id"])
		_view = views[0] if views[0] != "" else "side"
	for spec: Dictionary in slots:
		var slot := String(spec["id"])
		var need := bool(spec["need"])
		_slot_grid.add_child(_mini(slot, INK))
		var counts: Dictionary = {}
		if slot_map.has(slot):
			counts = ((slot_map[slot] as Dictionary).get("views", {}) as Dictionary)
		for view: String in views:
			var key := "side" if view == "" else view
			var n := int(counts.get(key, 0))
			if n == 0:
				n = HeroPackImporter.list_frames(_pack_id, slot, key).size()
			var color := GREEN if n > 0 else (RED if need else MUTED)
			var cell := _button("%d" % n, Vector2.ZERO, Vector2(64, 28))
			cell.modulate = color
			if slot == _slot and key == _view:
				cell.modulate = Color(1.15, 1.15, 1.0)
			var pick_slot := slot
			var pick_view := key
			cell.pressed.connect(func() -> void:
				_slot = pick_slot
				_view = pick_view
				_frame_index = 0
				_rebuild_slot_grid()
				_refresh_frames()
				_reload_preview()
			)
			_slot_grid.add_child(cell)


func _refresh_frames() -> void:
	var stale := _frame_row.get_children()
	for child in stale:
		_frame_row.remove_child(child)
		child.free()
	if _pack_id == "":
		return
	var frames: PackedStringArray = HeroPackImporter.list_frames(_pack_id, _slot, _view)
	if _frame_index >= frames.size():
		_frame_index = maxi(0, frames.size() - 1)
	for i in range(frames.size()):
		var path := String(frames[i])
		var wrap := Button.new()
		wrap.custom_minimum_size = Vector2(88, 104)
		wrap.toggle_mode = true
		wrap.button_pressed = i == _frame_index
		wrap.text = "%d" % (i + 1)
		var tex := TextureRect.new()
		tex.position = Vector2(8, 8)
		tex.size = Vector2(72, 72)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture = _thumb(path)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(tex)
		var idx := i
		wrap.pressed.connect(func() -> void:
			_frame_index = idx
			_refresh_frames()
		)
		_frame_row.add_child(wrap)
	_status.text = "%s  %s/%s  %d 帧" % [_pack_id, _slot, _view, frames.size()]


func _refresh_missing() -> void:
	if _pack_id == "":
		_missing.text = ""
		return
	if HeroPackImporter.is_builtin(_pack_id):
		_missing.add_theme_color_override("font_color", MUTED)
		_missing.text = "内置包只读，避免覆盖默认骑士/刺客片。"
		return
	var dest := HeroPackImporter.pack_assets_dir(_pack_id)
	if not FileAccess.file_exists("%s/pack.json" % dest):
		_missing.text = "没有 pack.json"
		return
	var report: Dictionary = HeroPackValidator.validate_dir(dest)
	var missing: Array = report.get("missing", [])
	if missing.is_empty():
		_missing.text = "校验通过，可以上架。" if bool(report.get("complete", false)) else "未标完整。"
		_missing.add_theme_color_override("font_color", GREEN)
		return
	_missing.add_theme_color_override("font_color", RED)
	var parts: PackedStringArray = PackedStringArray()
	for item: Variant in missing:
		parts.append(String(item))
	_missing.text = "缺：%s" % "；".join(parts)


func _reload_preview() -> void:
	if _actor != null and is_instance_valid(_actor):
		_actor.queue_free()
		_actor = null
	if _pack_id == "" or _preview_host == null:
		return
	var packed := load("res://xsxb_frame_tuner/runtime/xsxb_frame_actor.tscn") as PackedScene
	if packed == null:
		return
	var pack: Dictionary = HeroPackCatalog.pack_by_id(StringName(_pack_id))
	_actor = packed.instantiate() as Node2D
	_actor.process_mode = Node.PROCESS_MODE_ALWAYS
	_actor.position = Vector2(140, 250)
	_actor.set("frame_project_id", String(pack.get("frame_project_id", "emberline_frontier_07_final")))
	_actor.set("frame_profile_id", String(pack.get("frame_profile_id", _pack_id)))
	var clip := _clip_name()
	_actor.set("frame_animation", clip)
	_actor.set("use_frame_boxes", false)
	_actor.set("fallback_visual_scale", 0.34)
	_actor.set("autoplay", false)
	_preview_host.add_child(_actor)
	if _actor.has_method("_load_frame_runtime"):
		_actor.call("_load_frame_runtime")
	var loop := ONE_SHOT.find(_slot) < 0
	if _actor.has_method("play_frame_animation"):
		_actor.call("play_frame_animation", clip, loop, true)


func _clip_name() -> String:
	var pack: Dictionary = HeroPackCatalog.pack_by_id(StringName(_pack_id))
	var view_mode := String(pack.get("view_mode", HeroPackSpec.VIEW_THREE))
	var base := String(pack.get("base", "ember_hero"))
	if _pack_id == "assassin":
		base = "assassin"
	return HeroPackSpec.clip_name(_slot, base, view_mode, _view if view_mode == HeroPackSpec.VIEW_THREE else "")


func _create_draft() -> void:
	if _busy or OS.has_feature("web"):
		return
	var kind := "hero" if _kind_opt.selected == 1 else "skin"
	var base := "assassin" if _base_opt.selected == 1 else "ember_hero"
	var result: Dictionary = HeroPackImporter.create_draft(_id_edit.text, _draft_title.text, kind, base)
	if not bool(result.get("ok", false)):
		_status.text = "建草稿失败：%s" % String(result.get("error", ""))
		return
	_pack_id = String((result.get("pack", {}) as Dictionary).get("id", _id_edit.text))
	_slot = "idle"
	_view = "side"
	_after_catalog("已建草稿 %s（未完整，选人不能装备）" % _pack_id)


func _on_pngs_picked(paths: PackedStringArray) -> void:
	if HeroPackImporter.is_builtin(_pack_id):
		return
	var result: Dictionary = HeroPackImporter.add_frames(_pack_id, _slot, _view, paths, _png_mode)
	_status.text = "已写入 %s 帧" % str(result.get("copied", 0)) if bool(result.get("ok", false)) else "加帧失败：%s" % String(result.get("error", ""))
	_after_catalog(_status.text)


func _on_replace_picked(path: String) -> void:
	if HeroPackImporter.is_builtin(_pack_id):
		return
	var result: Dictionary = HeroPackImporter.replace_frame(_pack_id, _slot, _view, _frame_index, path)
	_status.text = "已替换第 %d 帧" % (_frame_index + 1) if bool(result.get("ok", false)) else "替换失败：%s" % String(result.get("error", ""))
	_after_catalog(_status.text)


func _remove_selected_frame() -> void:
	if HeroPackImporter.is_builtin(_pack_id):
		return
	var result: Dictionary = HeroPackImporter.remove_frame(_pack_id, _slot, _view, _frame_index)
	_status.text = "已删帧" if bool(result.get("ok", false)) else "删帧失败：%s" % String(result.get("error", ""))
	_after_catalog(_status.text)


func _on_portrait_picked(path: String) -> void:
	if HeroPackImporter.is_builtin(_pack_id):
		return
	var result: Dictionary = HeroPackImporter.set_portrait(_pack_id, path)
	_status.text = "已设立绘" if bool(result.get("ok", false)) else "立绘失败"
	_after_catalog(_status.text)


func _on_pack_file(path: String) -> void:
	if OS.has_feature("web"):
		return
	var result: Dictionary = HeroPackImporter.import_pack(path)
	if not bool(result.get("ok", false)):
		var report: Dictionary = result.get("report", {}) as Dictionary
		_status.text = "整包失败：%s %s" % [String(result.get("error", "")), str(report.get("missing", []))]
		return
	_pack_id = String((result.get("pack", {}) as Dictionary).get("id", ""))
	_after_catalog("整包已入库 %s" % _pack_id)


func _save_title() -> void:
	if HeroPackImporter.is_builtin(_pack_id):
		return
	var result: Dictionary = HeroPackImporter.set_title(_pack_id, _title_edit.text)
	_status.text = "标题已保存" if bool(result.get("ok", false)) else "标题失败"
	_after_catalog(_status.text)


func _publish() -> void:
	if HeroPackImporter.is_builtin(_pack_id):
		return
	var result: Dictionary = HeroPackImporter.publish(_pack_id)
	if bool(result.get("ok", false)):
		_after_catalog("已上架，选人可装备")
	else:
		_refresh_missing()
		_status.text = "还不能上架：%s" % String(result.get("error", ""))


func _delete_pack() -> void:
	if HeroPackImporter.is_builtin(_pack_id):
		_status.text = "不能删内置包"
		return
	var gone := _pack_id
	var result: Dictionary = HeroPackImporter.delete_imported(gone)
	_pack_id = ""
	_after_catalog("已删除 %s" % gone if bool(result.get("ok", false)) else "删除失败")


func _on_export_picked(path: String) -> void:
	if _pack_id == "":
		return
	var zip_path := path if path.to_lower().ends_with(".zip") else "%s.zip" % path
	var result: Dictionary = HeroPackImporter.export_zip(_pack_id, zip_path)
	_status.text = "已导出 %s" % zip_path if bool(result.get("ok", false)) else "导出失败"


func _after_catalog(message: String) -> void:
	HeroPackCatalog.load_from()
	_status.text = message
	_refresh_pack_list()
	catalog_changed.emit()


func _thumb(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE or key.keycode == KEY_F1 or key.keycode == KEY_QUOTELEFT:
		close_studio()
		get_viewport().set_input_as_handled()


func _label(text: String, size: int, color: Color, pos: Vector2, box: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = box
	label.add_theme_font_override("font", EmberUiFont.bundled())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _mini(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(72, 28)
	label.add_theme_font_override("font", EmberUiFont.bundled())
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	return label


func _line(text: String, pos: Vector2, box: Vector2) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = text
	edit.position = pos
	edit.size = box
	edit.add_theme_font_override("font", EmberUiFont.bundled())
	edit.add_theme_font_size_override("font_size", 14)
	return edit


func _button(text: String, pos: Vector2, box: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = box
	btn.custom_minimum_size = box
	btn.add_theme_font_override("font", EmberUiFont.bundled())
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color("e8d9a8"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2a2110")
	style.border_color = GOLD
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("3a3018")
	btn.add_theme_stylebox_override("hover", hover)
	return btn

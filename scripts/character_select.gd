class_name CharacterSelect
extends CanvasLayer

## Cold-boot character pick. Style from the gallery reference.
## Playable: knight + assassin. Extra slots stay locked.

signal hero_confirmed(hero_id: StringName)
signal import_pressed

const EmberUiFont := preload("res://scripts/ember_ui_font.gd")
const HeroPackCatalog := preload("res://scripts/hero_pack_catalog.gd")
const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")

const KNIGHT_SPRITE := "res://xsxb_frame_tuner/workspace/projects/emberline_frontier_07_final/assets/ember_hero/idle/breathe_00.png"
const ASSASSIN_SPRITE := "res://xsxb_frame_tuner/workspace/projects/emberline_enemies/assets/ember_assassin/idle/breathe_00.png"

const CYAN := Color("1ae0d0")
const SELECT_FILL := Color("161c28")
const IDLE_FILL := Color("1a1528")
const INK := Color("f4f0ff")
const MUTED := Color("9aa0b8")

var _picked: StringName = &"ember_hero"
var _hint: Label
var _root: Control
var _import_btn: Button
var _cards: Array = []
var _playable: Array[StringName] = []
var _skin_by_hero: Dictionary = {}
var _picker: Control
var _preview_pack: StringName = &""


func _ready() -> void:
	layer = 40
	name = "CharacterSelect"
	_build()
	highlight(_picked)


func configure(profile: Dictionary) -> void:
	var last := StringName(str(profile.get("last_selected_hero", "ember_hero")))
	if not HeroDefinitionCatalog.has_id(last):
		last = &"ember_hero"
	_picked = last
	var skins: Variant = profile.get("last_skin", {})
	if skins is Dictionary:
		_skin_by_hero = (skins as Dictionary).duplicate(true)
		for key: Variant in _skin_by_hero.keys():
			var hid := StringName(str(key))
			var sid := StringName(str(_skin_by_hero[key]))
			_skin_by_hero[str(key)] = String(HeroPackCatalog.resolve_selectable_skin(hid, sid))
	if is_node_ready():
		_apply_card_portraits()
		highlight(_picked)


func selected_hero_id() -> StringName:
	return _picked


func selected_skin_id() -> StringName:
	var stored := StringName(str(_skin_by_hero.get(String(_picked), "")))
	if HeroPackCatalog.selectable_skin_ids(_picked).has(stored):
		return stored
	return HeroPackCatalog.default_skin_id(_picked)


func select_hero(hero_id: StringName) -> void:
	if not _playable.has(hero_id):
		_set_hint("暂未开放")
		return
	_picked = hero_id
	_hide_skin_picker()
	_apply_card_portraits()
	highlight(_picked)
	_set_hint("")


func confirm_current() -> void:
	if not _playable.has(_picked):
		_set_hint("请先选择人物")
		return
	hero_confirmed.emit(_picked)


func refresh_from_catalog() -> void:
	if _root == null:
		return
	_rebuild_cards()
	highlight(_picked)
	_apply_card_portraits()


func highlight(hero_id: StringName) -> void:
	for card: Variant in _cards:
		var slot := card as _HeroCard
		slot.set_selected(slot.hero_id == hero_id and not slot.locked)
	_layout_cards()


func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var theme := Theme.new()
	theme.default_font = EmberUiFont.bundled()
	_root.theme = theme
	add_child(_root)

	var stage := _Stage.new()
	stage.name = "Stage"
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(stage)

	var title := _label("角色选择", 28, INK)
	title.name = "Title"
	title.position = Vector2(36, 16)
	title.size = Vector2(280, 40)
	_root.add_child(title)

	_import_btn = Button.new()
	_import_btn.name = "ImportButton"
	_import_btn.text = "导入"
	_import_btn.position = Vector2(320, 16)
	_import_btn.size = Vector2(88, 32)
	_import_btn.custom_minimum_size = Vector2(88, 32)
	_import_btn.add_theme_font_override("font", EmberUiFont.bundled())
	_import_btn.add_theme_font_size_override("font_size", 16)
	_import_btn.add_theme_color_override("font_color", Color("041016"))
	var import_style := StyleBoxFlat.new()
	import_style.bg_color = CYAN
	import_style.set_corner_radius_all(2)
	_import_btn.add_theme_stylebox_override("normal", import_style)
	_import_btn.pressed.connect(func() -> void: import_pressed.emit())
	_import_btn.visible = not OS.has_feature("web")
	_root.add_child(_import_btn)

	var sort_l := _label("默认", 16, MUTED)
	sort_l.position = Vector2(1120, 22)
	sort_l.size = Vector2(120, 28)
	sort_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(sort_l)

	_hint = _label("", 16, Color("ff8ab8"))
	_hint.name = "Hint"
	_hint.position = Vector2(36, 680)
	_hint.size = Vector2(1200, 28)
	_root.add_child(_hint)
	_rebuild_cards()


func _rebuild_cards() -> void:
	for card: Variant in _cards:
		var slot := card as _HeroCard
		if slot != null and is_instance_valid(slot):
			slot.queue_free()
	_cards.clear()
	if _root == null:
		return
	var defs: Array = _card_defs()
	for spec: Dictionary in defs:
		var card := _HeroCard.new()
		card.name = "Slot_%s" % String(spec["id"])
		card.setup(spec["id"], spec["title"], spec["sprite"], spec["locked"])
		card.clicked.connect(select_hero)
		card.deploy_pressed.connect(confirm_current)
		card.detail_pressed.connect(_on_detail)
		card.skin_pressed.connect(_on_skin)
		_root.add_child(card)
		_cards.append(card)
	_layout_cards()


func _layout_cards() -> void:
	var x := 16.0
	for card: Variant in _cards:
		var slot := card as _HeroCard
		var wide := slot.selected
		var w := 300.0 if wide else 238.0
		var h := 568.0 if wide else 500.0
		var y := 78.0 if wide else 118.0
		slot.position = Vector2(x, y)
		slot.size = Vector2(w, h)
		slot.refresh()
		x += w - 6.0


func _card_defs() -> Array:
	_playable = HeroPackCatalog.playable_hero_ids()
	var defs: Array = []
	for hero_id: StringName in _playable:
		var def: Dictionary = HeroDefinitionCatalog.get_def(hero_id)
		var title := String(def.get("title", hero_id))
		if hero_id == &"ember_hero":
			title = "余烬骑士"
		elif hero_id == &"assassin":
			title = "影刃刺客"
		defs.append({
			"id": hero_id,
			"title": title,
			"sprite": _portrait_for(hero_id),
			"locked": false,
		})
	var locked_n := maxi(0, 5 - defs.size())
	for i in range(locked_n):
		defs.append({
			"id": StringName("locked_%d" % i),
			"title": "暂未开放",
			"sprite": "",
			"locked": true,
		})
	return defs


func _on_detail(hero_id: StringName) -> void:
	var combat := HeroDefinitionCatalog.combat_base(hero_id)
	match combat:
		&"assassin":
			_set_hint("刺客：开局剑，冲刺槽放影分身")
		&"ember_hero":
			_set_hint("骑士：开局剑，冲刺带伤；霜晶战士技能可变身")
		_:
			_set_hint("暂未开放")


func _on_skin() -> void:
	if not _playable.has(_picked):
		_set_hint("暂未开放")
		return
	_show_skin_picker()


func selected_skins() -> Dictionary:
	return _skin_by_hero.duplicate(true)


func _portrait_for(hero_id: StringName, pack_id: StringName = &"") -> String:
	var skin := pack_id
	if skin == &"":
		var stored := StringName(str(_skin_by_hero.get(String(hero_id), "")))
		if HeroPackCatalog.selectable_skin_ids(hero_id).has(stored):
			skin = stored
		else:
			skin = HeroPackCatalog.default_skin_id(hero_id)
	var path := HeroPackCatalog.portrait_path(skin)
	if path == "" or not ResourceLoader.exists(path):
		return HeroPackCatalog.portrait_path(HeroPackCatalog.default_skin_id(hero_id))
	return path


func _skin_title_for(hero_id: StringName, pack_id: StringName = &"") -> String:
	var skin := pack_id
	if skin == &"":
		var stored := StringName(str(_skin_by_hero.get(String(hero_id), "")))
		if HeroPackCatalog.selectable_skin_ids(hero_id).has(stored):
			skin = stored
		else:
			skin = HeroPackCatalog.default_skin_id(hero_id)
	var title := String(HeroPackCatalog.pack_by_id(skin).get("title", ""))
	if title == "" or title == "默认":
		return ""
	return title


func _apply_card_portraits() -> void:
	for card: Variant in _cards:
		var slot := card as _HeroCard
		if slot == null or slot.locked:
			continue
		var preview := _preview_pack if slot.hero_id == _picked and _preview_pack != &"" else &""
		slot.set_art(_portrait_for(slot.hero_id, preview))
		slot.set_skin_caption(_skin_title_for(slot.hero_id, preview))


func _card_for(hero_id: StringName) -> _HeroCard:
	for card: Variant in _cards:
		var slot := card as _HeroCard
		if slot != null and slot.hero_id == hero_id:
			return slot
	return null


func _show_skin_picker() -> void:
	_hide_skin_picker()
	var skins: Array = HeroPackCatalog.skins_for(_picked, true, true)
	if skins.is_empty():
		skins = [HeroPackCatalog.pack_by_id(HeroPackCatalog.default_skin_id(_picked))]
	var tile_w := 132.0
	var tile_h := 176.0
	var cols := mini(skins.size(), 3)
	if cols < 1:
		cols = 1
	var rows := ceili(float(skins.size()) / float(cols))
	var pw := 24.0 + float(cols) * (tile_w + 8.0)
	var ph := 52.0 + float(rows) * (tile_h + 8.0) + 44.0
	var host := _card_for(_picked)
	var px := 36.0
	var py := 90.0
	if host != null:
		px = host.position.x + host.size.x + 10.0
		py = host.position.y
		if px + pw > 1264.0:
			px = host.position.x - pw - 10.0
		if px < 8.0:
			px = 8.0
			py = clampf(host.position.y + host.size.y - ph, 8.0, 720.0 - ph - 8.0)
	var panel := Panel.new()
	panel.name = "SkinPicker"
	panel.position = Vector2(px, py)
	panel.size = Vector2(pw, ph)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("12101c")
	style.border_color = CYAN
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	var label := _label("皮肤", 16, INK)
	label.position = Vector2(12, 8)
	label.size = Vector2(pw - 24.0, 24)
	panel.add_child(label)
	var current := selected_skin_id()
	var i := 0
	for row: Dictionary in skins:
		var col := i % cols
		var r := int(i / cols)
		var tile := _make_skin_tile(row, current)
		tile.position = Vector2(12.0 + float(col) * (tile_w + 8.0), 36.0 + float(r) * (tile_h + 8.0))
		tile.size = Vector2(tile_w, tile_h)
		panel.add_child(tile)
		i += 1
	var close := Button.new()
	close.name = "CloseButton"
	close.text = "关闭"
	close.position = Vector2(pw - 92.0, ph - 40.0)
	close.size = Vector2(80, 32)
	close.add_theme_font_override("font", EmberUiFont.bundled())
	close.add_theme_font_size_override("font_size", 14)
	close.pressed.connect(_hide_skin_picker)
	panel.add_child(close)
	panel.mouse_exited.connect(_on_picker_mouse_exited)
	var root := get_node_or_null("Root")
	if root != null:
		root.add_child(panel)
	else:
		add_child(panel)
	_picker = panel
	_set_hint("悬停预览，点击装备")


func _make_skin_tile(row: Dictionary, current: StringName) -> Control:
	var pack_id := StringName(str(row.get("id", "")))
	var title := String(row.get("title", pack_id))
	var tile := Panel.new()
	tile.name = "SkinChip_%s" % String(pack_id)
	tile.set_meta("pack_id", pack_id)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	_paint_skin_tile(tile, pack_id == current)
	var art := TextureRect.new()
	art.name = "Art"
	art.position = Vector2(8, 8)
	art.size = Vector2(116, 128)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := HeroPackCatalog.portrait_path(pack_id)
	if path != "" and ResourceLoader.exists(path):
		art.texture = load(path) as Texture2D
	tile.add_child(art)
	var caption := _label(title, 14, INK)
	caption.name = "Title"
	caption.position = Vector2(4, 140)
	caption.size = Vector2(124, 28)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_child(caption)
	tile.mouse_entered.connect(_preview_skin.bind(pack_id))
	tile.gui_input.connect(_on_skin_tile_input.bind(pack_id))
	return tile


func _paint_skin_tile(tile: Panel, on: bool) -> void:
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color("1a2430") if on else Color("16141f")
	chip.border_color = CYAN if on else Color("3a4254")
	chip.set_border_width_all(2 if on else 1)
	chip.set_corner_radius_all(2)
	tile.add_theme_stylebox_override("panel", chip)


func _refresh_picker_highlights() -> void:
	if _picker == null or not is_instance_valid(_picker):
		return
	var current := selected_skin_id()
	for child in _picker.get_children():
		if not (child is Panel):
			continue
		var tile := child as Panel
		if not str(tile.name).begins_with("SkinChip_"):
			continue
		var pack_id := StringName(str(tile.get_meta("pack_id", "")))
		_paint_skin_tile(tile, pack_id == current)


func _on_skin_tile_input(event: InputEvent, pack_id: StringName) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			_pick_skin(pack_id)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_pick_skin(pack_id)
		get_viewport().set_input_as_handled()


func _preview_skin(pack_id: StringName) -> void:
	if not HeroPackCatalog.selectable_skin_ids(_picked).has(pack_id):
		return
	_preview_pack = pack_id
	_apply_card_portraits()


func _on_picker_mouse_exited() -> void:
	_preview_pack = &""
	_apply_card_portraits()


func _pick_skin(pack_id: StringName) -> void:
	if not HeroPackCatalog.selectable_skin_ids(_picked).has(pack_id):
		_set_hint("不完整，不能选")
		return
	_skin_by_hero[String(_picked)] = String(pack_id)
	_preview_pack = &""
	_apply_card_portraits()
	_refresh_picker_highlights()
	_set_hint("已选皮肤：%s" % String(HeroPackCatalog.pack_by_id(pack_id).get("title", pack_id)))


func _hide_skin_picker() -> void:
	_preview_pack = &""
	if _picker != null and is_instance_valid(_picker):
		_picker.queue_free()
	_picker = null
	_apply_card_portraits()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_LEFT, KEY_A:
			_cycle_hero(-1)
			get_viewport().set_input_as_handled()
		KEY_RIGHT, KEY_D:
			_cycle_hero(1)
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			confirm_current()
			get_viewport().set_input_as_handled()


func _cycle_hero(step: int) -> void:
	if _playable.is_empty():
		return
	var idx := _playable.find(_picked)
	if idx < 0:
		idx = 0
	idx = posmod(idx + step, _playable.size())
	select_hero(_playable[idx])


func _set_hint(text: String) -> void:
	if _hint != null:
		_hint.text = text


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", EmberUiFont.bundled())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


class _HeroCard extends Control:
	signal clicked(hero_id: StringName)
	signal deploy_pressed
	signal detail_pressed(hero_id: StringName)
	signal skin_pressed

	var hero_id: StringName = &""
	var display_name: String = ""
	var sprite_path: String = ""
	var locked: bool = false
	var selected: bool = false
	var _art: TextureRect
	var _name: Label
	var _skin_caption: Label
	var _ready_tag: Label
	var _detail: Button
	var _skin: Button
	var _deploy: Button


	func setup(id: StringName, title: String, path: String, is_locked: bool) -> void:
		hero_id = id
		display_name = title
		sprite_path = path
		locked = is_locked
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = false

		_name = Label.new()
		_name.text = title
		_name.position = Vector2(18, 12)
		_name.size = Vector2(180, 28)
		_name.add_theme_font_override("font", EmberUiFont.bundled())
		_name.add_theme_font_size_override("font_size", 18)
		_name.add_theme_color_override("font_color", INK)
		_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_name)

		_skin_caption = Label.new()
		_skin_caption.name = "SkinCaption"
		_skin_caption.position = Vector2(18, 34)
		_skin_caption.size = Vector2(180, 22)
		_skin_caption.add_theme_font_override("font", EmberUiFont.bundled())
		_skin_caption.add_theme_font_size_override("font_size", 13)
		_skin_caption.add_theme_color_override("font_color", MUTED)
		_skin_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_skin_caption)

		_ready_tag = Label.new()
		_ready_tag.text = "已准备"
		_ready_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_ready_tag.add_theme_font_override("font", EmberUiFont.bundled())
		_ready_tag.add_theme_font_size_override("font_size", 12)
		_ready_tag.add_theme_color_override("font_color", INK)
		_ready_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_ready_tag)

		_art = TextureRect.new()
		_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if path != "":
			_art.texture = load(path) as Texture2D
		add_child(_art)

		_detail = _chip("详细", false)
		_detail.pressed.connect(func() -> void: detail_pressed.emit(hero_id))
		add_child(_detail)
		_skin = _chip("皮肤", false)
		_skin.name = "SkinButton"
		_skin.pressed.connect(func() -> void: skin_pressed.emit())
		add_child(_skin)
		_deploy = _chip("已出战", false)
		_deploy.name = "StartButton"
		_deploy.pressed.connect(func() -> void: deploy_pressed.emit())
		add_child(_deploy)


	func set_selected(on: bool) -> void:
		selected = on


	func set_art(path: String) -> void:
		sprite_path = path
		if _art == null:
			return
		if path != "" and ResourceLoader.exists(path):
			_art.texture = load(path) as Texture2D
		else:
			_art.texture = null
		refresh()


	func set_skin_caption(text: String) -> void:
		if _skin_caption == null:
			return
		_skin_caption.text = text
		refresh()


	func refresh() -> void:
		var art_top := 56.0 if selected and _skin_caption != null and _skin_caption.text != "" else 48.0
		_art.position = Vector2(8, art_top)
		_art.size = Vector2(size.x - 24, size.y - art_top - 92.0)
		_art.visible = sprite_path != ""
		_ready_tag.visible = selected
		_ready_tag.position = Vector2(size.x - 92, 14)
		_ready_tag.size = Vector2(72, 22)
		if _skin_caption != null:
			_skin_caption.visible = selected and _skin_caption.text != ""
		_detail.visible = selected
		_skin.visible = selected
		_deploy.visible = selected
		_detail.position = Vector2(size.x - 268, size.y - 58)
		_skin.position = Vector2(size.x - 184, size.y - 58)
		_deploy.position = Vector2(size.x - 100, size.y - 58)
		_name.add_theme_color_override("font_color", MUTED if locked else INK)
		queue_redraw()


	func _chip(text: String, pending: bool) -> Button:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(76, 32)
		btn.size = Vector2(76, 32)
		btn.add_theme_font_override("font", EmberUiFont.bundled())
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color("8a9098") if pending else Color("041016"))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("2a3140") if pending else CYAN
		style.set_corner_radius_all(2)
		btn.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate() as StyleBoxFlat
		hover.bg_color = Color("3a4254") if pending else Color("7afff2")
		btn.add_theme_stylebox_override("hover", hover)
		return btn


	func _draw() -> void:
		var poly := _poly()
		var fill := SELECT_FILL if selected else (Color("143844") if locked else IDLE_FILL)
		draw_colored_polygon(poly, fill)
		if selected:
			_draw_diamonds(Color(0.10, 0.88, 0.82, 0.18))
		else:
			_draw_diamonds(Color(0.35, 0.16, 0.53, 0.25) if not locked else Color(0.1, 0.88, 0.82, 0.12))
		var closed := PackedVector2Array(poly)
		closed.append(poly[0])
		draw_polyline(closed, CYAN if selected else Color("4a3a68"), 3.5 if selected else 1.5)
		if locked:
			draw_colored_polygon(poly, Color(0.08, 0.55, 0.58, 0.42))
			_draw_lock_bar()
		if selected:
			draw_rect(Rect2(size.x - 90, 12, 76, 24), Color("0a0a12"))


	func _draw_diamonds(color: Color) -> void:
		var step := 22.0
		var y := 8.0
		while y < size.y:
			var x := 8.0 + int(y / step) % 2 * (step * 0.5)
			while x < size.x:
				draw_rect(Rect2(x, y, step * 0.5, step * 0.5), color, false, 1.0)
				x += step
			y += step


	func _draw_lock_bar() -> void:
		var y := size.y * 0.48
		draw_rect(Rect2(8, y, size.x - 16, 28), CYAN)
		draw_circle(Vector2(size.x * 0.5, y + 14), 8.0, Color("041016"))
		draw_arc(Vector2(size.x * 0.5, y + 10), 5.0, PI, TAU, 10, Color("041016"), 2.0)


	func _poly() -> PackedVector2Array:
		var w := size.x
		var h := size.y
		var s := 30.0
		return PackedVector2Array([
			Vector2(s, 0.0),
			Vector2(w, 0.0),
			Vector2(w - s * 0.4, h),
			Vector2(0.0, h),
		])


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
				if Geometry2D.is_point_in_polygon(mouse.position, _poly()):
					clicked.emit(hero_id)
					accept_event()
		elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			var touch := event as InputEventScreenTouch
			if Geometry2D.is_point_in_polygon(touch.position, _poly()):
				clicked.emit(hero_id)
				accept_event()


class _Stage extends Control:
	func _draw() -> void:
		var r := get_rect()
		draw_rect(r, Color("14081f"))
		var step := 36.0
		var grid := Color(0.29, 0.12, 0.47, 0.35)
		var y := 0.0
		while y < r.size.y:
			var x := 0.0
			while x < r.size.x:
				draw_rect(Rect2(x, y, step * 0.55, step * 0.55), grid, false, 1.0)
				x += step
			y += step
		for i in range(80):
			var px := fmod(float(i * 97), r.size.x)
			var py := fmod(float(i * 53), r.size.y)
			draw_circle(Vector2(px, py), 1.2, Color(0.10, 0.88, 0.82, 0.22))
		draw_rect(Rect2(0, 0, r.size.x, 58), Color(0.05, 0.02, 0.09, 0.92))
		draw_rect(Rect2(0, r.size.y - 52, r.size.x, 52), Color(0.03, 0.01, 0.05, 0.88))

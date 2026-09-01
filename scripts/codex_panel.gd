class_name CodexPanel
extends CanvasLayer

## Home-hub browse overlay for weapons, enemies, and records. Meta only — no combat power.

const EmberUiFont := preload("res://scripts/ember_ui_font.gd")
const WeaponCatalog := preload("res://scripts/weapon_catalog.gd")
const EnemyCatalog := preload("res://scripts/enemy_catalog.gd")

const STONE := Color("1a1410")
const GOLD := Color("d4a84b")
const INK := Color("f4ead8")
const INK_DIM := Color("cbbfa8")
const HIDDEN := "???"

var _title: Label
var _list: VBoxContainer


func _ready() -> void:
	layer = 25
	visible = false
	_build()


## Weapon rows: discovered names, everything else ???.
func open_weapons(profile: Dictionary) -> void:
	_title.text = "兵器图鉴"
	_clear_rows()
	var weapons: Dictionary = _codex_bucket(profile, "weapons")
	for id: StringName in WeaponCatalog.all_ids():
		var discovered := _flag(weapons, id, "discovered")
		var def: Dictionary = WeaponCatalog.get_def(id)
		var title := str(def.get("display_name", id)) if discovered else HIDDEN
		var detail := _kind_cn(def.get("kind", &"")) if discovered else "未发现"
		var icon := str(def.get("hold_path", "")) if discovered else ""
		_add_row(String(id), title, detail, icon, true)
	visible = true


## Enemy rows: seen titles + kills/leaks, unseen ???.
func open_enemies(profile: Dictionary) -> void:
	_title.text = "敌人图鉴"
	_clear_rows()
	var enemies: Dictionary = _codex_bucket(profile, "enemies")
	for id: StringName in EnemyCatalog.all_ids():
		var row: Dictionary = _entry(enemies, id)
		var seen := bool(row.get("seen", false))
		var def: Dictionary = EnemyCatalog.get_def(id)
		var title := str(def.get("title", id)) if seen else HIDDEN
		var detail := "未遇见"
		if seen:
			detail = "击杀 %d  /  漏 %d" % [int(row.get("kills", 0)), int(row.get("leaks", 0))]
		var icon := str(def.get("icon", "")) if seen else ""
		_add_row(String(id), title, detail, icon, true)
	visible = true


## Record plaque: highest wave, kills, survive time.
func open_records(profile: Dictionary) -> void:
	_title.text = "战绩碑"
	_clear_rows()
	var records: Dictionary = (profile.get("records", {}) as Dictionary)
	var wave := int(records.get("highest_wave", 0))
	var kills := int(records.get("best_kills", 0))
	var survive := int(floor(float(records.get("best_survive_time", 0.0))))
	_add_row("highest_wave", "最高波次  %d" % wave, "", "", false)
	_add_row("best_kills", "最高击杀  %d" % kills, "", "", false)
	_add_row("best_survive_time", "最长存活  %d秒" % survive, "", "", false)
	visible = true


## Hides the overlay.
func hide_panel() -> void:
	visible = false


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.58)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if _is_press(event):
			hide_panel()
	)
	root.add_child(dim)

	var panel := Panel.new()
	panel.name = "Frame"
	panel.position = Vector2(280, 70)
	panel.size = Vector2(720, 580)
	panel.add_theme_stylebox_override("panel", _style(STONE, GOLD, 2, 4))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	_title = _label("PanelTitle", 22, Color("f0d78c"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.position = Vector2(56, 16)
	_title.size = Vector2(608, 36)
	panel.add_child(_title)

	var closer := Button.new()
	closer.name = "CloseButton"
	closer.text = "关"
	closer.position = Vector2(656, 12)
	closer.custom_minimum_size = Vector2(48, 48)
	closer.size = Vector2(48, 48)
	closer.add_theme_font_override("font", EmberUiFont.bundled())
	closer.add_theme_font_size_override("font_size", 16)
	closer.add_theme_color_override("font_color", INK)
	closer.add_theme_stylebox_override("normal", _style(Color("2a2110"), GOLD, 2, 3))
	closer.pressed.connect(hide_panel)
	panel.add_child(closer)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.position = Vector2(24, 64)
	scroll.size = Vector2(672, 492)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)


func _clear_rows() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()


func _add_row(id: String, title: String, detail: String, icon_path: String, show_slot: bool) -> void:
	var row := HBoxContainer.new()
	row.name = "Row_%s" % id
	row.custom_minimum_size = Vector2(640, 52)
	row.add_theme_constant_override("separation", 10)
	_list.add_child(row)

	if show_slot:
		var icon_wrap := Control.new()
		icon_wrap.custom_minimum_size = Vector2(48, 48)
		icon_wrap.size = Vector2(48, 48)
		row.add_child(icon_wrap)
		var fall := ColorRect.new()
		fall.position = Vector2.ZERO
		fall.size = Vector2(48, 48)
		fall.color = Color("2a2110")
		fall.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_wrap.add_child(fall)
		var tex := _load_tex(icon_path)
		if tex != null:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.position = Vector2.ZERO
			icon.size = Vector2(48, 48)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_wrap.add_child(icon)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	row.add_child(texts)
	var name_label := _label("Name", 15, INK)
	name_label.text = title
	texts.add_child(name_label)
	var detail_label := _label("Detail", 12, INK_DIM)
	detail_label.text = detail
	texts.add_child(detail_label)


func _codex_bucket(profile: Dictionary, key: String) -> Dictionary:
	var codex: Dictionary = (profile.get("codex", {}) as Dictionary)
	return (codex.get(key, {}) as Dictionary)


func _entry(bucket: Dictionary, id: StringName) -> Dictionary:
	if bucket.has(id):
		return bucket[id] as Dictionary
	var as_text := String(id)
	if bucket.has(as_text):
		return bucket[as_text] as Dictionary
	return {}


func _flag(bucket: Dictionary, id: StringName, key: String) -> bool:
	return bool(_entry(bucket, id).get(key, false))


func _kind_cn(kind: Variant) -> String:
	match StringName(str(kind)):
		&"melee":
			return "近战"
		&"pistol":
			return "手枪"
		&"shotgun":
			return "霰弹"
		&"launcher":
			return "发射器"
		&"bow":
			return "弓"
		&"staff":
			return "法杖"
		&"thrown":
			return "投掷"
		_:
			return "远程"


func _load_tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded: Variant = load(path)
		if loaded is Texture2D:
			return loaded as Texture2D
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			return ImageTexture.create_from_image(img)
	return null


func _is_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		return mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _label(node_name: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_override("font", EmberUiFont.bundled())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style

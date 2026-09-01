class_name TalentChoiceOverlay
extends CanvasLayer

## Three-card talent pick. Soul Knight dungeon chrome, not default Godot grey.

const EmberUiFont := preload("res://scripts/ember_ui_font.gd")

const CARD_SIZE := Vector2(280, 340)
const CARD_POSITIONS: Array[Vector2] = [
	Vector2(150, 170),
	Vector2(500, 170),
	Vector2(850, 170),
]
const STONE := Color("#1a1410")
const GOLD := Color("#d4a84b")
const CATEGORY_COLORS := {
	&"offense": Color("#c45c3e"),
	&"defense": Color("#3aa7c2"),
	&"utility": Color("#3cbf8f"),
}

signal talent_chosen(talent_id: StringName)

var _choices: Array = []
var _busy := false
var _title: Label
var _cards: Array[Panel] = []
var _card_styles: Array[StyleBoxFlat] = []
var _strips: Array[ColorRect] = []
var _icons: Array[TextureRect] = []
var _icon_falls: Array[ColorRect] = []
var _name_labels: Array[Label] = []
var _desc_labels: Array[Label] = []
var _stack_labels: Array[Label] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 20
	visible = false
	_build_ui()


## Shows three talent dicts (TalentCatalog get_def shape: id, title, description, category, max_stacks, icon).
func show_choices(level: int, choices: Array, counts: Dictionary) -> void:
	_busy = false
	_choices = choices.duplicate()
	_title.text = "等级提升  /  Lv.%02d" % level
	for i in range(3):
		_fill_card(i, counts)
		_set_card_border(i, 2)
	visible = true


## Hides overlay.
func hide_choices() -> void:
	visible = false
	_busy = false
	for i in range(_cards.size()):
		_set_card_border(i, 2)


## Picks the card at index. Used by keys, clicks, and tests.
func choose_index(index: int) -> void:
	_choose(index)


func _choose(index: int) -> void:
	if _busy or not visible:
		return
	if index < 0 or index >= _choices.size():
		return
	var def: Variant = _choices[index]
	if typeof(def) != TYPE_DICTIONARY:
		return
	var talent_id: StringName = StringName(str((def as Dictionary).get("id", &"")))
	if talent_id == &"":
		return
	_busy = true
	_set_card_border(index, 3)
	talent_chosen.emit(talent_id)
	hide_choices()


func _input(event: InputEvent) -> void:
	if not visible or _busy:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: Key = event.keycode
	if key == KEY_1 or key == KEY_KP_1:
		_choose(0)
		get_viewport().set_input_as_handled()
	elif key == KEY_2 or key == KEY_KP_2:
		_choose(1)
		get_viewport().set_input_as_handled()
	elif key == KEY_3 or key == KEY_KP_3:
		_choose(2)
		get_viewport().set_input_as_handled()
	elif key == KEY_ESCAPE:
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.58)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	_title = _label("Title", 28, Color("#f0d78c"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.position = Vector2(0, 85)
	_title.size = Vector2(1280, 40)
	root.add_child(_title)

	for i in range(3):
		root.add_child(_make_card(i))


func _make_card(index: int) -> Panel:
	var card := Panel.new()
	card.name = "Card%d" % index
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	card.position = CARD_POSITIONS[index]
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := _style(STONE, GOLD, 2, 4)
	card.add_theme_stylebox_override("panel", style)
	_card_styles.append(style)
	card.gui_input.connect(_on_card_gui_input.bind(index))
	card.mouse_entered.connect(_on_card_hover.bind(index, true))
	card.mouse_exited.connect(_on_card_hover.bind(index, false))

	var strip := ColorRect.new()
	strip.name = "CategoryStrip"
	strip.position = Vector2(2, 2)
	strip.size = Vector2(CARD_SIZE.x - 4, 10)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(strip)
	_strips.append(strip)

	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 16
	inner.offset_right = -16
	inner.offset_top = 20
	inner.offset_bottom = -14
	inner.add_theme_constant_override("separation", 8)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inner)

	var icon_row := CenterContainer.new()
	icon_row.custom_minimum_size = Vector2(48, 48)
	icon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(icon_row)

	var fall := ColorRect.new()
	fall.name = "IconFallback"
	fall.custom_minimum_size = Vector2(48, 48)
	fall.size = Vector2(48, 48)
	fall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_row.add_child(fall)
	_icon_falls.append(fall)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_row.add_child(icon)
	_icons.append(icon)

	var name_label := _label("Name", 16, Color("#f4ead8"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(name_label)
	_name_labels.append(name_label)

	var desc := _label("Description", 12, Color("#cbbfa8"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(desc)
	_desc_labels.append(desc)

	var stacks := _label("Stacks", 12, GOLD)
	stacks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(stacks)
	_stack_labels.append(stacks)

	var footer := _label("Footer", 11, Color("#a89060"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.text = "选择 %d" % (index + 1)
	inner.add_child(footer)

	_cards.append(card)
	return card


func _fill_card(index: int, counts: Dictionary) -> void:
	var card: Panel = _cards[index]
	if index >= _choices.size():
		card.visible = false
		return
	var def: Dictionary = _choices[index]
	card.visible = true
	var category: StringName = def.get("category", &"utility")
	var cat_color: Color = CATEGORY_COLORS.get(category, CATEGORY_COLORS[&"utility"])
	_strips[index].color = cat_color
	_name_labels[index].text = str(def.get("title", ""))
	_desc_labels[index].text = str(def.get("description", ""))
	var talent_id: StringName = StringName(str(def.get("id", &"")))
	var stacks: int = _stack_count(talent_id, counts)
	var max_stacks: int = int(def.get("max_stacks", 1))
	_stack_labels[index].text = "层数 %d / %d" % [stacks, max_stacks]
	_apply_icon(index, str(def.get("icon", "")), cat_color)


func _apply_icon(index: int, icon_path: String, fallback_color: Color) -> void:
	var icon: TextureRect = _icons[index]
	var fall: ColorRect = _icon_falls[index]
	fall.color = fallback_color
	var tex := _load_tex(icon_path)
	if tex != null:
		icon.texture = tex
		icon.visible = true
		fall.visible = false
		return
	icon.texture = null
	icon.visible = false
	fall.visible = true


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


func _stack_count(talent_id: StringName, counts: Dictionary) -> int:
	if counts.has(talent_id):
		return int(counts[talent_id])
	var as_text := String(talent_id)
	if counts.has(as_text):
		return int(counts[as_text])
	return 0


func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if not visible or _busy:
		return
	var pressed := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		pressed = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	_set_card_border(index, 3)
	_choose(index)
	get_viewport().set_input_as_handled()


func _on_card_hover(index: int, hovering: bool) -> void:
	if not visible:
		return
	_set_card_border(index, 3 if hovering else 2)


func _set_card_border(index: int, width: int) -> void:
	if index < 0 or index >= _card_styles.size():
		return
	_card_styles[index].set_border_width_all(width)
	_cards[index].queue_redraw()


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

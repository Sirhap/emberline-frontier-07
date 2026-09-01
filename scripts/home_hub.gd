class_name HomeHub
extends Node2D

signal new_run_requested(hero_id: StringName, mode_id: StringName)
signal continue_requested

const EmberUiFont := preload("res://scripts/ember_ui_font.gd")
const CODEX_SCENE := "res://scenes/ui/codex_panel.tscn"

const ROOM := Rect2(96, 72, 1088, 568)
const FLOOR_PATH := "res://assets/generated/grid-battlefield-v6.png"
const GOLD := Color("c9a227")
const GOLD_DIM := Color("8a6e1c")
const STONE_FILL := Color("12100a")
const STONE_INNER := Color("1c160c")
const INK := Color("e8d9a8")
const INK_DIM := Color("a8945a")
const SELECT_PROMPT := "选择出战人物"
const PET_LOCKED := "宠物系统暂未开放"
const NEED_HERO := "请先选择人物"
const MODE_ENDLESS := &"endless_td"

const PORTAL_POS := Vector2(640, 118)
const KNIGHT_POS := Vector2(480, 520)
const ASSASSIN_POS := Vector2(620, 520)
const WEAPON_CODEX_POS := Vector2(1040, 245)
const ENEMY_CODEX_POS := Vector2(1040, 405)
const RECORDS_POS := Vector2(220, 245)
const PET_NEST_POS := Vector2(220, 475)
const PREVIEW_POS := Vector2(640, 355)
const PEDESTAL_SIZE := Vector2(64, 64)

var _profile: Dictionary = {}
var _resumable_run: Dictionary = {}
var _selection_confirmed: bool = false
var _selected_id: StringName = &""
var _highlight_id: StringName = &""
var _mode_open: bool = false
var _built: bool = false

var _title_label: Label
var _prompt_label: Label
var _hint_label: Label
var _preview_label: Label
var _knight_btn: Button
var _assassin_btn: Button
var _continue_btn: Button
var _pet_lock: Label
var _codex: CanvasLayer
var _preview_portrait: TextureRect


## Applies meta profile + optional resumable run payload (may be empty).
func configure(profile: Dictionary, resumable_run: Dictionary) -> void:
	_profile = profile.duplicate(true)
	_resumable_run = resumable_run.duplicate(true)
	_selection_confirmed = false
	_selected_id = &""
	_mode_open = false
	var last := StringName(str(_profile.get("last_selected_hero", "")))
	if last == &"ember_hero" or last == &"assassin":
		_highlight_id = last
	else:
		_highlight_id = &""
	_refresh_visuals()


## True after the player clicks a pedestal this visit.
func is_selection_confirmed() -> bool:
	return _selection_confirmed


## Currently highlighted hero id or &"" if none this visit.
func selected_hero_id() -> StringName:
	if _selection_confirmed:
		return _selected_id
	return &""


## Marks a pedestal hero as the confirmed pick for this visit.
func confirm_hero(hero_id: StringName) -> void:
	if hero_id != &"ember_hero" and hero_id != &"assassin":
		return
	_selected_id = hero_id
	_highlight_id = hero_id
	_selection_confirmed = true
	_refresh_visuals()


## Opens the mode select. Does not emit new_run_requested.
func try_open_portal() -> String:
	if not _selection_confirmed:
		_set_hint(NEED_HERO)
		return NEED_HERO
	_mode_open = true
	_set_hint("选择模式：无尽塔防")
	_refresh_visuals()
	return ""


## Emits new_run_requested(selected, endless_td) after a confirmed pick.
func confirm_new_run() -> String:
	if not _selection_confirmed:
		_set_hint(NEED_HERO)
		return NEED_HERO
	new_run_requested.emit(_selected_id, MODE_ENDLESS)
	return ""


## Resume the stored run when the payload is not empty.
func request_continue() -> void:
	if _resumable_run.is_empty():
		return
	continue_requested.emit()


## Locked pet copy for the nest plaque.
func pet_prompt() -> String:
	return PET_LOCKED


## Opens the weapon codex from the current meta profile.
func open_weapon_codex() -> void:
	if _codex != null:
		_codex.call("open_weapons", _profile)


## Opens the enemy codex from the current meta profile.
func open_enemy_codex() -> void:
	if _codex != null:
		_codex.call("open_enemies", _profile)


## Opens the records plaque from the current meta profile.
func open_records() -> void:
	if _codex != null:
		_codex.call("open_records", _profile)


func _ready() -> void:
	_build_room()
	_refresh_visuals()


func _build_room() -> void:
	if _built:
		return
	_built = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_walls()
	_build_floor()
	_build_room_border()
	_build_portal()
	_build_station("WeaponCodex", WEAPON_CODEX_POS, "兵器图鉴", "已发现的武器", "WeaponCodexButton", open_weapon_codex)
	_build_station("EnemyCodex", ENEMY_CODEX_POS, "敌人图鉴", "已见过的敌人", "EnemyCodexButton", open_enemy_codex)
	_build_station("Records", RECORDS_POS, "战绩碑", "最高波次与击杀", "RecordsButton", open_records)
	_build_codex()
	_build_pet_nest()
	_build_preview()
	_knight_btn = _build_pedestal("KnightPedestal", KNIGHT_POS, "骑士", &"ember_hero")
	_assassin_btn = _build_pedestal("AssassinPedestal", ASSASSIN_POS, "刺客", &"assassin")
	_build_hud()


func _build_walls() -> void:
	_add_fill("Void", Rect2(0, 0, 1280, 720), Color("070604"))
	_add_fill("WallNorth", Rect2(80, 56, 1120, 20), STONE_FILL)
	_add_fill("WallSouth", Rect2(80, 636, 1120, 28), STONE_FILL)
	_add_fill("WallWest", Rect2(80, 72, 20, 568), STONE_FILL)
	_add_fill("WallEast", Rect2(1180, 72, 20, 568), STONE_FILL)


func _add_fill(node_name: String, rect: Rect2, fill: Color) -> void:
	var slab := ColorRect.new()
	slab.name = node_name
	slab.position = rect.position
	slab.size = rect.size
	slab.color = fill
	slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slab)


func _build_floor() -> void:
	var floor := Sprite2D.new()
	floor.name = "Floor"
	floor.texture = load(FLOOR_PATH) as Texture2D
	floor.centered = false
	floor.position = ROOM.position
	floor.region_enabled = true
	floor.region_rect = Rect2(224, 216, ROOM.size.x, ROOM.size.y)
	floor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	floor.z_index = 0
	add_child(floor)


func _build_room_border() -> void:
	var inner := ColorRect.new()
	inner.name = "GoldLintel"
	inner.position = ROOM.position
	inner.size = Vector2(ROOM.size.x, 10)
	inner.color = GOLD_DIM
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.z_index = 1
	add_child(inner)
	var border := Line2D.new()
	border.name = "RoomBorder"
	border.width = 4.0
	border.default_color = GOLD
	border.joint_mode = Line2D.LINE_JOINT_SHARP
	border.begin_cap_mode = Line2D.LINE_CAP_BOX
	border.end_cap_mode = Line2D.LINE_CAP_BOX
	var r := ROOM
	border.points = PackedVector2Array([
		r.position,
		r.position + Vector2(r.size.x, 0.0),
		r.position + r.size,
		r.position + Vector2(0.0, r.size.y),
		r.position,
	])
	border.z_index = 2
	add_child(border)
	var inner_line := Line2D.new()
	inner_line.name = "RoomInnerGold"
	inner_line.width = 1.5
	inner_line.default_color = Color("e2c35a", 0.55)
	var inset := r.grow(-6.0)
	inner_line.points = PackedVector2Array([
		inset.position,
		inset.position + Vector2(inset.size.x, 0.0),
		inset.position + inset.size,
		inset.position + Vector2(0.0, inset.size.y),
		inset.position,
	])
	inner_line.z_index = 2
	add_child(inner_line)


func _build_portal() -> void:
	var portal := Node2D.new()
	portal.name = "EndlessPortal"
	portal.position = PORTAL_POS
	portal.z_index = 3
	add_child(portal)
	var arch := Sprite2D.new()
	arch.name = "Arch"
	arch.texture = load("res://assets/generated/fx/portal/arch.png") as Texture2D
	arch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arch.scale = Vector2(1.2, 1.2)
	arch.position = Vector2(0.0, 8.0)
	portal.add_child(arch)
	var vortex := Sprite2D.new()
	vortex.name = "Vortex"
	vortex.texture = load("res://assets/generated/fx/portal/frame_0.png") as Texture2D
	vortex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vortex.scale = Vector2(0.22, 0.22)
	vortex.position = Vector2(0.0, -6.0)
	portal.add_child(vortex)
	var btn := Button.new()
	btn.name = "PortalButton"
	btn.position = Vector2(-40.0, -48.0)
	btn.custom_minimum_size = Vector2(80.0, 96.0)
	btn.size = Vector2(80.0, 96.0)
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0.08)
	btn.pressed.connect(func() -> void:
		if _mode_open:
			confirm_new_run()
		else:
			try_open_portal()
	)
	portal.add_child(btn)
	var caption := _make_label("无尽之门", 14, GOLD)
	caption.name = "PortalCaption"
	caption.position = Vector2(-48.0, 44.0)
	caption.size = Vector2(96.0, 20.0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portal.add_child(caption)


func _build_codex() -> void:
	if _codex != null:
		return
	_codex = (load(CODEX_SCENE) as PackedScene).instantiate() as CanvasLayer
	_codex.name = "CodexPanel"
	add_child(_codex)


func _build_station(node_name: String, pos: Vector2, title: String, subtitle: String, button_name: String, opener: Callable) -> void:
	var root := Node2D.new()
	root.name = node_name
	root.position = pos
	root.z_index = 3
	add_child(root)
	var plate := Panel.new()
	plate.position = Vector2(-52.0, -28.0)
	plate.size = Vector2(104.0, 56.0)
	plate.custom_minimum_size = Vector2(104.0, 56.0)
	plate.add_theme_stylebox_override("panel", _stone_box(STONE_INNER, GOLD_DIM, 2))
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(plate)
	var label := _make_label(title, 13, INK)
	label.position = Vector2(-50.0, -22.0)
	label.size = Vector2(100.0, 22.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(label)
	var sub := _make_label(subtitle, 11, INK_DIM)
	sub.position = Vector2(-50.0, 0.0)
	sub.size = Vector2(100.0, 20.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)
	var btn := Button.new()
	btn.name = button_name
	btn.position = Vector2(-52.0, -28.0)
	btn.custom_minimum_size = Vector2(104.0, 56.0)
	btn.size = Vector2(104.0, 56.0)
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0.12)
	btn.pressed.connect(opener)
	root.add_child(btn)


func _build_pet_nest() -> void:
	var nest := Node2D.new()
	nest.name = "PetNest"
	nest.position = PET_NEST_POS
	nest.z_index = 3
	add_child(nest)
	var plate := Panel.new()
	plate.position = Vector2(-56.0, -36.0)
	plate.size = Vector2(112.0, 72.0)
	plate.add_theme_stylebox_override("panel", _stone_box(STONE_FILL, GOLD_DIM, 2))
	nest.add_child(plate)
	var title := _make_label("宠物巢穴", 13, INK)
	title.position = Vector2(-54.0, -32.0)
	title.size = Vector2(108.0, 20.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nest.add_child(title)
	_pet_lock = _make_label(PET_LOCKED, 11, Color("c45b4a"))
	_pet_lock.name = "PetLock"
	_pet_lock.position = Vector2(-54.0, -8.0)
	_pet_lock.size = Vector2(108.0, 36.0)
	_pet_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pet_lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nest.add_child(_pet_lock)
	var btn := Button.new()
	btn.name = "PetButton"
	btn.position = Vector2(-56.0, -36.0)
	btn.custom_minimum_size = Vector2(112.0, 72.0)
	btn.size = Vector2(112.0, 72.0)
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0.12)
	btn.pressed.connect(func() -> void:
		_set_hint(pet_prompt())
	)
	nest.add_child(btn)


func _build_preview() -> void:
	var preview := Node2D.new()
	preview.name = "Preview"
	preview.position = PREVIEW_POS
	preview.z_index = 3
	add_child(preview)
	var dais := Panel.new()
	dais.position = Vector2(-70.0, -36.0)
	dais.size = Vector2(140.0, 72.0)
	dais.add_theme_stylebox_override("panel", _stone_box(Color("0c0a07", 0.72), GOLD, 2))
	dais.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(dais)
	_preview_portrait = TextureRect.new()
	_preview_portrait.name = "PreviewPortrait"
	_preview_portrait.position = Vector2(-24.0, -32.0)
	_preview_portrait.size = Vector2(48.0, 48.0)
	_preview_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_portrait.visible = false
	preview.add_child(_preview_portrait)
	_preview_label = _make_label("石座未选", 14, INK_DIM)
	_preview_label.name = "PreviewLabel"
	_preview_label.position = Vector2(-68.0, 16.0)
	_preview_label.size = Vector2(136.0, 24.0)
	_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(_preview_label)


func _build_pedestal(node_name: String, pos: Vector2, title: String, hero_id: StringName) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos - PEDESTAL_SIZE * 0.5
	btn.custom_minimum_size = PEDESTAL_SIZE
	btn.size = PEDESTAL_SIZE
	btn.text = ""
	btn.z_index = 4
	_apply_font(btn, 14)
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_stylebox_override("normal", _stone_box(STONE_INNER, GOLD_DIM, 2))
	btn.add_theme_stylebox_override("hover", _stone_box(Color("2a2110"), GOLD, 2))
	btn.add_theme_stylebox_override("pressed", _stone_box(Color("3a2c12"), GOLD, 3))
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = 6
	portrait.offset_top = 4
	portrait.offset_right = -6
	portrait.offset_bottom = -4
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = load(_portrait_path(hero_id)) as Texture2D
	btn.add_child(portrait)
	btn.pressed.connect(func() -> void:
		confirm_hero(hero_id)
	)
	add_child(btn)
	var tag := _make_label(title, 12, GOLD)
	tag.name = node_name + "Tag"
	tag.position = Vector2(pos.x - 40.0, pos.y + 34.0)
	tag.size = Vector2(80.0, 18.0)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.z_index = 4
	add_child(tag)
	return btn


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	_title_label = _make_label("余烬防线  ·  家园", 22, GOLD)
	_title_label.name = "TitleLabel"
	_title_label.position = Vector2(0.0, 8.0)
	_title_label.size = Vector2(1280.0, 32.0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(_title_label)
	_prompt_label = _make_label(SELECT_PROMPT, 20, INK)
	_prompt_label.name = "PromptLabel"
	_prompt_label.position = Vector2(0.0, 40.0)
	_prompt_label.size = Vector2(1280.0, 28.0)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(_prompt_label)
	_hint_label = _make_label("点击石座选择出战人物", 14, INK_DIM)
	_hint_label.name = "HintLabel"
	_hint_label.position = Vector2(0.0, 684.0)
	_hint_label.size = Vector2(1280.0, 28.0)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(_hint_label)
	_continue_btn = Button.new()
	_continue_btn.name = "ContinueButton"
	_continue_btn.text = "继续远征"
	_continue_btn.position = Vector2(24.0, 640.0)
	_continue_btn.custom_minimum_size = Vector2(120.0, 40.0)
	_continue_btn.size = Vector2(120.0, 40.0)
	_apply_font(_continue_btn, 14)
	_continue_btn.add_theme_color_override("font_color", INK)
	_continue_btn.add_theme_stylebox_override("normal", _stone_box(STONE_INNER, GOLD, 2))
	_continue_btn.pressed.connect(request_continue)
	_continue_btn.visible = false
	hud.add_child(_continue_btn)


func _refresh_visuals() -> void:
	if not _built:
		return
	var hero_title := _hero_title(_selected_id if _selection_confirmed else &"")
	if _prompt_label != null:
		_prompt_label.text = SELECT_PROMPT if not _selection_confirmed else hero_title
	if _preview_label != null:
		_preview_label.text = "石座未选" if not _selection_confirmed else hero_title
	if _preview_portrait != null:
		if _selection_confirmed:
			_preview_portrait.texture = load(_portrait_path(_selected_id)) as Texture2D
			_preview_portrait.visible = true
		else:
			_preview_portrait.visible = false
	if _continue_btn != null:
		_continue_btn.visible = not _resumable_run.is_empty()
	_paint_pedestal(_knight_btn, &"ember_hero")
	_paint_pedestal(_assassin_btn, &"assassin")
	if _hint_label != null and not _selection_confirmed:
		_set_hint("点击石座选择出战人物")
	elif _hint_label != null and _selection_confirmed and not _mode_open:
		_set_hint("走近传送门，开启无尽塔防")


func _paint_pedestal(btn: Button, hero_id: StringName) -> void:
	if btn == null:
		return
	var lit := (_highlight_id == hero_id) or (_selection_confirmed and _selected_id == hero_id)
	var border := GOLD if lit else GOLD_DIM
	var fill := Color("2e2410") if lit else STONE_INNER
	btn.add_theme_stylebox_override("normal", _stone_box(fill, border, 2 if lit else 2))
	if _selection_confirmed and _selected_id == hero_id:
		btn.add_theme_stylebox_override("normal", _stone_box(Color("3d2f12"), GOLD, 3))


func _hero_title(hero_id: StringName) -> String:
	if hero_id == &"ember_hero":
		return "骑士"
	if hero_id == &"assassin":
		return "刺客"
	return SELECT_PROMPT


func _portrait_path(hero_id: StringName) -> String:
	if hero_id == &"assassin":
		return "res://assets/generated/ui/portrait-assassin.png"
	return "res://assets/generated/ui/portrait-knight.png"


func _set_hint(text: String) -> void:
	if _hint_label != null:
		_hint_label.text = text


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(label, size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.01, 0.92))
	label.add_theme_constant_override("outline_size", 4)
	return label


func _apply_font(control: Control, size: int) -> void:
	control.add_theme_font_override("font", EmberUiFont.bundled())
	control.add_theme_font_size_override("font_size", size)


func _stone_box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	return style

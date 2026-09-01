class_name HomeHub
extends Node2D

signal new_run_requested(hero_id: StringName, mode_id: StringName)
signal continue_requested

const EmberUiFont := preload("res://scripts/ember_ui_font.gd")
const HomeRoom := preload("res://scripts/home_room.gd")
const CODEX_SCENE := "res://scenes/ui/codex_panel.tscn"

const GOLD := Color("c9a227")
const GOLD_DIM := Color("8a6e1c")
const STONE_INNER := Color("1c160c")
const INK := Color("e8d9a8")
const INK_DIM := Color("a8945a")
const SELECT_PROMPT := "选择出战人物"
const PET_LOCKED := "宠物系统暂未开放"
const NEED_HERO := "请先选择人物"
const MODE_ENDLESS := &"endless_td"

const PORTAL_POS := Vector2(640, 100)
const KNIGHT_POS := Vector2(500, 575)
const ASSASSIN_POS := Vector2(790, 575)
const WEAPON_CODEX_POS := Vector2(1084, 168)
const ENEMY_CODEX_POS := Vector2(1088, 540)
const RECORDS_POS := Vector2(210, 250)
const PET_NEST_POS := Vector2(210, 520)
const PREVIEW_POS := Vector2(640, 598)
const PEDESTAL_SIZE := Vector2(96, 140)
const KNIGHT_IDLE_REGION := Rect2(81, 70, 163, 250)
const ASSASSIN_IDLE_REGION := Rect2(115, 160, 161, 224)
const PAD_BODY_HEIGHT := 112.0
const PREVIEW_BODY_HEIGHT := 130.0

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
var _preview_body: AnimatedSprite2D


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
	var room := HomeRoom.new()
	room.name = "HomeRoom"
	add_child(room)
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


func _build_portal() -> void:
	var portal := Node2D.new()
	portal.name = "EndlessPortal"
	portal.position = PORTAL_POS
	portal.z_index = 4
	add_child(portal)
	var btn := Button.new()
	btn.name = "PortalButton"
	btn.position = Vector2(-60.0, -70.0)
	btn.custom_minimum_size = Vector2(120.0, 140.0)
	btn.size = Vector2(120.0, 140.0)
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
	caption.position = Vector2(-64.0, 62.0)
	caption.size = Vector2(128.0, 20.0)
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
	plate.position = Vector2(-70.0, 96.0)
	plate.size = Vector2(140.0, 42.0)
	plate.custom_minimum_size = Vector2(140.0, 42.0)
	plate.add_theme_stylebox_override("panel", _stone_box(Color("1c160c", 0.72), GOLD_DIM, 2))
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(plate)
	var label := _make_label(title, 13, INK)
	label.position = Vector2(-68.0, 98.0)
	label.size = Vector2(136.0, 18.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(label)
	var sub := _make_label(subtitle, 11, INK_DIM)
	sub.position = Vector2(-68.0, 116.0)
	sub.size = Vector2(136.0, 18.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)
	var btn := Button.new()
	btn.name = button_name
	btn.position = Vector2(-70.0, -120.0)
	btn.custom_minimum_size = Vector2(140.0, 220.0)
	btn.size = Vector2(140.0, 220.0)
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0.08)
	btn.pressed.connect(opener)
	root.add_child(btn)


func _build_pet_nest() -> void:
	var nest := Node2D.new()
	nest.name = "PetNest"
	nest.position = PET_NEST_POS
	nest.z_index = 3
	add_child(nest)
	var plate := Panel.new()
	plate.position = Vector2(-70.0, 92.0)
	plate.size = Vector2(140.0, 44.0)
	plate.add_theme_stylebox_override("panel", _stone_box(Color("1c160c", 0.72), GOLD_DIM, 2))
	nest.add_child(plate)
	var title := _make_label("宠物巢穴", 13, INK)
	title.position = Vector2(-68.0, 94.0)
	title.size = Vector2(136.0, 18.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nest.add_child(title)
	_pet_lock = _make_label(PET_LOCKED, 11, Color("c45b4a"))
	_pet_lock.name = "PetLock"
	_pet_lock.position = Vector2(-68.0, 112.0)
	_pet_lock.size = Vector2(136.0, 22.0)
	_pet_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pet_lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nest.add_child(_pet_lock)
	var btn := Button.new()
	btn.name = "PetButton"
	btn.position = Vector2(-70.0, -110.0)
	btn.custom_minimum_size = Vector2(140.0, 200.0)
	btn.size = Vector2(140.0, 200.0)
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0.08)
	btn.pressed.connect(func() -> void:
		_set_hint(pet_prompt())
	)
	nest.add_child(btn)


func _build_preview() -> void:
	var preview := Node2D.new()
	preview.name = "Preview"
	preview.position = PREVIEW_POS
	preview.z_index = 5
	add_child(preview)
	_preview_body = _make_idle_body("PreviewBody", &"ember_hero", PREVIEW_BODY_HEIGHT)
	_place_idle_body(_preview_body, Vector2.ZERO)
	_preview_body.visible = false
	preview.add_child(_preview_body)
	_preview_label = _make_label("石座未选", 14, INK_DIM)
	_preview_label.name = "PreviewLabel"
	_preview_label.visible = false
	_preview_label.position = Vector2(-80.0, 12.0)
	_preview_label.size = Vector2(160.0, 24.0)
	_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(_preview_label)


func _build_pedestal(node_name: String, pos: Vector2, title: String, hero_id: StringName) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = Vector2(pos.x - PEDESTAL_SIZE.x * 0.5, pos.y - 118.0)
	btn.custom_minimum_size = PEDESTAL_SIZE
	btn.size = PEDESTAL_SIZE
	btn.text = ""
	btn.z_index = 4
	_apply_font(btn, 14)
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_stylebox_override("normal", _stone_box(Color("1c160c", 0.18), GOLD_DIM, 2))
	btn.add_theme_stylebox_override("hover", _stone_box(Color("2a2110", 0.35), GOLD, 2))
	btn.add_theme_stylebox_override("pressed", _stone_box(Color("3a2c12", 0.45), GOLD, 3))
	btn.pressed.connect(func() -> void:
		confirm_hero(hero_id)
	)
	add_child(btn)
	var body := _make_idle_body(node_name + "Body", hero_id, PAD_BODY_HEIGHT)
	_place_idle_body(body, pos)
	body.z_index = 5
	add_child(body)
	var tag := _make_label(title, 12, GOLD)
	tag.name = node_name + "Tag"
	tag.position = Vector2(pos.x - 48.0, pos.y + 52.0)
	tag.size = Vector2(96.0, 18.0)
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
		_preview_label.visible = _selection_confirmed
		_preview_label.text = hero_title
	if _preview_body != null:
		if _selection_confirmed:
			_apply_idle_frames(_preview_body, _selected_id, PREVIEW_BODY_HEIGHT)
			_place_idle_body(_preview_body, Vector2.ZERO)
			_preview_body.visible = true
			_preview_body.play("idle")
		else:
			_preview_body.visible = false
			_preview_body.stop()
	_set_stage_clear(_selection_confirmed)
	if _continue_btn != null:
		_continue_btn.visible = not _resumable_run.is_empty()
	_paint_pedestal(_knight_btn, &"ember_hero")
	_paint_pedestal(_assassin_btn, &"assassin")
	_set_pad_body_visible("KnightPedestalBody", not (_selection_confirmed and _selected_id == &"ember_hero"))
	_set_pad_body_visible("AssassinPedestalBody", not (_selection_confirmed and _selected_id == &"assassin"))
	if _hint_label != null and not _selection_confirmed:
		_set_hint("点击石座选择出战人物")
	elif _hint_label != null and _selection_confirmed and not _mode_open:
		_set_hint("走近传送门，开启无尽塔防")


func _paint_pedestal(btn: Button, hero_id: StringName) -> void:
	if btn == null:
		return
	var lit := (_highlight_id == hero_id) or (_selection_confirmed and _selected_id == hero_id)
	var border := GOLD if lit else GOLD_DIM
	var fill := Color("2e2410", 0.28) if lit else Color("1c160c", 0.16)
	btn.add_theme_stylebox_override("normal", _stone_box(fill, border, 2 if lit else 2))
	if _selection_confirmed and _selected_id == hero_id:
		btn.add_theme_stylebox_override("normal", _stone_box(Color("3d2f12", 0.35), GOLD, 3))


func _hero_title(hero_id: StringName) -> String:
	if hero_id == &"ember_hero":
		return "骑士"
	if hero_id == &"assassin":
		return "刺客"
	return SELECT_PROMPT


func _make_idle_body(node_name: String, hero_id: StringName, body_height: float) -> AnimatedSprite2D:
	var body := AnimatedSprite2D.new()
	body.name = node_name
	body.centered = true
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_idle_frames(body, hero_id, body_height)
	body.play("idle")
	return body


func _apply_idle_frames(body: AnimatedSprite2D, hero_id: StringName, body_height: float) -> void:
	var region := _idle_region(hero_id)
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 8.0)
	frames.set_animation_loop("idle", true)
	for path: String in _idle_frame_paths(hero_id):
		var sheet := load(path) as Texture2D
		assert(sheet != null, "home idle frame missing: %s" % path)
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = region
		atlas.filter_clip = true
		frames.add_frame("idle", atlas)
	body.sprite_frames = frames
	var scale := body_height / maxf(region.size.y, 1.0)
	body.scale = Vector2(scale, scale)


func _place_idle_body(body: AnimatedSprite2D, feet: Vector2) -> void:
	var frames: SpriteFrames = body.sprite_frames
	if frames == null or frames.get_frame_count("idle") < 1:
		body.position = feet
		return
	var tex := frames.get_frame_texture("idle", 0)
	var canvas_h := float(tex.get_height()) if tex != null else 250.0
	body.position = feet + Vector2(0.0, -canvas_h * body.scale.y * 0.5)


func _idle_region(hero_id: StringName) -> Rect2:
	if hero_id == &"assassin":
		return ASSASSIN_IDLE_REGION
	return KNIGHT_IDLE_REGION


func _idle_frame_paths(hero_id: StringName) -> PackedStringArray:
	var folder := "res://xsxb_frame_tuner/workspace/projects/emberline_enemies/assets/ember_assassin/idle"
	if hero_id != &"assassin":
		folder = "res://xsxb_frame_tuner/workspace/projects/emberline_frontier_07_final/assets/ember_hero/idle"
	var paths: PackedStringArray = PackedStringArray()
	for i: int in 6:
		paths.append("%s/breathe_%02d.png" % [folder, i])
	return paths


func _set_stage_clear(clear: bool) -> void:
	for node_name: String in ["Table", "ChairWest", "ChairEast"]:
		var piece := find_child(node_name, true, false)
		if piece != null:
			piece.visible = not clear


func _set_pad_body_visible(node_name: String, shown: bool) -> void:
	var body := find_child(node_name, true, false)
	if body != null:
		body.visible = shown


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

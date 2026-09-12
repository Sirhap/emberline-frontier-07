class_name HomeHub
extends Node2D

signal new_run_requested(hero_id: StringName, mode_id: StringName)
signal continue_requested
signal hero_select_requested

const EmberUiFont := preload("res://scripts/ember_ui_font.gd")
const EmberHero := preload("res://scripts/hero.gd")
const HomeRoom := preload("res://scripts/home_room.gd")
const HeroPackCatalog := preload("res://scripts/hero_pack_catalog.gd")
const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")
const CODEX_SCENE := "res://scenes/ui/codex_panel.tscn"
const WALKER_SPAWN := Vector2(280, 560)
const WALKER_HEIGHT := 128.0

const GOLD := Color("c9a227")
const STONE_INNER := Color("1c160c")
const INK := Color("e8d9a8")
const PET_LOCKED := "宠物系统暂未开放"
const INVALID_SAVE_HINT := "存档无效"
const MODE_ENDLESS := &"endless_td"

const WEAPON_CODEX_POS := Vector2(905, 130)
const ENEMY_CODEX_POS := Vector2(175, 398)
const RECORDS_POS := Vector2(1015, 78)
const PET_NEST_POS := Vector2(305, 625)

var _profile: Dictionary = {}
var _resumable_run: Dictionary = {}
var _save_on_disk: bool = false
var _built: bool = false

var _start_btn: Button
var _continue_btn: Button
var _hero_select_btn: Button
var _invalid_save_hint: Label
var _hud_layer: CanvasLayer
var _codex: CanvasLayer
var _room: HomeRoom
var _walker: EmberHero
var _pet_hint: Label
var _pet_hint_left := 0.0


## Applies meta profile + optional resumable run payload (may be empty).
## save_on_disk is true when user://run.json exists even if load_run rejected it.
func configure(profile: Dictionary, resumable_run: Dictionary, save_on_disk: bool = false) -> void:
	_profile = profile.duplicate(true)
	_resumable_run = resumable_run.duplicate(true)
	_save_on_disk = save_on_disk
	_refresh_visuals()


## Hero used when starting a new run.
func selected_hero_id() -> StringName:
	return _launch_hero_id()


## Starts endless TD with the profile hero (assassin if last run, else knight).
func confirm_new_run() -> String:
	new_run_requested.emit(_launch_hero_id(), MODE_ENDLESS)
	return ""


## Resume the stored run when the payload is not empty.
func request_continue() -> void:
	if _resumable_run.is_empty():
		return
	continue_requested.emit()


## Reopens the boot character-select screen from home.
func request_hero_select() -> void:
	hero_select_requested.emit()


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
	_room = HomeRoom.new()
	_room.name = "HomeRoom"
	add_child(_room)
	_build_walker()
	_build_station("WeaponCodex", WEAPON_CODEX_POS, "兵器图鉴", "已发现的武器", "WeaponCodexButton", open_weapon_codex)
	_build_station("EnemyCodex", ENEMY_CODEX_POS, "敌人图鉴", "已见过的敌人", "EnemyCodexButton", open_enemy_codex)
	_build_station("Records", RECORDS_POS, "战绩碑", "最高波次与击杀", "RecordsButton", open_records)
	_build_codex()
	_build_pet_nest()
	_build_hud()


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
	var btn := Button.new()
	btn.name = button_name
	btn.position = Vector2(-70.0, -120.0)
	btn.custom_minimum_size = Vector2(140.0, 220.0)
	btn.size = Vector2(140.0, 220.0)
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0.08)
	btn.tooltip_text = "%s\n%s" % [title, subtitle]
	btn.pressed.connect(opener)
	root.add_child(btn)


func _build_pet_nest() -> void:
	var nest := Node2D.new()
	nest.name = "PetNest"
	nest.position = PET_NEST_POS
	nest.z_index = 3
	add_child(nest)
	var btn := Button.new()
	btn.name = "PetButton"
	btn.position = Vector2(-70.0, -110.0)
	btn.custom_minimum_size = Vector2(140.0, 200.0)
	btn.size = Vector2(140.0, 200.0)
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0.08)
	btn.tooltip_text = pet_prompt()
	btn.pressed.connect(_show_pet_locked)
	nest.add_child(btn)


func set_hub_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	_sync_overlay_visibility(active)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_sync_overlay_visibility(visible)


func _sync_overlay_visibility(active: bool) -> void:
	if _hud_layer != null:
		_hud_layer.visible = active
	if _codex != null and not active:
		if _codex.has_method("hide_panel"):
			_codex.call("hide_panel")
		_codex.visible = false


func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUD"
	add_child(_hud_layer)
	_start_btn = _make_hud_button("StartButton", "开始远征", Vector2(24.0, 640.0))
	_start_btn.pressed.connect(func() -> void:
		confirm_new_run()
	)
	_hud_layer.add_child(_start_btn)
	_continue_btn = _make_hud_button("ContinueButton", "继续远征", Vector2(156.0, 640.0))
	_continue_btn.pressed.connect(request_continue)
	_continue_btn.visible = false
	_hud_layer.add_child(_continue_btn)
	_hero_select_btn = _make_hud_button("HeroSelectButton", "更换人物", Vector2(288.0, 640.0))
	_hero_select_btn.pressed.connect(request_hero_select)
	_hud_layer.add_child(_hero_select_btn)
	_invalid_save_hint = Label.new()
	_invalid_save_hint.name = "InvalidSaveHint"
	_invalid_save_hint.text = INVALID_SAVE_HINT
	_invalid_save_hint.position = Vector2(156.0, 640.0)
	_invalid_save_hint.custom_minimum_size = Vector2(120.0, 48.0)
	_invalid_save_hint.size = Vector2(120.0, 48.0)
	_invalid_save_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_invalid_save_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_invalid_save_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_invalid_save_hint.visible = false
	_apply_font(_invalid_save_hint, 14)
	_invalid_save_hint.add_theme_color_override("font_color", GOLD)
	_hud_layer.add_child(_invalid_save_hint)
	_pet_hint = Label.new()
	_pet_hint.name = "PetLockedHint"
	_pet_hint.text = PET_LOCKED
	_pet_hint.position = Vector2(430.0, 640.0)
	_pet_hint.custom_minimum_size = Vector2(220.0, 48.0)
	_pet_hint.size = Vector2(220.0, 48.0)
	_pet_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pet_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pet_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pet_hint.visible = false
	_apply_font(_pet_hint, 14)
	_pet_hint.add_theme_color_override("font_color", GOLD)
	_hud_layer.add_child(_pet_hint)


func _refresh_visuals() -> void:
	if not _built:
		return
	var can_continue := not _resumable_run.is_empty()
	if _continue_btn != null:
		_continue_btn.visible = can_continue
	if _invalid_save_hint != null:
		_invalid_save_hint.visible = _save_on_disk and not can_continue
	if _walker != null:
		var skin := _skin_for(_launch_hero_id())
		_walker.apply_hero_kind(_launch_hero_id(), skin)


func _show_pet_locked() -> void:
	if _pet_hint == null:
		return
	_pet_hint.text = PET_LOCKED
	_pet_hint.visible = true
	_pet_hint_left = 2.6


func _process(delta: float) -> void:
	if _pet_hint_left <= 0.0:
		return
	_pet_hint_left = maxf(_pet_hint_left - delta, 0.0)
	if _pet_hint_left <= 0.0 and _pet_hint != null:
		_pet_hint.visible = false


func clamp_hero_position(from: Vector2, next: Vector2) -> Vector2:
	if _room == null:
		return next
	var clearance := 0.0
	if _walker != null:
		clearance = _walker.air_clearance()
	return _room.clamp_walk(from, next, clearance)


func _build_walker() -> void:
	_walker = EmberHero.new()
	_walker.name = "HomeWalker"
	_walker.z_index = 5
	_walker.hub_visual_height = WALKER_HEIGHT
	_walker.hub_hide_weapon = true
	_walker.has_dash = false
	_walker.configure(self, WALKER_SPAWN)
	add_child(_walker)


func _unhandled_input(event: InputEvent) -> void:
	if _walker == null or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_J:
			get_viewport().set_input_as_handled()
		KEY_K, KEY_SPACE:
			_walker.request_jump()
			get_viewport().set_input_as_handled()


func _launch_hero_id() -> StringName:
	var last := StringName(str(_profile.get("last_selected_hero", "")))
	if HeroDefinitionCatalog.has_id(last):
		return last
	return &"ember_hero"


func _skin_for(hero_id: StringName) -> StringName:
	var raw: Variant = _profile.get("last_skin", {})
	var picked := &""
	if raw is Dictionary:
		picked = StringName(str((raw as Dictionary).get(String(hero_id), "")))
	return HeroPackCatalog.resolve_selectable_skin(hero_id, picked)


func _make_hud_button(node_name: String, text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = text
	btn.position = pos
	btn.custom_minimum_size = Vector2(120.0, 48.0)
	btn.size = Vector2(120.0, 48.0)
	_apply_font(btn, 14)
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_stylebox_override("normal", _stone_box(STONE_INNER, GOLD, 2))
	return btn


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

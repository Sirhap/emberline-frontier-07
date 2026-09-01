class_name HomeHub
extends Node2D

signal new_run_requested(hero_id: StringName, mode_id: StringName)
signal continue_requested

const EmberUiFont := preload("res://scripts/ember_ui_font.gd")
const HomeRoom := preload("res://scripts/home_room.gd")
const CODEX_SCENE := "res://scenes/ui/codex_panel.tscn"

const GOLD := Color("c9a227")
const STONE_INNER := Color("1c160c")
const INK := Color("e8d9a8")
const PET_LOCKED := "宠物系统暂未开放"
const MODE_ENDLESS := &"endless_td"

const PORTAL_POS := Vector2(640, 100)
const WEAPON_CODEX_POS := Vector2(1084, 168)
const ENEMY_CODEX_POS := Vector2(1088, 540)
const RECORDS_POS := Vector2(210, 250)
const PET_NEST_POS := Vector2(210, 520)

var _profile: Dictionary = {}
var _resumable_run: Dictionary = {}
var _built: bool = false

var _continue_btn: Button
var _codex: CanvasLayer


## Applies meta profile + optional resumable run payload (may be empty).
func configure(profile: Dictionary, resumable_run: Dictionary) -> void:
	_profile = profile.duplicate(true)
	_resumable_run = resumable_run.duplicate(true)
	_refresh_visuals()


## Hero used when the portal starts a new run.
func selected_hero_id() -> StringName:
	return _launch_hero_id()


## Starts endless TD with the profile hero (assassin if last run, else knight).
func confirm_new_run() -> String:
	new_run_requested.emit(_launch_hero_id(), MODE_ENDLESS)
	return ""


## Same as confirm_new_run: there is no mode or hero picker.
func try_open_portal() -> String:
	return confirm_new_run()


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
		confirm_new_run()
	)
	portal.add_child(btn)


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
	nest.add_child(btn)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
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
	if _continue_btn != null:
		_continue_btn.visible = not _resumable_run.is_empty()


func _launch_hero_id() -> StringName:
	var last := StringName(str(_profile.get("last_selected_hero", "")))
	if last == &"assassin":
		return &"assassin"
	return &"ember_hero"


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

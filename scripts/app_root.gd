class_name AppRoot
extends Node

## Boot root: home hub first, then endless TD. Battlefield is not the process main scene.

const HOME_SCENE := "res://scenes/home/home_hub.tscn"
const BATTLE_SCENE := "res://main.tscn"
const EmberUiFont := preload("res://scripts/ember_ui_font.gd")
const HomeHub := preload("res://scripts/home_hub.gd")
const EmberMetaSave := preload("res://scripts/meta_save.gd")
const EmberRunSave := preload("res://scripts/run_save.gd")

var _profile: Dictionary = {}
var _home: HomeHub
var _battle: Node
var _pending_hero: StringName = &""
var _confirm: CanvasLayer


func _ready() -> void:
	_profile = EmberMetaSave.load_profile()
	_show_home()


func _show_home() -> void:
	if get_tree() != null:
		get_tree().paused = false
	if _battle != null and is_instance_valid(_battle):
		_battle.queue_free()
		_battle = null
	if _home == null or not is_instance_valid(_home):
		_home = (load(HOME_SCENE) as PackedScene).instantiate() as HomeHub
		_home.name = "HomeHub"
		add_child(_home)
		_home.new_run_requested.connect(_on_new_run_requested)
		_home.continue_requested.connect(_on_continue_requested)
	_profile = EmberMetaSave.load_profile()
	var resumable: Dictionary = EmberRunSave.load_run()
	_home.visible = true
	_home.configure(_profile, resumable)


func _on_new_run_requested(hero_id: StringName, _mode_id: StringName) -> void:
	if FileAccess.file_exists(EmberRunSave.RUN_PATH):
		_pending_hero = hero_id
		_show_overwrite_confirm()
		return
	_start_new_run(hero_id)


func _on_continue_requested() -> void:
	var payload := EmberRunSave.load_run()
	if payload.is_empty():
		return
	_hide_confirm()
	_launch_battle({
		"resume": true,
		"payload": payload,
		"hero_id": StringName(str((payload.get("hero", {}) as Dictionary).get("hero_id", "ember_hero"))),
		"mode_id": &"endless_td",
		"run_seed": int(payload.get("run_seed", 1)),
	})


func _start_new_run(hero_id: StringName) -> void:
	_hide_confirm()
	EmberRunSave.delete_run()
	_launch_battle({
		"resume": false,
		"hero_id": hero_id,
		"mode_id": &"endless_td",
		"run_seed": int(Time.get_ticks_msec()),
	})


func _launch_battle(config: Dictionary) -> void:
	if _home != null:
		_home.visible = false
	if _battle != null and is_instance_valid(_battle):
		_battle.queue_free()
	_battle = (load(BATTLE_SCENE) as PackedScene).instantiate()
	_battle.name = "Battlefield"
	if _battle.has_method("configure_launch"):
		_battle.call("configure_launch", config)
	if _battle.has_signal("run_finished"):
		_battle.connect("run_finished", _on_run_finished)
	add_child(_battle)


func _on_run_finished(result: Dictionary) -> void:
	if not bool(result.get("exclude_from_meta", false)):
		_profile = EmberMetaSave.apply_run_result(_profile, result)
		var discoveries: Variant = result.get("discoveries", [])
		if discoveries is Array:
			for event: Variant in discoveries:
				if event is Dictionary:
					_profile = EmberMetaSave.record_discovery(_profile, event)
		EmberMetaSave.write_profile(_profile)
	_show_home()


func _show_overwrite_confirm() -> void:
	if _confirm != null:
		_confirm.visible = true
		return
	_confirm = CanvasLayer.new()
	_confirm.name = "OverwriteConfirm"
	_confirm.layer = 30
	add_child(_confirm)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	_confirm.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(400, 240)
	panel.size = Vector2(480, 220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a1410")
	style.border_color = Color("d4a84b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	_confirm.add_child(panel)
	var title := Label.new()
	title.text = "覆盖当前远征？"
	title.position = Vector2(24, 28)
	title.size = Vector2(432, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", EmberUiFont.bundled())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f0d78c"))
	panel.add_child(title)
	var body := Label.new()
	body.text = "开始新的无尽塔防会删除未结束的存档。"
	body.position = Vector2(24, 76)
	body.size = Vector2(432, 48)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", EmberUiFont.bundled())
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color("cbbfa8"))
	panel.add_child(body)
	var yes := Button.new()
	yes.text = "覆盖并出发"
	yes.position = Vector2(40, 144)
	yes.size = Vector2(180, 44)
	yes.custom_minimum_size = Vector2(180, 44)
	_style_confirm_button(yes)
	yes.pressed.connect(func() -> void:
		var hero_id := _pending_hero
		_pending_hero = &""
		_start_new_run(hero_id)
	)
	panel.add_child(yes)
	var no := Button.new()
	no.text = "取消"
	no.position = Vector2(260, 144)
	no.size = Vector2(180, 44)
	no.custom_minimum_size = Vector2(180, 44)
	_style_confirm_button(no)
	no.pressed.connect(_hide_confirm)
	panel.add_child(no)


func _hide_confirm() -> void:
	if _confirm != null:
		_confirm.visible = false


func _style_confirm_button(btn: Button) -> void:
	btn.add_theme_font_override("font", EmberUiFont.bundled())
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color("e8d9a8"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2a2110")
	style.border_color = Color("d4a84b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", style)

class_name FrontierHud
extends CanvasLayer

const UiFont := preload("res://scripts/ember_ui_font.gd")

signal start_wave_pressed
signal restart_pressed
signal speed_pressed
signal hero_pressed
signal jump_pressed
signal attack_pressed
signal upgrade_pressed
signal sell_pressed
signal skill_pressed
signal shop_slot_pressed(index: int)
signal weapon_switch_pressed
signal talk_pressed
signal hero_kind_pressed(kind: StringName)

var resources_label: Label
var base_label: Label
var wave_label: Label
var status_label: Label
var hero_status_label: Label
var loadout_label: Label
var tower_name_label: Label
var tower_info_label: Label
var tower_hint_label: Label
var tower_icon: TextureRect
var start_button: Button
var upgrade_button: Button
var sell_button: Button
var speed_button: Button
var hero_button: Button
var jump_button: Button
var attack_button: Button
var skill_button: Button
var shop_panel: PanelContainer
var shop_title: Label
var shop_hold_hint: Label
var shop_vendor_icon: TextureRect
var shop_buttons: Array[Button] = []
var prep_label: Label
var npc_bubble: PanelContainer
var npc_bubble_label: Label
var overlay: ColorRect
var overlay_title: Label
var overlay_body: Label
var dev_panel: PanelContainer
var dev_label: Label
var _toast_left := 0.0
var _hero_hp_bar: ProgressBar
var _hero_armor_bar: ProgressBar
var _hero_energy_bar: ProgressBar
var _tower_panel: PanelContainer
var _action_cluster: PanelContainer
var _tower_panel_left := 0.0
var _action_cluster_left := 0.0
var weapon_switch: Button
var move_stick := Vector2.ZERO
var talk_button: Button
var _hero_kind_buttons: Dictionary = {}
var _hero_kind: StringName = &"ember_hero"
var _stick: Control
var _in_home := false
var _skill_overlay: Control
var _attack_icon: Texture2D
var _jump_icon: Texture2D
var _talk_icon: Texture2D
var _dash_icon: Texture2D
var _weapon_slot_ids: Array[StringName] = []
var _weapon_active_index := 0
var _weapon_dock_ready := false
var _weapon_count_label: Label
var _turret_hand := false
var _turret_kind: StringName = &""
var _turret_count := 0
var _minimap: Control
var _shop_visible := false
var _dev_visible := false

func _ready() -> void:
	_build_interface()

func _process(delta: float) -> void:
	if _toast_left > 0.0 and status_label != null:
		_toast_left = maxf(_toast_left - delta, 0.0)
		if _toast_left <= 0.0:
			status_label.text = ""
			status_label.visible = false
	_tower_panel_left = maxf(_tower_panel_left - delta, 0.0)
	_sync_context_overlays()
	_action_cluster_left = maxf(_action_cluster_left - delta, 0.0)
	if _stick != null:
		move_stick = _stick.get("value") as Vector2 if _stick.get("value") is Vector2 else Vector2.ZERO

func _build_interface() -> void:
	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _build_interface_theme()
	add_child(root)

	var top_row := HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.position = Vector2(16.0, 12.0)
	top_row.size = Vector2(1248.0, 44.0)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override("separation", 14)
	root.add_child(top_row)

	var bars := VBoxContainer.new()
	bars.add_theme_constant_override("separation", 4)
	top_row.add_child(bars)
	_hero_hp_bar = _stat_bar("生命", Color("#ff5f4d"), 190.0)
	bars.add_child(_hero_hp_bar)
	var sub_bars := HBoxContainer.new()
	sub_bars.add_theme_constant_override("separation", 6)
	bars.add_child(sub_bars)
	_hero_armor_bar = _stat_bar("护甲", Color("#9aa6ad"), 92.0)
	_hero_armor_bar.visible = false
	sub_bars.add_child(_hero_armor_bar)
	_hero_energy_bar = _stat_bar("冲刺", Color("#4d9dff"), 92.0)
	sub_bars.add_child(_hero_energy_bar)

	wave_label = _top_value("无尽 0", Color("#ffb55f"))
	top_row.add_child(wave_label)
	resources_label = _top_value("300", Color("#ffc84f"))
	top_row.add_child(resources_label)
	base_label = _top_value("10 / 10", Color("#54e5d5"))
	top_row.add_child(base_label)

	var spring := Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spring)
	speed_button = _button("1×", Color("#8ad4e8"), 52.0)
	speed_button.custom_minimum_size = Vector2(52.0, 36.0)
	speed_button.pressed.connect(_on_speed_pressed)
	top_row.add_child(speed_button)
	prep_label = _top_value("100 秒", Color("#ffc967"))
	prep_label.name = "PrepCountdown"
	top_row.add_child(prep_label)
	start_button = _button("提前开战", Color("#ffc967"), 100.0)
	start_button.custom_minimum_size = Vector2(100.0, 36.0)
	start_button.pressed.connect(_on_start_pressed)
	top_row.add_child(start_button)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = ""
	status_label.visible = false
	status_label.add_theme_color_override("font_color", Color("#f2eee3"))
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.position = Vector2(16.0, 88.0)
	status_label.size = Vector2(560.0, 40.0)
	root.add_child(status_label)
	shop_hold_hint = Label.new()
	shop_hold_hint.name = "ShopHoldHint"
	shop_hold_hint.text = ""
	shop_hold_hint.visible = false
	shop_hold_hint.position = Vector2(16.0, 136.0)
	shop_hold_hint.size = Vector2(420.0, 22.0)
	shop_hold_hint.add_theme_color_override("font_color", Color("#ffbe66"))
	shop_hold_hint.add_theme_font_size_override("font_size", 12)
	root.add_child(shop_hold_hint)
	_build_npc_bubble(root)

	_tower_panel = PanelContainer.new()
	_tower_panel.name = "TowerPanel"
	_tower_panel.position = Vector2(24.0, 120.0)
	_tower_panel.size = Vector2(240.0, 156.0)
	_tower_panel.visible = false
	_tower_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tower_panel.add_theme_stylebox_override("panel", _style(Color(0.03, 0.06, 0.10, 0.86), Color("#237982"), 2, 6))
	root.add_child(_tower_panel)
	var tower_margin := _margin(10, 10, 8, 8)
	_tower_panel.add_child(tower_margin)
	var tower_row := HBoxContainer.new()
	tower_row.add_theme_constant_override("separation", 8)
	tower_margin.add_child(tower_row)
	tower_icon = _icon("res://assets/generated/towers/tower-lv1.png", Vector2(52.0, 64.0))
	tower_row.add_child(tower_icon)
	var tower_text := VBoxContainer.new()
	tower_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tower_row.add_child(tower_text)
	tower_name_label = Label.new()
	tower_name_label.text = "未选中"
	tower_name_label.add_theme_color_override("font_color", Color("#9af4d2"))
	tower_name_label.add_theme_font_size_override("font_size", 13)
	tower_text.add_child(tower_name_label)
	tower_info_label = Label.new()
	tower_info_label.text = "点击已放的塔"
	tower_info_label.add_theme_color_override("font_color", Color("#b4cbd0"))
	tower_info_label.add_theme_font_size_override("font_size", 10)
	tower_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tower_text.add_child(tower_info_label)
	tower_hint_label = Label.new()
	tower_hint_label.text = ""
	tower_hint_label.add_theme_color_override("font_color", Color("#ffbe66"))
	tower_hint_label.add_theme_font_size_override("font_size", 10)
	tower_text.add_child(tower_hint_label)
	var tower_buttons := VBoxContainer.new()
	tower_buttons.add_theme_constant_override("separation", 6)
	tower_row.add_child(tower_buttons)
	upgrade_button = _button("升级 U", Color("#73e9d0"), 76.0)
	upgrade_button.name = "UpgradeButton"
	upgrade_button.disabled = true
	upgrade_button.custom_minimum_size = Vector2(76.0, 40.0)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	tower_buttons.add_child(upgrade_button)
	sell_button = _button("出售", Color("#ffbe66"), 76.0)
	sell_button.name = "SellButton"
	sell_button.disabled = true
	sell_button.custom_minimum_size = Vector2(76.0, 36.0)
	sell_button.pressed.connect(_on_sell_pressed)
	tower_buttons.add_child(sell_button)

	_build_virtual_pad(root)
	_build_weapon_dock(root)
	_build_hero_select(root)
	_build_shop_panel(root)
	_overlay(root)
	_build_dev_panel(root)

## Builds the touch controls with one dominant attack action and spaced secondary actions.
func _build_virtual_pad(root: Control) -> void:
	_stick = (load("res://scripts/virtual_stick.gd") as GDScript).new()
	_stick.name = "MoveStick"
	_stick.position = Vector2(24.0, 508.0)
	_stick.size = Vector2(176.0, 176.0)
	root.add_child(_stick)
	attack_button = _circle_button("", Color("#f4f7f8"), 104.0)
	attack_button.name = "AttackButton"
	attack_button.tooltip_text = "攻击（J）"
	attack_button.position = Vector2(1152.0, 592.0)
	attack_button.expand_icon = true
	if _attack_icon == null:
		_attack_icon = _load_action_icon("res://assets/generated/ui/attack.png")
	attack_button.icon = _attack_icon
	attack_button.text = "攻" if _attack_icon == null else ""
	attack_button.z_index = 12
	attack_button.pressed.connect(_on_attack_pressed)
	root.add_child(attack_button)
	jump_button = _circle_button("", Color("#d7eef4"), 56.0)
	jump_button.name = "JumpButton"
	jump_button.tooltip_text = "跳跃（K）"
	jump_button.position = Vector2(1080.0, 632.0)
	if _jump_icon == null:
		_jump_icon = _load_action_icon("res://assets/generated/ui/action-jump-v2.png")
	jump_button.icon = _jump_icon
	jump_button.text = "跳" if _jump_icon == null else ""
	jump_button.z_index = 10
	jump_button.pressed.connect(_on_jump_pressed)
	root.add_child(jump_button)
	skill_button = _circle_button("", Color("#d7e8ff"), 56.0)
	skill_button.name = "SkillButton"
	skill_button.position = Vector2(1196.0, 520.0)
	skill_button.disabled = false
	skill_button.expand_icon = true
	if _dash_icon == null:
		_dash_icon = _load_action_icon("res://assets/generated/ui/dash.png")
	skill_button.icon = _dash_icon
	skill_button.text = "技" if _dash_icon == null else ""
	skill_button.z_index = 10
	skill_button.pressed.connect(_on_skill_pressed)
	_skill_overlay = SkillPadOverlay.new()
	_skill_overlay.name = "SkillPadOverlay"
	_skill_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skill_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skill_button.add_child(_skill_overlay)
	root.add_child(skill_button)
	talk_button = _circle_button("", Color("#ffe7b0"), 56.0)
	talk_button.name = "TalkButton"
	talk_button.tooltip_text = "交谈（E）"
	talk_button.position = Vector2(1000.0, 632.0)
	talk_button.visible = false
	if _talk_icon == null:
		_talk_icon = _load_action_icon("res://assets/generated/ui/action-talk-v2.png")
	talk_button.icon = _talk_icon
	talk_button.text = "谈" if _talk_icon == null else ""
	talk_button.z_index = 10
	talk_button.pressed.connect(_on_talk_pressed)
	root.add_child(talk_button)
	_build_minimap(root)

## Loads an action icon without emitting runtime errors while a generated asset is pending.
func _load_action_icon(texture_path: String) -> Texture2D:
	if not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path) as Texture2D

func _circle_button(text: String, color: Color, size: float) -> Button:
	var button := Button.new()
	button.text = text
	button.position = Vector2.ZERO
	button.custom_minimum_size = Vector2(size, size)
	button.size = Vector2(size, size)
	button.clip_text = true
	button.clip_contents = true
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_font_size_override("font_size", 18 if size >= 100.0 else 13)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(1.0, 1.0, 1.0, 0.28))
	_paint_circle(button, color, size, false)
	return button

func _paint_circle(button: Button, color: Color, size: float, active: bool) -> void:
	var radius := int(size * 0.5)
	var fill := Color(0.78, 0.82, 0.86, 0.50) if active else Color(0.72, 0.76, 0.80, 0.42)
	var ring := color if active else Color(0.86, 0.90, 0.94, 0.72)
	var hover := Color(0.80, 0.84, 0.88, 0.52)
	var pad := _icon_content_margin(size)
	button.add_theme_stylebox_override("normal", _circle_style(fill, ring, 3, radius, pad))
	button.add_theme_stylebox_override("hover", _circle_style(hover, Color(0.94, 0.96, 0.98, 0.86), 3, radius, pad))
	button.add_theme_stylebox_override("pressed", _circle_style(Color(0.82, 0.86, 0.90, 0.58), color, 3, radius, pad))
	button.add_theme_stylebox_override("disabled", _circle_style(Color(0.72, 0.76, 0.80, 0.18), Color(0.86, 0.90, 0.94, 0.28), 2, radius, pad))
	button.add_theme_stylebox_override("focus", _circle_style(fill, ring, 3, radius, pad))

## Keeps icon texels 1:1 with the circle's content box (96 / 48 / 32).
func _icon_content_margin(size: float) -> int:
	if size >= 100.0:
		return 4
	if size >= 60.0:
		return 8
	if size >= 52.0:
		return 4
	return 8

func _circle_style(fill: Color, border: Color, border_width: int, radius: int, content_margin: int = 8) -> StyleBoxFlat:
	var style := _style(fill, border, border_width, radius)
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	style.anti_aliasing = true
	return style

func _on_talk_pressed() -> void:
	talk_pressed.emit()

func _build_weapon_dock(root: Control) -> void:
	weapon_switch = _circle_button("", Color("#ffbe66"), 64.0)
	weapon_switch.name = "WeaponSwitch"
	weapon_switch.tooltip_text = "切换武器（Q）"
	weapon_switch.position = Vector2(1072.0, 552.0)
	weapon_switch.z_index = 10
	weapon_switch.pressed.connect(_on_weapon_switch_pressed)
	root.add_child(weapon_switch)

func _on_weapon_switch_pressed() -> void:
	weapon_switch_pressed.emit()


func _build_hero_select(root: Control) -> void:
	var kinds: Array[Dictionary] = [
		{"id": &"ember_hero", "tex": "res://assets/generated/ui/portrait-knight.png", "tip": "骑士"},
		{"id": &"assassin", "tex": "res://assets/generated/ui/portrait-assassin.png", "tip": "刺客"},
	]
	for i: int in range(kinds.size()):
		var spec: Dictionary = kinds[i]
		var button := _circle_button("", Color("#9af4d2"), 48.0)
		var kind := spec["id"] as StringName
		button.name = "HeroSelect_%s" % String(kind)
		button.tooltip_text = "选择%s" % String(spec["tip"])
		button.position = Vector2(1004.0 + float(i) * 56.0, 488.0)
		button.z_index = 10
		button.expand_icon = true
		var tex := load(String(spec["tex"])) as Texture2D
		if tex != null:
			button.icon = tex
			button.text = ""
		else:
			button.text = String(spec["tip"]).substr(0, 1)
		button.pressed.connect(_on_hero_kind_pressed.bind(kind))
		root.add_child(button)
		_hero_kind_buttons[kind] = button
	set_hero_kind(&"ember_hero")


func _on_hero_kind_pressed(kind: StringName) -> void:
	hero_kind_pressed.emit(kind)


func set_hero_kind(kind: StringName) -> void:
	_hero_kind = kind
	for key: Variant in _hero_kind_buttons.keys():
		var button := _hero_kind_buttons[key] as Button
		if button == null:
			continue
		var active := StringName(str(key)) == kind
		_paint_circle(button, Color("#9af4d2") if active else Color("#6f98a5"), 48.0, active)
	if attack_button != null:
		attack_button.icon = _attack_icon
		attack_button.text = "攻" if _attack_icon == null else ""
	if _weapon_dock_ready:
		set_weapon_dock(_weapon_slot_ids, _weapon_active_index, _turret_hand, _turret_kind, _turret_count)

func _top_value(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _stat_bar(caption: String, color: Color, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = caption
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.custom_minimum_size = Vector2(width, 14.0)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color(0.02, 0.03, 0.05, 0.9), Color("#22333c"), 1, 3))
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _metric_chip(caption: String, icon_path: String, accent: Color, width: float) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(width, 54.0)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _style(Color("#10283a"), Color("#1e5263"), 1, 4))
	var margin := _margin(7, 9, 5, 5)
	margin.name = "Margin"
	chip.add_child(margin)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	var icon := _icon(icon_path, Vector2(34.0, 34.0))
	row.add_child(icon)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.add_theme_color_override("font_color", Color("#6f98a5"))
	caption_label.add_theme_font_size_override("font_size", 9)
	text_box.add_child(caption_label)
	var value := Label.new()
	value.name = "Value"
	value.text = "--"
	value.add_theme_color_override("font_color", accent)
	value.add_theme_font_size_override("font_size", 15)
	text_box.add_child(value)
	chip.set_meta("value_label", value)
	return chip

func _build_interface_theme() -> Theme:
	var interface_theme := Theme.new()
	if DisplayServer.get_name() == "headless":
		return interface_theme
	interface_theme.default_font = UiFont.bundled()
	return interface_theme

func _icon(texture_path: String, size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	if not texture_path.is_empty():
		icon.texture = load(texture_path) as Texture2D
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _build_shop_panel(root: Control) -> void:
	shop_panel = PanelContainer.new()
	shop_panel.name = "ShopPanel"
	shop_panel.position = Vector2(16.0, 64.0)
	shop_panel.size = Vector2(1248.0, 68.0)
	shop_panel.custom_minimum_size = Vector2(1248.0, 68.0)
	shop_panel.clip_contents = true
	shop_panel.visible = false
	shop_panel.add_theme_stylebox_override("panel", _style(Color(0.02, 0.04, 0.07, 0.72), Color("#2c9a91"), 1, 5))
	root.add_child(shop_panel)
	var margin := _margin(8, 8, 6, 6)
	shop_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	shop_vendor_icon = _icon("res://assets/generated/npc/merchant.png", Vector2(44.0, 52.0))
	shop_vendor_icon.name = "ShopVendorIcon"
	row.add_child(shop_vendor_icon)
	shop_title = Label.new()
	shop_title.name = "ShopTitle"
	shop_title.text = "商人"
	shop_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shop_title.add_theme_color_override("font_color", Color("#9af4d2"))
	shop_title.add_theme_font_size_override("font_size", 13)
	shop_title.custom_minimum_size = Vector2(56.0, 40.0)
	row.add_child(shop_title)
	shop_buttons.clear()
	for index: int in range(4):
		var button := _button("货架 %d" % (index + 1), Color("#9af4d2"), 250.0)
		button.name = "ShopSlot%d" % index
		button.custom_minimum_size = Vector2(220.0, 52.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.expand_icon = true
		button.set_meta("shop_index", index)
		var shop_button := button
		shop_button.pressed.connect(func() -> void: shop_slot_pressed.emit(int(shop_button.get_meta("shop_index", -1))))
		row.add_child(button)
		shop_buttons.append(button)

func _build_npc_bubble(root: Control) -> void:
	npc_bubble = PanelContainer.new()
	npc_bubble.name = "NpcTalkBubble"
	npc_bubble.visible = false
	npc_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	npc_bubble.z_index = 20
	npc_bubble.custom_minimum_size = Vector2(120.0, 30.0)
	npc_bubble.add_theme_stylebox_override("panel", _style(Color(0.04, 0.08, 0.12, 0.92), Color("#9af4d2"), 2, 6))
	root.add_child(npc_bubble)
	var margin := _margin(10, 10, 5, 5)
	npc_bubble.add_child(margin)
	npc_bubble_label = Label.new()
	npc_bubble_label.text = "点柜台购买"
	npc_bubble_label.add_theme_color_override("font_color", Color("#f2eee3"))
	npc_bubble_label.add_theme_font_size_override("font_size", 12)
	margin.add_child(npc_bubble_label)


func _build_dev_panel(root: Control) -> void:
	dev_panel = PanelContainer.new()
	dev_panel.name = "DevPanel"
	dev_panel.visible = false
	dev_panel.position = Vector2(16.0, 280.0)
	dev_panel.size = Vector2(430.0, 204.0)
	dev_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dev_panel.z_index = 30
	dev_panel.add_theme_stylebox_override("panel", _style(Color(0.02, 0.05, 0.08, 0.88), Color("#ffbe66"), 2, 6))
	root.add_child(dev_panel)
	var margin := _margin(10, 10, 8, 8)
	dev_panel.add_child(margin)
	dev_label = Label.new()
	dev_label.name = "DevLabel"
	dev_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dev_label.add_theme_color_override("font_color", Color("#ffe7b0"))
	dev_label.add_theme_font_size_override("font_size", 11)
	margin.add_child(dev_label)


func set_dev_overlay(enabled: bool, body: String) -> void:
	if dev_panel == null:
		return
	_dev_visible = enabled
	dev_panel.visible = enabled
	if dev_label != null:
		dev_label.text = body
	_sync_context_overlays()


func _overlay(root: Control) -> void:
	overlay = ColorRect.new()
	overlay.name = "EndOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.01, 0.03, 0.07, 0.80)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)
	var panel := PanelContainer.new()
	panel.position = Vector2(358.0, 232.0)
	panel.size = Vector2(564.0, 252.0)
	panel.add_theme_stylebox_override("panel", _style(Color("#10283a"), Color("#2c9a91"), 2, 6))
	overlay.add_child(panel)
	var margin := _margin(30, 30, 24, 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	overlay_title = Label.new()
	overlay_title.name = "OverlayTitle"
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 29)
	overlay_title.add_theme_color_override("font_color", Color("#9bf4d1"))
	content.add_child(overlay_title)
	overlay_body = Label.new()
	overlay_body.name = "OverlayBody"
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.add_theme_font_size_override("font_size", 12)
	overlay_body.add_theme_color_override("font_color", Color("#b7cbd0"))
	content.add_child(overlay_body)
	var restart_button := _button("重新开始", Color("#9bf4d1"), 164.0)
	restart_button.name = "RestartButton"
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_button.pressed.connect(_on_restart_pressed)
	content.add_child(restart_button)

func _margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

func _button(text: String, color: Color, width: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 48.0)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#4d6b76"))
	button.add_theme_stylebox_override("normal", _style(Color("#122a3b"), Color("#28586a"), 1, 4))
	button.add_theme_stylebox_override("hover", _style(Color("#1b3b4c"), color, 2, 4))
	button.add_theme_stylebox_override("pressed", _style(Color("#0b1825"), color, 2, 4))
	button.add_theme_stylebox_override("disabled", _style(Color("#0b1925"), Color("#1d3644"), 1, 4))
	return button

func _style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style

func update_stats(scrap: int, core: int, wave: int, max_waves: int = 0) -> void:
	if resources_label == null:
		return
	resources_label.text = "%03d" % scrap
	base_label.text = "%02d / 10" % core
	wave_label.text = "无尽 %d" % wave

func update_status(message: String) -> void:
	if status_label == null:
		return
	status_label.text = message
	status_label.visible = not message.is_empty()
	_toast_left = 2.4 if not message.is_empty() else 0.0

func set_wave_button_enabled(enabled: bool, label_text: String = "开始波次") -> void:
	if start_button == null:
		return
	start_button.disabled = not enabled
	start_button.text = label_text

func set_speed_label(multiplier: float) -> void:
	if speed_button != null:
		speed_button.text = "%d×" % int(multiplier)

func poke_action_cluster() -> void:
	_action_cluster_left = 2.0

func set_shop_countdown(seconds_left: float) -> void:
	if prep_label == null:
		return
	if seconds_left <= 0.0:
		prep_label.text = ""
		return
	prep_label.text = "%d 秒" % int(ceil(seconds_left))

func set_hero_state(state: String) -> void:
	pass

func set_hero_hp(current: int, maximum: int, down: bool = false) -> void:
	if _hero_hp_bar != null:
		_hero_hp_bar.max_value = maxf(float(maximum), 1.0)
		_hero_hp_bar.value = 0.0 if down else float(current)
	if _hero_armor_bar != null:
		_hero_armor_bar.visible = false

func set_npc_prompt(visible: bool, world_pos: Vector2, text: String = "点柜台购买") -> void:
	if npc_bubble == null or npc_bubble_label == null:
		return
	npc_bubble.visible = visible
	if not visible:
		return
	npc_bubble_label.text = text
	var size := Vector2(maxi(int(npc_bubble_label.get_minimum_size().x) + 28, 128), 32)
	npc_bubble.custom_minimum_size = size
	npc_bubble.size = size
	var screen := get_viewport().get_canvas_transform() * world_pos
	npc_bubble.position = screen - Vector2(size.x * 0.5, size.y + 10.0)

func set_hold_hint(text: String) -> void:
	if shop_hold_hint == null:
		return
	shop_hold_hint.text = text
	shop_hold_hint.visible = not text.is_empty()

func set_loadout(weapon_name: String, dash_unlocked: bool) -> void:
	update_status("已装备%s%s" % [weapon_name, "  /  空格冲刺" if dash_unlocked else ""])

func set_weapon_dock(
	slot_ids: Array[StringName],
	active_index: int,
	turret_hand: bool = false,
	turret_kind: StringName = &"",
	turret_count: int = 0
) -> void:
	if weapon_switch == null:
		return
	_weapon_dock_ready = true
	_weapon_slot_ids = slot_ids.duplicate()
	_weapon_active_index = active_index
	_turret_hand = turret_hand
	_turret_kind = turret_kind
	_turret_count = turret_count
	if _weapon_count_label == null:
		_weapon_count_label = Label.new()
		_weapon_count_label.name = "WeaponCount"
		_weapon_count_label.position = Vector2(38.0, 40.0)
		_weapon_count_label.size = Vector2(28.0, 18.0)
		_weapon_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_weapon_count_label.add_theme_color_override("font_color", Color("#ffbe66"))
		_weapon_count_label.add_theme_font_size_override("font_size", 12)
		weapon_switch.add_child(_weapon_count_label)
	var other_index := 1 - active_index
	var other_filled := other_index >= 0 and other_index < slot_ids.size() and slot_ids[other_index] != &""
	var can_cycle := other_filled or turret_count > 0
	if turret_hand and turret_kind != &"":
		weapon_switch.text = ""
		weapon_switch.icon = load(_tower_dock_icon(turret_kind)) as Texture2D
		var tower_name := EmberTower.kind_display_name(turret_kind, 1)
		weapon_switch.tooltip_text = "炮台 / %s x%d" % [tower_name, maxi(turret_count, 1)]
		weapon_switch.modulate = Color.WHITE
		_weapon_count_label.text = "x%d" % maxi(turret_count, 1)
		_weapon_count_label.visible = true
		_paint_circle(weapon_switch, Color(0.98, 0.82, 0.32, 0.90), 64.0, true)
		return
	var current_id: StringName = &""
	if active_index >= 0 and active_index < slot_ids.size():
		current_id = slot_ids[active_index]
	var filled := current_id != &""
	var weapon := WeaponCatalog.get_def(current_id) if filled else {}
	weapon_switch.text = ""
	var path := String(weapon.get("pickup_path", "")) if filled else ""
	if path.is_empty() and filled:
		path = String(weapon.get("hold_path", ""))
	weapon_switch.icon = load(path) as Texture2D if path != "" else null
	var name := String(weapon.get("display_name", "武器")) if filled else "武器"
	weapon_switch.tooltip_text = "切换 / %s" % name if can_cycle else name
	weapon_switch.modulate = Color.WHITE if filled else Color(1.0, 1.0, 1.0, 0.38)
	_weapon_count_label.visible = false
	_paint_circle(weapon_switch, Color(0.86, 0.90, 0.94, 0.86) if can_cycle else Color(0.86, 0.90, 0.94, 0.72), 64.0, false)


func _tower_dock_icon(kind: StringName) -> String:
	if kind == &"burst":
		return "res://assets/generated/towers/burst-lv1.png"
	if kind == &"frost":
		return "res://assets/generated/towers/frost-lv1.png"
	return "res://assets/generated/towers/tower-lv1.png"

func set_talk_enabled(enabled: bool) -> void:
	if talk_button != null:
		talk_button.visible = enabled

func layout_for_home(in_home: bool) -> void:
	_in_home = in_home
	if dev_panel != null:
		dev_panel.position = Vector2(520.0, 280.0) if in_home else Vector2(16.0, 280.0)
	_sync_context_overlays()

## Gives the shop or developer overlay exclusive ownership of secondary HUD space.
func _sync_context_overlays() -> void:
	if _minimap != null:
		_minimap.visible = not _shop_visible and not _dev_visible
	if _tower_panel != null:
		_tower_panel.visible = not _in_home and not _shop_visible and not _dev_visible and _tower_panel_left > 0.0

## Builds the compact map whose visibility follows the shop overlay state.
func _build_minimap(root: Control) -> void:
	_minimap = MiniMap.new()
	_minimap.name = "MiniMap"
	_minimap.position = Vector2(1096.0, 48.0)
	_minimap.size = Vector2(168.0, 132.0)
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap.clip_contents = true
	_minimap.z_index = 5
	root.add_child(_minimap)

func update_minimap(
	hero_pos: Vector2,
	core_pos: Vector2,
	pads: Array,
	shop: Rect2,
	door: Rect2,
	combat: Rect2,
	hall: Rect2 = Rect2(),
	enemies: Array = [],
	shop_open: bool = true
) -> void:
	var map := get_node_or_null("HudRoot/MiniMap") as MiniMap
	if map == null:
		return
	map.hero_pos = hero_pos
	map.core_pos = core_pos
	map.pads = pads
	map.shop = shop
	map.door = door
	map.combat = combat
	map.hall = hall
	map.enemies = enemies
	map.shop_open = shop_open
	map.queue_redraw()

## Ready / casting / cooldown / locked skill pad, Soul Knight clock-wipe.
func set_skill(unlocked: bool, cooldown_left: float, cooldown_max: float = 12.0, skill_name: String = "冲刺", casting: bool = false) -> void:
	if skill_button != null:
		var on_cd := unlocked and not casting and cooldown_left > 0.05
		var ready := unlocked and not casting and not on_cd
		skill_button.disabled = not ready
		skill_button.icon = _dash_icon if unlocked else null
		skill_button.text = "" if _dash_icon != null or not unlocked else skill_name.substr(0, 1)
		_paint_circle(skill_button, Color(0.95, 0.98, 1.0, 0.95) if casting else Color(0.86, 0.90, 0.94, 0.72), 56.0, casting and unlocked)
		var look := skill_button.get_theme_stylebox("normal")
		if look != null:
			skill_button.add_theme_stylebox_override("disabled", look)
		skill_button.modulate = Color(1.0, 1.0, 1.0, 0.38) if not unlocked else Color.WHITE
		if _skill_overlay != null:
			if not unlocked:
				_skill_overlay.set("mode", &"locked")
				_skill_overlay.set("ratio", 0.0)
			elif casting:
				_skill_overlay.set("mode", &"casting")
				_skill_overlay.set("ratio", 0.0)
			elif on_cd:
				_skill_overlay.set("mode", &"cooldown")
				_skill_overlay.set("ratio", clampf(cooldown_left / maxf(cooldown_max, 0.1), 0.0, 1.0))
			else:
				_skill_overlay.set("mode", &"ready")
				_skill_overlay.set("ratio", 0.0)
			_skill_overlay.queue_redraw()
	if _hero_energy_bar == null:
		return
	var maximum := maxf(cooldown_max, 0.1)
	_hero_energy_bar.max_value = maximum
	if not unlocked:
		_hero_energy_bar.value = 0.0
	else:
		_hero_energy_bar.value = maximum - cooldown_left

## Shows the active vendor strip and suppresses the overlapping minimap while it is open.
func show_shop(visible: bool, vendor: StringName = &"") -> void:
	_shop_visible = visible
	if shop_panel != null:
		shop_panel.visible = visible
	_sync_context_overlays()
	if not visible:
		return
	var is_trainer := vendor == &"trainer"
	if shop_title != null:
		shop_title.text = "训练师" if is_trainer else "商人"
	if shop_vendor_icon != null:
		var icon_path := "res://assets/generated/npc/trainer.png" if is_trainer else "res://assets/generated/npc/merchant.png"
		shop_vendor_icon.texture = load(icon_path) as Texture2D

func set_shop_slots(slots: Array[Dictionary], scrap: int, vendor: StringName = &"") -> void:
	var shown := 0
	for index: int in range(slots.size()):
		var slot: Dictionary = slots[index]
		if vendor != &"" and StringName(slot.get("vendor", &"")) != vendor:
			continue
		if shown >= shop_buttons.size():
			break
		var button := shop_buttons[shown]
		button.visible = true
		button.set_meta("shop_index", index)
		var cost := int(slot.get("cost", 0))
		button.disabled = scrap < cost
		var icon_path := String(slot.get("icon", ""))
		button.icon = load(icon_path) as Texture2D if not icon_path.is_empty() and ResourceLoader.exists(icon_path) else null
		button.expand_icon = true
		button.tooltip_text = String(slot.get("detail", ""))
		button.text = "%s  %d" % [String(slot.get("title", "")), cost]
		shown += 1
	for rest: int in range(shown, shop_buttons.size()):
		shop_buttons[rest].visible = false
		shop_buttons[rest].disabled = true
		shop_buttons[rest].text = "—"

func set_tower_info(
	level: int,
	damage: int,
	attack_range: float,
	next_cost: int,
	can_upgrade: bool,
	kind: StringName = &"pulse",
	sell_refund: int = 0,
	can_sell: bool = false
) -> void:
	_tower_panel_left = 3.0
	if tower_name_label == null:
		return
	if WeaponCatalog.has_id(kind):
		var weapon := WeaponCatalog.get_def(kind)
		tower_name_label.text = String(weapon.get("display_name", "武器"))
		tower_info_label.text = "伤害 %02d  •  范围 %03d" % [damage, int(attack_range)]
		tower_hint_label.text = "武器炮不能升级"
		upgrade_button.disabled = true
		if sell_button != null:
			sell_button.disabled = not can_sell
			sell_button.text = "出售 %d" % sell_refund if can_sell else "出售"
		var hold_path := String(weapon.get("pickup_path", weapon.get("hold_path", "")))
		tower_icon.texture = load(hold_path) as Texture2D if hold_path != "" else null
		return
	tower_name_label.text = "等级 %d  /  %s" % [level, EmberTower.kind_display_name(kind, level)]
	tower_info_label.text = "伤害 %02d  •  范围 %03d" % [damage, int(attack_range)]
	tower_hint_label.text = "已满级" if next_cost <= 0 else "升级  /  %d 资源" % next_cost
	upgrade_button.disabled = not can_upgrade
	if sell_button != null:
		sell_button.disabled = not can_sell
		sell_button.text = "出售 %d" % sell_refund if can_sell else "出售"
	var icon_path := "res://assets/generated/towers/tower-lv%d.png" % level
	if kind == &"burst":
		icon_path = "res://assets/generated/towers/burst-lv%d.png" % level
	elif kind == &"frost":
		icon_path = "res://assets/generated/towers/frost-lv%d.png" % level
	tower_icon.texture = load(icon_path) as Texture2D

func clear_tower_info() -> void:
	_tower_panel_left = 0.0
	if _tower_panel != null:
		_tower_panel.visible = false
	if tower_name_label == null:
		return
	tower_name_label.text = "未选中"
	tower_info_label.text = "点击已放的塔查看"
	tower_hint_label.text = ""
	tower_icon.texture = load("res://assets/generated/towers/tower-lv1.png") as Texture2D
	upgrade_button.disabled = true
	if sell_button != null:
		sell_button.disabled = true
		sell_button.text = "出售"

func show_end_screen(_won: bool, defeated_count: int, wave: int = 0, survived_seconds: float = 0.0) -> void:
	overlay.visible = true
	overlay_title.text = "核心失守"
	overlay_title.add_theme_color_override("font_color", Color("#ff9b76"))
	var minutes := int(survived_seconds) / 60
	var seconds := int(survived_seconds) % 60
	overlay_body.text = "最高波次：%d\n击败单位：%d\n存活时间：%d:%02d\n重建防线后再次挑战。" % [wave, defeated_count, minutes, seconds]
	start_button.disabled = true
	show_shop(false)

func _tower_level_name(level: int) -> String:
	return "脉冲塔" if level == 1 else "聚能炮" if level == 2 else "雷霆核心"

func _on_start_pressed() -> void:
	start_wave_pressed.emit()

func _on_restart_pressed() -> void:
	restart_pressed.emit()

func _on_speed_pressed() -> void:
	speed_pressed.emit()

func _on_hero_pressed() -> void:
	hero_pressed.emit()

func _on_jump_pressed() -> void:
	_action_cluster_left = 2.0
	jump_pressed.emit()

func _on_attack_pressed() -> void:
	_action_cluster_left = 2.0
	attack_pressed.emit()

func _on_upgrade_pressed() -> void:
	upgrade_pressed.emit()

func _on_sell_pressed() -> void:
	sell_pressed.emit()

func _on_skill_pressed() -> void:
	_action_cluster_left = 2.0
	skill_pressed.emit()


class SkillPadOverlay extends Control:
	var mode: StringName = &"locked"
	var ratio := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(center.x, center.y) - 3.0
		if radius < 4.0:
			return
		match mode:
			&"locked":
				draw_circle(center, radius, Color(0.06, 0.07, 0.09, 0.58))
			&"cooldown":
				_draw_sweep(center, radius, ratio, Color(0.04, 0.05, 0.07, 0.70))
			&"casting":
				draw_arc(center, radius - 1.0, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.92), 3.0, true)
			&"ready":
				pass

	func _draw_sweep(center: Vector2, radius: float, fraction: float, color: Color) -> void:
		var amount := clampf(fraction, 0.0, 1.0)
		if amount <= 0.001:
			return
		if amount >= 0.999:
			draw_circle(center, radius, color)
			return
		var points := PackedVector2Array()
		points.append(center)
		var start := -PI * 0.5
		var span := TAU * amount
		var steps := maxi(4, int(round(48.0 * amount)))
		for i: int in range(steps + 1):
			var angle := start + span * (float(i) / float(steps))
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(points, color)


class MiniMap extends Control:
	const TRIM := Color(0.77, 0.63, 0.42, 0.82)
	const FLOOR := Color(0.16, 0.20, 0.24, 0.96)
	const SHOP_FLOOR := Color(0.22, 0.18, 0.13, 0.96)

	var hero_pos := Vector2.ZERO
	var core_pos := Vector2.ZERO
	var pads: Array = []
	var shop := Rect2()
	var door := Rect2()
	var combat := Rect2()
	var hall := Rect2()
	var enemies: Array = []
	var shop_open := true
	var _panel: StyleBoxFlat

	func _ready() -> void:
		custom_minimum_size = Vector2(168.0, 132.0)
		_panel = StyleBoxFlat.new()
		_panel.bg_color = Color(0.04, 0.06, 0.09, 0.92)
		_panel.border_color = TRIM
		_panel.set_border_width_all(1)
		_panel.set_corner_radius_all(6)
		_panel.anti_aliasing = false

	func _draw() -> void:
		var content := _content_rect()
		if content.size.x <= 1.0 or content.size.y <= 1.0:
			return
		if _panel == null:
			_ready()
		draw_style_box(_panel, Rect2(Vector2.ZERO, size))
		var here := _room_id(hero_pos)
		var hall_fill := FLOOR.lightened(0.10 if here == "hall" else 0.0)
		var combat_fill := FLOOR.lightened(0.10 if here == "combat" else 0.0)
		var shop_fill := SHOP_FLOOR if shop_open else Color(0.08, 0.07, 0.07, 0.94)
		if here == "shop":
			shop_fill = shop_fill.lightened(0.12)
		_fill_room(hall, hall_fill)
		_fill_room(combat, combat_fill)
		_fill_room(shop, shop_fill)
		_draw_link(shop, combat)
		_stroke_room(hall)
		_stroke_room(combat)
		_stroke_room(shop)
		for pad_pos: Variant in pads:
			if pad_pos is Vector2:
				var p := _map_point(pad_pos as Vector2)
				draw_rect(Rect2(p.x - 1.5, p.y - 1.5, 3.0, 3.0), Color(0.83, 0.69, 0.42, 0.88), true)
		for enemy_pos: Variant in enemies:
			if enemy_pos is Vector2:
				draw_circle(_map_point(enemy_pos as Vector2), 1.7, Color("#ff5f4d"))
		_draw_diamond(_map_point(core_pos), 4.0, Color("#54e5d5"))
		var hero := _map_point(hero_pos)
		draw_circle(hero, 3.4, Color(0.05, 0.06, 0.08, 0.95))
		draw_circle(hero, 2.2, Color(0.96, 0.96, 0.94))

	func _content_rect() -> Rect2:
		var bounds := Rect2()
		var started := false
		for room: Rect2 in [shop, door, combat, hall]:
			if room.size.x <= 1.0 or room.size.y <= 1.0:
				continue
			if started:
				bounds = bounds.merge(room)
			else:
				bounds = room
				started = true
		if not started:
			return Rect2()
		return bounds.grow(28.0)

	func _fit() -> Rect2:
		var content := _content_rect()
		var box := Rect2(Vector2(6.0, 6.0), size - Vector2(12.0, 12.0))
		if content.size.x <= 1.0 or content.size.y <= 1.0:
			return box
		var scale := minf(box.size.x / content.size.x, box.size.y / content.size.y)
		var used := content.size * scale
		return Rect2(box.position + (box.size - used) * 0.5, used)

	func _map_point(world_pos: Vector2) -> Vector2:
		var content := _content_rect()
		var inner := _fit()
		var u := (world_pos.x - content.position.x) / content.size.x
		var v := (world_pos.y - content.position.y) / content.size.y
		return inner.position + Vector2(u, v) * inner.size

	func _map_rect(world_rect: Rect2) -> Rect2:
		var a := _map_point(world_rect.position)
		var b := _map_point(world_rect.end)
		return Rect2(a, b - a)

	func _fill_room(room: Rect2, color: Color) -> void:
		if room.size.x <= 1.0 or room.size.y <= 1.0:
			return
		draw_rect(_map_rect(room), color, true)

	func _stroke_room(room: Rect2) -> void:
		if room.size.x <= 1.0 or room.size.y <= 1.0:
			return
		draw_rect(_map_rect(room), TRIM, false, 1.0)

	func _draw_link(a: Rect2, b: Rect2) -> void:
		if a.size.x <= 1.0 or b.size.x <= 1.0:
			return
		var ra := _map_rect(a)
		var rb := _map_rect(b)
		var overlap_x0 := maxf(ra.position.x, rb.position.x)
		var overlap_x1 := minf(ra.end.x, rb.end.x)
		var mid_x := (overlap_x0 + overlap_x1) * 0.5 if overlap_x1 > overlap_x0 else (ra.get_center().x + rb.get_center().x) * 0.5
		var width := maxf(overlap_x1 - overlap_x0, 12.0)
		var x0 := mid_x - width * 0.5
		var y0 := minf(ra.end.y, rb.end.y)
		var y1 := maxf(ra.position.y, rb.position.y)
		var gap := y1 - y0
		if gap <= 0.5:
			return
		var link := Rect2(x0, y0 - 0.5, width, gap + 1.0)
		draw_rect(link, FLOOR.lightened(0.06), true)
		draw_line(Vector2(link.position.x, link.position.y), Vector2(link.position.x, link.end.y), TRIM, 1.0)
		draw_line(Vector2(link.end.x, link.position.y), Vector2(link.end.x, link.end.y), TRIM, 1.0)

	func _room_id(point: Vector2) -> String:
		if shop.has_point(point) or door.has_point(point):
			return "shop"
		if hall.has_point(point):
			return "hall"
		return "combat"

	func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
		var points := PackedVector2Array([
			center + Vector2(0.0, -radius),
			center + Vector2(radius * 0.72, 0.0),
			center + Vector2(0.0, radius),
			center + Vector2(-radius * 0.72, 0.0),
		])
		draw_colored_polygon(points, color)

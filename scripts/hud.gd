class_name FrontierHud
extends CanvasLayer

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
signal default_tower_pressed
signal weapon_slot_pressed(index: int)
signal talk_pressed

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
var default_tower_button: Button
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
var _weapon_buttons: Array[Button] = []
var _weapon_icons: Array[TextureRect] = []
var _weapon_names: Array[Label] = []
var move_stick := Vector2.ZERO
var talk_button: Button
var _stick: Control
var _in_home := false

func _ready() -> void:
	_build_interface()

func _process(delta: float) -> void:
	if _toast_left > 0.0 and status_label != null:
		_toast_left = maxf(_toast_left - delta, 0.0)
		if _toast_left <= 0.0:
			status_label.text = ""
			status_label.visible = false
	_tower_panel_left = maxf(_tower_panel_left - delta, 0.0)
	if _tower_panel != null:
		_tower_panel.visible = (not _in_home) and _tower_panel_left > 0.0
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
	default_tower_button = _button("默认", Color("#9af4d2"), 76.0)
	default_tower_button.name = "DefaultTowerButton"
	default_tower_button.custom_minimum_size = Vector2(76.0, 40.0)
	default_tower_button.pressed.connect(_on_default_tower_pressed)
	tower_buttons.add_child(default_tower_button)

	_build_virtual_pad(root)
	_build_weapon_dock(root)
	_build_shop_panel(root)
	_overlay(root)
	_build_dev_panel(root)

func _build_virtual_pad(root: Control) -> void:
	_stick = (load("res://scripts/virtual_stick.gd") as GDScript).new()
	_stick.name = "MoveStick"
	_stick.position = Vector2(24.0, 508.0)
	_stick.size = Vector2(176.0, 176.0)
	root.add_child(_stick)
	attack_button = _circle_button("攻击", Color("#f4f7f8"), 108.0)
	attack_button.name = "AttackButton"
	attack_button.position = Vector2(1148.0, 564.0)
	attack_button.pressed.connect(_on_attack_pressed)
	root.add_child(attack_button)
	jump_button = _circle_button("跳跃", Color("#d7eef4"), 68.0)
	jump_button.name = "JumpButton"
	jump_button.position = Vector2(1064.0, 612.0)
	jump_button.pressed.connect(_on_jump_pressed)
	root.add_child(jump_button)
	skill_button = _circle_button("冲刺", Color("#d7e8ff"), 72.0)
	skill_button.name = "SkillButton"
	skill_button.position = Vector2(1172.0, 484.0)
	skill_button.disabled = true
	skill_button.pressed.connect(_on_skill_pressed)
	root.add_child(skill_button)
	talk_button = _circle_button("交谈", Color("#ffe7b0"), 68.0)
	talk_button.name = "TalkButton"
	talk_button.position = Vector2(1048.0, 524.0)
	talk_button.visible = false
	talk_button.pressed.connect(_on_talk_pressed)
	root.add_child(talk_button)
	_build_minimap(root)

func _circle_button(text: String, color: Color, size: float) -> Button:
	var button := Button.new()
	button.text = text
	button.position = Vector2.ZERO
	button.custom_minimum_size = Vector2(size, size)
	button.size = Vector2(size, size)
	button.clip_text = true
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.add_theme_font_size_override("font_size", 12 if size >= 100.0 else 11)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(1.0, 1.0, 1.0, 0.28))
	var radius := int(size * 0.5)
	button.add_theme_stylebox_override("normal", _style(Color(1.0, 1.0, 1.0, 0.12), Color(1.0, 1.0, 1.0, 0.42), 2, radius))
	button.add_theme_stylebox_override("hover", _style(Color(1.0, 1.0, 1.0, 0.22), Color.WHITE, 2, radius))
	button.add_theme_stylebox_override("pressed", _style(Color(1.0, 1.0, 1.0, 0.32), color, 3, radius))
	button.add_theme_stylebox_override("disabled", _style(Color(1.0, 1.0, 1.0, 0.06), Color(1.0, 1.0, 1.0, 0.16), 1, radius))
	return button

func _on_talk_pressed() -> void:
	talk_pressed.emit()

func _build_weapon_dock(root: Control) -> void:
	var dock := PanelContainer.new()
	dock.name = "WeaponDock"
	dock.position = Vector2(1108.0, 392.0)
	dock.size = Vector2(156.0, 72.0)
	dock.mouse_filter = Control.MOUSE_FILTER_STOP
	dock.add_theme_stylebox_override("panel", _style(Color(0.04, 0.06, 0.08, 0.55), Color(1.0, 1.0, 1.0, 0.22), 1, 10))
	root.add_child(dock)
	var margin := _margin(6, 6, 6, 6)
	dock.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	_weapon_buttons.clear()
	_weapon_icons.clear()
	_weapon_names.clear()
	for index: int in range(2):
		var slot := Button.new()
		slot.name = "WeaponSlot%d" % index
		slot.text = "空"
		slot.custom_minimum_size = Vector2(68.0, 56.0)
		slot.clip_text = true
		slot.expand_icon = true
		slot.add_theme_font_size_override("font_size", 10)
		slot.pressed.connect(_on_weapon_slot_pressed.bind(index))
		slot.add_theme_stylebox_override("normal", _style(Color(1.0, 1.0, 1.0, 0.08), Color(1.0, 1.0, 1.0, 0.22), 1, 8))
		slot.add_theme_stylebox_override("hover", _style(Color(1.0, 1.0, 1.0, 0.16), Color.WHITE, 1, 8))
		row.add_child(slot)
		_weapon_buttons.append(slot)
		_weapon_icons.append(TextureRect.new())
		_weapon_names.append(Label.new())

func _on_weapon_slot_pressed(index: int) -> void:
	weapon_slot_pressed.emit(index)

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
	var macos_cjk_font_path := "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
	if FileAccess.file_exists(macos_cjk_font_path):
		var cjk_font := FontFile.new()
		if cjk_font.load_dynamic_font(macos_cjk_font_path) == OK:
			interface_theme.default_font = cjk_font
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
	npc_bubble_label.text = "按 E 交谈"
	npc_bubble_label.add_theme_color_override("font_color", Color("#f2eee3"))
	npc_bubble_label.add_theme_font_size_override("font_size", 12)
	margin.add_child(npc_bubble_label)


func _build_dev_panel(root: Control) -> void:
	dev_panel = PanelContainer.new()
	dev_panel.name = "DevPanel"
	dev_panel.visible = false
	dev_panel.position = Vector2(16.0, 280.0)
	dev_panel.size = Vector2(360.0, 172.0)
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
	dev_panel.visible = enabled
	if dev_label != null:
		dev_label.text = body


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

func set_npc_prompt(visible: bool, world_pos: Vector2, text: String = "按 E 交谈") -> void:
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

func set_hold_hint(held_kind: StringName) -> void:
	if shop_hold_hint == null:
		return
	if held_kind == &"":
		shop_hold_hint.text = ""
		shop_hold_hint.visible = false
		return
	shop_hold_hint.text = "手持：%s — 点击地面放下" % EmberTower.kind_display_name(held_kind, 1)
	shop_hold_hint.visible = true

func set_loadout(weapon_name: String, dash_unlocked: bool) -> void:
	update_status("已装备%s%s" % [weapon_name, "  /  空格冲刺" if dash_unlocked else ""])

func set_weapon_dock(slot_ids: Array[StringName], active_index: int) -> void:
	for index: int in range(_weapon_buttons.size()):
		var filled := index < slot_ids.size() and slot_ids[index] != &""
		var weapon := WeaponCatalog.get_def(slot_ids[index]) if filled else {}
		var slot := _weapon_buttons[index]
		slot.text = String(weapon.get("display_name", "空")) if filled else "空"
		var path := String(weapon.get("hold_path", "")) if filled else ""
		slot.icon = load(path) as Texture2D if path != "" else null
		var active := filled and index == active_index
		slot.add_theme_stylebox_override(
			"normal",
			_style(Color("#1a3d3a") if active else Color("#10283a"), Color("#ffbe66") if active else Color("#1e5263"), 2 if active else 1, 4)
		)

func set_talk_enabled(enabled: bool) -> void:
	if talk_button != null:
		talk_button.visible = enabled

func layout_for_home(in_home: bool) -> void:
	_in_home = in_home
	if dev_panel != null:
		dev_panel.position = Vector2(520.0, 280.0) if in_home else Vector2(16.0, 280.0)
	if _tower_panel != null and in_home:
		_tower_panel.visible = false

func _build_minimap(root: Control) -> void:
	var map := MiniMap.new()
	map.name = "MiniMap"
	map.position = Vector2(1148.0, 58.0)
	map.size = Vector2(116.0, 156.0)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(map)

func update_minimap(
	hero_pos: Vector2,
	core_pos: Vector2,
	pads: Array,
	home: Rect2,
	world: Rect2,
	combat: Rect2
) -> void:
	var map := get_node_or_null("HudRoot/MiniMap") as MiniMap
	if map == null:
		return
	map.hero_pos = hero_pos
	map.core_pos = core_pos
	map.pads = pads
	map.home = home
	map.world = world
	map.combat = combat
	map.queue_redraw()

func set_skill(unlocked: bool, cooldown_left: float, cooldown_max: float = 6.0) -> void:
	if skill_button != null:
		skill_button.disabled = not unlocked or cooldown_left > 0.05
		if not unlocked:
			skill_button.text = "冲刺"
		elif cooldown_left > 0.05:
			skill_button.text = "%d" % ceili(cooldown_left)
		else:
			skill_button.text = "冲刺"
	if _hero_energy_bar == null:
		return
	var maximum := maxf(cooldown_max, 0.1)
	_hero_energy_bar.max_value = maximum
	if not unlocked:
		_hero_energy_bar.value = 0.0
	else:
		_hero_energy_bar.value = maximum - cooldown_left

func set_default_tower(kind: StringName) -> void:
	if default_tower_button != null:
		default_tower_button.text = EmberTower.kind_display_name(kind, 1).substr(0, 2)

func show_shop(visible: bool, vendor: StringName = &"") -> void:
	if shop_panel != null:
		shop_panel.visible = visible
	if not visible:
		return
	var is_trainer := vendor == &"trainer"
	if shop_title != null:
		shop_title.text = "训练师" if is_trainer else "商人"
	if shop_vendor_icon != null:
		var icon_path := "res://assets/generated/npc/trainer.png" if is_trainer else "res://assets/generated/npc/merchant.png"
		shop_vendor_icon.texture = load(icon_path) as Texture2D

func set_shop_slots(slots: Array[Dictionary], scrap: int, held_kind: StringName = &"", vendor: StringName = &"") -> void:
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
		var sold := bool(slot.get("sold", false))
		var cost := int(slot.get("cost", 0))
		button.disabled = sold or scrap < cost
		var icon_path := String(slot.get("icon", ""))
		button.icon = load(icon_path) as Texture2D if not icon_path.is_empty() and ResourceLoader.exists(icon_path) else null
		button.expand_icon = true
		button.tooltip_text = String(slot.get("detail", ""))
		var waiting := sold and held_kind != &"" and StringName(slot.get("payload", &"")) == held_kind
		if waiting:
			button.text = "%s  点地面" % String(slot.get("title", ""))
			button.disabled = true
		elif sold:
			button.text = "%s  已售" % String(slot.get("title", ""))
		else:
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

func _on_default_tower_pressed() -> void:
	default_tower_pressed.emit()


class MiniMap extends Control:
	var hero_pos := Vector2.ZERO
	var core_pos := Vector2.ZERO
	var pads: Array = []
	var home := Rect2()
	var world := Rect2()
	var combat := Rect2()

	func _ready() -> void:
		custom_minimum_size = Vector2(116.0, 156.0)

	func _draw() -> void:
		if world.size.x <= 1.0:
			return
		var pad := 4.0
		var box := Rect2(Vector2.ZERO, size)
		draw_rect(box, Color(0.04, 0.07, 0.10, 0.72), true)
		draw_rect(box, Color(1.0, 1.0, 1.0, 0.28), false, 1.0)
		var inner := Rect2(Vector2(pad, pad), size - Vector2(pad * 2.0, pad * 2.0))
		draw_rect(_map_rect(home, inner), Color(0.28, 0.36, 0.42, 0.55), true)
		draw_rect(_map_rect(combat, inner), Color(0.10, 0.16, 0.22, 0.70), true)
		draw_rect(_map_rect(combat, inner), Color(0.45, 0.62, 0.70, 0.45), false, 1.0)
		for pad_pos: Variant in pads:
			if pad_pos is Vector2:
				draw_circle(_map_point(pad_pos as Vector2, inner), 1.8, Color(0.55, 0.78, 1.0, 0.80))
		draw_circle(_map_point(core_pos, inner), 3.2, Color("#54e5d5"))
		draw_circle(_map_point(hero_pos, inner), 2.6, Color.WHITE)
		var font := get_theme_default_font()
		if font == null:
			font = ThemeDB.fallback_font
		draw_string(font, Vector2(8.0, 14.0), "地图", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#9aaeb6"))

	func _map_point(world_pos: Vector2, inner: Rect2) -> Vector2:
		var u := (world_pos.x - world.position.x) / world.size.x
		var v := (world_pos.y - world.position.y) / world.size.y
		return inner.position + Vector2(clampf(u, 0.0, 1.0) * inner.size.x, clampf(v, 0.0, 1.0) * inner.size.y)

	func _map_rect(world_rect: Rect2, inner: Rect2) -> Rect2:
		var a := _map_point(world_rect.position, inner)
		var b := _map_point(world_rect.end, inner)
		return Rect2(a, b - a)

class_name HomeRoom
extends Node2D

signal lighting_changed(daylight: bool)

## Empty hall + office-sheet furniture + station-pack desk/coffee. Night set is locked. Day swaps leftover sheet props. Never farm furniture, never cut from layout-ref.

const HOME_DIR := "res://assets/generated/home/"
const MANIFEST_PATH := "res://assets/generated/home/office-manifest.json"
const NIGHT_FLOOR_PATH := HOME_DIR + "floor-room.png"
const DAY_FLOOR_PATH := HOME_DIR + "floor-room-day.png"
const LIGHT_TRANSITION_DURATION := 0.72
const LIGHT_GLOW_ALPHA := 0.52

const CODER_POS := Vector2(635, 365)
const PLANT_POS := Vector2(325, 105)
const FRIDGE_POS := Vector2(815, 115)
const COFFEE_POS := Vector2(1125, 385)
const LANTERN_POS := Vector2(715, 76)
const LANTERN_HIT_SIZE := Vector2(72, 72)
const WALK_BOUNDS := Rect2(96, 108, 1088, 548)
const AIR_LAYER_ON := 0.5
## Footprint height in px. 0 = wall-hung, no floor block. Below JUMP_HEIGHT (32) is jumpable.
const AIR_HEIGHTS := {
	"CoderDesk": 48.0,
	"Plant": 18.0,
	"DayPlant": 18.0,
	"Fridge": 48.0,
	"DayFridge": 48.0,
	"Coffee": 42.0,
	"Workbench": 44.0,
	"OvertimeSign": 0.0,
	"SlackScreen": 0.0,
	"CodeSign": 0.0,
	"CodeWindow": 0.0,
	"Monument": 0.0,
	"Trash": 20.0,
	"Bookshelf": 46.0,
	"WaterCooler": 44.0,
	"Bestiary": 36.0,
	"Panda": 40.0,
	"DayPanda": 40.0,
	"Bull": 42.0,
	"DayBull": 42.0,
	"Chicken": 40.0,
	"DayChicken": 40.0,
	"CoffeeTable": 22.0,
	"Soda": 12.0,
	"PetBed": 24.0,
	"Controller": 8.0,
	"BookStack": 14.0,
	"Wrench": 10.0,
	"FloorPlant": 18.0,
	"DayFloorPlant": 16.0,
	"BallBox": 16.0,
	"Boxes": 22.0,
	"WetFloor": 24.0,
	"Skateboard": 10.0,
	"Dumbbell": 10.0,
	"Vacuum": 14.0,
	"Drone": 12.0,
	"Pizza": 14.0,
	"Doraemon": 22.0,
	"Chopper": 24.0,
}

var _air_walls: Array[Dictionary] = []
var _night_floor: Sprite2D
var _day_floor: Sprite2D
var _night_props: Node2D
var _day_props: Node2D
var _transition_glow: Sprite2D
var _transition_tween: Tween
var _transition_from_night_alpha := 1.0
var _transition_from_day_alpha := 0.0
var _transition_target_daylight: bool = false
var _is_daylight: bool = false
var _is_transitioning: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fill_void()
	_stamp_floor()
	_build_prop_layers()
	_stamp_pack_furniture()
	_stamp_office_furniture()
	_apply_lighting_state(false)


## Room interior the walker is clamped to. Stone walls are infinite height.
func walk_bounds() -> Rect2:
	return WALK_BOUNDS


## Named air wall `{name, rect, height, layer}`, or empty if missing / wall-hung.
func air_wall_named(prop_name: String) -> Dictionary:
	for wall: Dictionary in _air_walls:
		if String(wall.get("name", "")) == prop_name:
			return wall
	return {}


## True when the point sits in an active air wall taller than the current jump clearance.
func is_air_blocked(point: Vector2, air_clearance: float = 0.0) -> bool:
	if not WALK_BOUNDS.has_point(point):
		return true
	for wall: Dictionary in _air_walls:
		if not _air_layer_active(String(wall.get("layer", "both"))):
			continue
		var height := float(wall.get("height", 0.0))
		if height <= 0.0 or air_clearance >= height:
			continue
		var rect: Rect2 = wall.get("rect", Rect2())
		if rect.has_point(point):
			return true
	return false


## Slides along furniture like the battlefield clamp. Jump clearance skips shorter walls.
func clamp_walk(from: Vector2, next: Vector2, air_clearance: float = 0.0) -> Vector2:
	next.x = clampf(next.x, WALK_BOUNDS.position.x, WALK_BOUNDS.end.x)
	next.y = clampf(next.y, WALK_BOUNDS.position.y, WALK_BOUNDS.end.y)
	if not is_air_blocked(next, air_clearance):
		return next
	var slide_x := Vector2(from.x, next.y)
	var slide_y := Vector2(next.x, from.y)
	if not is_air_blocked(slide_x, air_clearance):
		return slide_x
	if not is_air_blocked(slide_y, air_clearance):
		return slide_y
	return from


func _fill_void() -> void:
	var void_rect := ColorRect.new()
	void_rect.name = "Void"
	void_rect.position = Vector2.ZERO
	void_rect.size = Vector2(1280, 720)
	void_rect.color = Color("07080c")
	void_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	void_rect.z_index = -2
	add_child(void_rect)


func _stamp_floor() -> void:
	_night_floor = _scaled_floor("Floor", NIGHT_FLOOR_PATH)
	_day_floor = _scaled_floor("DayFloor", DAY_FLOOR_PATH)
	_build_transition_glow()
	_build_lantern_toggle()


## Returns whether the room currently shows the daylight floor.
func is_daylight() -> bool:
	return _is_daylight


## Returns whether a day/night crossfade is still running.
func is_lighting_transitioning() -> bool:
	return _is_transitioning


## Toggles daylight once; repeated input is ignored until the transition finishes.
func toggle_daylight() -> bool:
	return set_daylight(not _is_daylight, true)


## Sets the requested lighting state with an optional crossfade.
func set_daylight(daylight: bool, animated: bool = true) -> bool:
	if _is_transitioning or _night_floor == null or _day_floor == null:
		return false
	if daylight == _is_daylight:
		return false
	if not animated:
		_apply_lighting_state(daylight)
		lighting_changed.emit(_is_daylight)
		return true

	_is_transitioning = true
	_transition_target_daylight = daylight
	_transition_from_night_alpha = _night_floor.modulate.a
	_transition_from_day_alpha = _day_floor.modulate.a
	_transition_tween = create_tween()
	_transition_tween.tween_method(_apply_lighting_transition, 0.0, 1.0, LIGHT_TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_transition_tween.finished.connect(_finish_lighting_transition)
	return true


func _scaled_floor(node_name: String, path: String) -> Sprite2D:
	var floor := _sprite(node_name, path, Vector2(640, 360), 720.0)
	floor.z_index = 0
	var tex: Texture2D = floor.texture
	if tex != null:
		floor.scale = Vector2(1280.0 / float(tex.get_width()), 720.0 / float(tex.get_height()))
	return floor


func _build_transition_glow() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.90), Color(1, 1, 1, 0.28), Color(1, 1, 1, 0.0)])
	var glow_texture := GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.width = 360
	glow_texture.height = 260
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.16)
	glow_texture.fill_to = Vector2(0.5, 1.0)
	var glow_material := CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_transition_glow = Sprite2D.new()
	_transition_glow.name = "LightingTransitionGlow"
	_transition_glow.texture = glow_texture
	_transition_glow.material = glow_material
	_transition_glow.position = LANTERN_POS + Vector2(0, 90)
	_transition_glow.modulate = Color(1, 1, 1, 0)
	_transition_glow.scale = Vector2(0.8, 0.8)
	_transition_glow.z_index = 1
	add_child(_transition_glow)


func _build_lantern_toggle() -> void:
	var button := Button.new()
	button.name = "LanternToggleButton"
	button.position = LANTERN_POS - LANTERN_HIT_SIZE * 0.5
	button.custom_minimum_size = LANTERN_HIT_SIZE
	button.size = LANTERN_HIT_SIZE
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.modulate = Color(1, 1, 1, 0.01)
	button.tooltip_text = "点击灯笼切换昼夜"
	button.z_index = 4
	button.pressed.connect(_on_lantern_pressed)
	add_child(button)


func _on_lantern_pressed() -> void:
	toggle_daylight()


func _apply_lighting_transition(progress: float) -> void:
	var target_day_alpha := 1.0 if _transition_target_daylight else 0.0
	var target_night_alpha := 0.0 if _transition_target_daylight else 1.0
	var pulse := sin(progress * PI)
	_day_floor.modulate = Color(1, 1, 1, lerpf(_transition_from_day_alpha, target_day_alpha, progress))
	_night_floor.modulate = Color(1, 1, 1, lerpf(_transition_from_night_alpha, target_night_alpha, progress))
	_sync_prop_layers()
	var glow_color := Color("ffc66d") if _transition_target_daylight else Color("78a8ff")
	glow_color.a = pulse * LIGHT_GLOW_ALPHA
	_transition_glow.modulate = glow_color
	_transition_glow.scale = Vector2.ONE * (0.8 + pulse * 0.24)


func _finish_lighting_transition() -> void:
	_apply_lighting_state(_transition_target_daylight)
	_is_transitioning = false
	lighting_changed.emit(_is_daylight)


func _apply_lighting_state(daylight: bool) -> void:
	_is_daylight = daylight
	_night_floor.modulate = Color(1, 1, 1, 0.0 if daylight else 1.0)
	_day_floor.modulate = Color(1, 1, 1, 1.0 if daylight else 0.0)
	_sync_prop_layers()
	_transition_glow.modulate = Color(1, 1, 1, 0)
	_transition_glow.scale = Vector2(0.8, 0.8)


func _sync_prop_layers() -> void:
	if _night_props != null:
		_night_props.modulate.a = _night_floor.modulate.a
	if _day_props != null:
		_day_props.modulate.a = _day_floor.modulate.a


func _build_prop_layers() -> void:
	_night_props = Node2D.new()
	_night_props.name = "NightProps"
	_night_props.z_index = 2
	add_child(_night_props)
	_day_props = Node2D.new()
	_day_props.name = "DayProps"
	_day_props.z_index = 2
	add_child(_day_props)


func _stamp_pack_furniture() -> void:
	_bind_air_wall(_sprite("CoderDesk", HOME_DIR + "desk-coder.png", CODER_POS, 210.0, self), "both")
	_bind_air_wall(_sprite("Plant", HOME_DIR + "plant.png", PLANT_POS, 72.0, _night_props), "night")
	_bind_air_wall(_sprite("Fridge", HOME_DIR + "vending.png", FRIDGE_POS, 140.0, _night_props), "night")
	_bind_air_wall(_sprite("Coffee", HOME_DIR + "coffee.png", COFFEE_POS, 118.0, _night_props), "night")
	_bind_air_wall(_sprite("DayPlant", HOME_DIR + "plant-day.png", PLANT_POS, 80.0, _day_props), "day")
	_bind_air_wall(_sprite("Workbench", HOME_DIR + "workbench.png", COFFEE_POS, 150.0, _day_props), "day")


func _stamp_office_furniture() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return
	for item: Variant in parsed:
		if not item is Dictionary:
			continue
		var spec: Dictionary = item
		var layer := String(spec.get("layer", "both"))
		var parent: Node = self
		if layer == "night":
			parent = _night_props
		elif layer == "day":
			parent = _day_props
		var sprite := Sprite2D.new()
		sprite.name = String(spec.get("name", "Prop"))
		sprite.texture = load(HOME_DIR + String(spec.get("file", ""))) as Texture2D
		sprite.centered = true
		sprite.flip_h = bool(spec.get("flip", false))
		sprite.position = Vector2(float(spec.get("x", 0.0)), float(spec.get("y", 0.0)))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 2
		var target_h := float(spec.get("h", 0.0))
		if target_h > 0.0 and sprite.texture != null and sprite.texture.get_height() > 0:
			var sc := target_h / float(sprite.texture.get_height())
			sprite.scale = Vector2(sc, sc)
		parent.add_child(sprite)
		_bind_air_wall(sprite, layer)


func _sprite(node_name: String, path: String, pos: Vector2, target_h: float, parent: Node = null) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(path) as Texture2D
	sprite.centered = true
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if sprite.texture != null and sprite.texture.get_height() > 0:
		var sc := target_h / float(sprite.texture.get_height())
		sprite.scale = Vector2(sc, sc)
	sprite.z_index = 2
	(parent if parent != null else self).add_child(sprite)
	return sprite


func _bind_air_wall(sprite: Sprite2D, layer: String) -> void:
	if sprite == null:
		return
	var height := float(AIR_HEIGHTS.get(sprite.name, -1.0))
	if height < 0.0:
		height = _default_air_height(sprite)
	if height <= 0.0:
		return
	var rect := _footprint_rect(sprite)
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return
	_air_walls.append({
		"name": sprite.name,
		"rect": rect,
		"height": height,
		"layer": layer,
	})


func _footprint_rect(sprite: Sprite2D) -> Rect2:
	if sprite.texture == null:
		return Rect2()
	var vis_w := float(sprite.texture.get_width()) * absf(sprite.scale.x)
	var vis_h := float(sprite.texture.get_height()) * absf(sprite.scale.y)
	var wide := sprite.name == "CoderDesk" or sprite.name == "Coffee" or sprite.name == "Workbench" or sprite.name == "CoffeeTable"
	var foot_w := vis_w * (0.78 if wide else 0.55)
	var foot_d := clampf(vis_h * (0.22 if wide else 0.16), 10.0, 36.0)
	var feet_y := sprite.position.y + vis_h * 0.5
	return Rect2(sprite.position.x - foot_w * 0.5, feet_y - foot_d, foot_w, foot_d)


func _default_air_height(sprite: Sprite2D) -> float:
	if sprite.texture == null:
		return 0.0
	var vis_h := float(sprite.texture.get_height()) * absf(sprite.scale.y)
	return clampf(vis_h * 0.28, 8.0, 56.0)


func _air_layer_active(layer: String) -> bool:
	if layer == "night":
		return _night_props != null and _night_props.modulate.a >= AIR_LAYER_ON
	if layer == "day":
		return _day_props != null and _day_props.modulate.a >= AIR_LAYER_ON
	return true

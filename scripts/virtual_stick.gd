class_name VirtualStick
extends Control

## Soul Knight-style left stick. Keyboard WASD still works alongside this.

var value := Vector2.ZERO

const RADIUS := 88.0
const KNOB := 34.0

var _dragging := false
var _knob := Vector2.ZERO
## -2 idle, -1 mouse, >=0 matching ScreenTouch.index so attack-finger-up cannot drop the stick.
var _pointer := -2
const POINTER_MOUSE := -1
const POINTER_NONE := -2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(220.0, 220.0)
	set_process_input(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _dragging and _pointer != POINTER_NONE and event.index != _pointer:
				return
			_pointer = event.index
			_press(event.position)
		elif event.index == _pointer:
			_release()
		accept_event()
	elif event is InputEventScreenDrag:
		if _pointer == POINTER_NONE or event.index == _pointer:
			_drag(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _dragging and _pointer >= 0:
				return
			_pointer = POINTER_MOUSE
			_press(event.position)
		elif _pointer == POINTER_MOUSE:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _dragging and _pointer == POINTER_MOUSE:
		_drag(event.position)
		accept_event()


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion and _pointer == POINTER_MOUSE:
		_drag(_to_local(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _pointer == POINTER_MOUSE:
		_release()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _pointer:
		_drag(_to_local(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed and event.index == _pointer:
		_release()
		get_viewport().set_input_as_handled()


func _to_local(viewport_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_pos


func _press(local: Vector2) -> void:
	_dragging = true
	set_process_input(true)
	_drag(local)


func _drag(local: Vector2) -> void:
	var center := size * 0.5
	var offset := local - center
	if offset.length() > RADIUS:
		offset = offset.normalized() * RADIUS
	_knob = offset
	value = offset / RADIUS
	if value.length() < 0.18:
		value = Vector2.ZERO
	queue_redraw()


func _release() -> void:
	_dragging = false
	_pointer = POINTER_NONE
	set_process_input(false)
	_knob = Vector2.ZERO
	value = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, RADIUS, Color(0.72, 0.76, 0.80, 0.42))
	draw_arc(center, RADIUS, 0.0, TAU, 48, Color(0.86, 0.90, 0.94, 0.72), 3.0, true)
	draw_circle(center + _knob, KNOB, Color(0.90, 0.93, 0.96, 0.82))
	draw_arc(center + _knob, KNOB, 0.0, TAU, 32, Color(0.94, 0.96, 0.98, 0.78), 2.0, true)

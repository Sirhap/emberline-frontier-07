class_name VirtualStick
extends Control

## Soul Knight-style left stick. Keyboard WASD still works alongside this.

var value := Vector2.ZERO

const RADIUS := 88.0
const KNOB := 34.0

var _dragging := false
var _knob := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(220.0, 220.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.position)
		else:
			_release()
		accept_event()
	elif event is InputEventScreenDrag:
		_drag(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(event.position)
		else:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_drag(event.position)
		accept_event()


func _press(local: Vector2) -> void:
	_dragging = true
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
	_knob = Vector2.ZERO
	value = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, RADIUS, Color(0.72, 0.76, 0.80, 0.42))
	draw_arc(center, RADIUS, 0.0, TAU, 48, Color(0.86, 0.90, 0.94, 0.72), 3.0, true)
	draw_circle(center + _knob, KNOB, Color(0.90, 0.93, 0.96, 0.82))
	draw_arc(center + _knob, KNOB, 0.0, TAU, 32, Color(0.94, 0.96, 0.98, 0.78), 2.0, true)

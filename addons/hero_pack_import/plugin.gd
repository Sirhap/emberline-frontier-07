@tool
extends EditorPlugin

var _dock: Control


func _enter_tree() -> void:
	_dock = preload("res://addons/hero_pack_import/import_dock.gd").new()
	_dock.name = "HeroPackImport"
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null

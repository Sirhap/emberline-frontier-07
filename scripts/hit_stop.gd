class_name EmberHitStop
extends RefCounted

## Hit-stop uses unscaled time so the pause is real, not stretched.

const MELEE_STOP := 0.03
const MELEE_SCALE := 0.08
const RANGED_STOP := 0.012
const RANGED_SCALE := 0.22

static var _busy := false


static func punch_melee(tree: SceneTree) -> void:
	await _punch(tree, MELEE_STOP, MELEE_SCALE)


static func punch_ranged(tree: SceneTree) -> void:
	await _punch(tree, RANGED_STOP, RANGED_SCALE)


static func _punch(tree: SceneTree, stop: float, scale: float) -> void:
	if _busy or tree == null:
		return
	_busy = true
	Engine.time_scale = scale
	await tree.create_timer(stop, true, false, true).timeout
	Engine.time_scale = 1.0
	_busy = false

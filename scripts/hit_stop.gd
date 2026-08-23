class_name EmberHitStop
extends RefCounted

## 30ms melee hit-stop. Uses unscaled time so the pause is real, not stretched.

const MELEE_STOP := 0.03
const MELEE_SCALE := 0.08

static var _busy := false


static func punch_melee(tree: SceneTree) -> void:
	if _busy or tree == null:
		return
	_busy = true
	Engine.time_scale = MELEE_SCALE
	await tree.create_timer(MELEE_STOP, true, false, true).timeout
	Engine.time_scale = 1.0
	_busy = false

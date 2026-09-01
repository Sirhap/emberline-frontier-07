class_name WeaponPose
extends RefCounted

## Handheld and hologram-pad weapon rotation. Keep pad and hand on the same numbers.

const MELEE_BOB_BASE_DEG := -18.0
const MELEE_BOB_AMP_DEG := 8.0
const MELEE_SWING_DEG := 78.0
const MELEE_PUNCH_FLOOR := 0.58
const MELEE_PUNCH_SPAN := 0.42
const MELEE_BOB_FREQ := 2.4


static func melee_punch(attacking: bool, progress: float) -> float:
	if not attacking:
		return 0.0
	return clampf(MELEE_PUNCH_FLOOR + MELEE_PUNCH_SPAN * clampf(progress, 0.0, 1.0), 0.0, 1.0)


static func apply_melee(sprite: Sprite2D, idle_time: float, punch: float, facing: int, copy_index: int = 0) -> void:
	var bob := deg_to_rad(MELEE_BOB_BASE_DEG + sin(idle_time * MELEE_BOB_FREQ + float(copy_index)) * MELEE_BOB_AMP_DEG)
	sprite.rotation = bob + punch * deg_to_rad(MELEE_SWING_DEG)
	if facing < 0:
		sprite.rotation = -sprite.rotation
	sprite.flip_h = facing < 0
	sprite.flip_v = false


static func apply_ranged(sprite: Sprite2D, aim: Vector2) -> void:
	if aim.is_zero_approx():
		aim = Vector2.RIGHT
	sprite.rotation = aim.angle()
	sprite.flip_v = aim.x < 0.0
	sprite.flip_h = false

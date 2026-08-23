class_name EmberHero
extends Node2D

signal state_changed(next_state: StringName)
signal attacked(origin: Vector2, facing: int)
signal ranged_fired(origin: Vector2, aim_dir: Vector2, weapon_id: StringName)
signal health_changed(current: int, maximum: int)
signal downed
signal revived
signal dash_used

const HERO_FRAME_SIZE := Vector2(256.0, 256.0)
const MOVE_SPEED := 165.0
const JUMP_DURATION := 0.50
const JUMP_HEIGHT := 32.0
const ATTACK_DURATION := 0.50
const ATTACK_PLAYBACK_SPEED := 1.0
const COMBO_END_FRAMES: Array[int] = [6, 19]
const COMBO_HIT_FRAMES: Array[int] = [3, 14]
const COMBO_HOLD := 0.05
const COMBO_WINDOW := 0.20
const FOLLOWUP_START_FRAME := 7
const WORLD_BOUNDS := Rect2(-80.0, -420.0, 1200.0, 1040.0)
const WEAPON_SLOT_COUNT := 2

var current_state: StringName = &"idle"
var _game: Node
var _xsxb_actor: CharacterBody2D
var _move_input := Vector2.ZERO
var _facing: int = 1
var _jump_elapsed: float = -1.0
var _jump_offset: float = 0.0
var _attack_elapsed: float = -1.0
var _attack_cooldown: float = 0.0
var _attack_hits_sent := 0
var _combo_step := 0
var _combo_queued := false
var _combo_hold := 0.0
var _combo_window := 0.0
var total_attack_hits_emitted := 0
var ranged_shots_emitted := 0
var _demo_state: StringName = &""
var _demo_state_time: float = 0.0
var max_health := 100
var health := 100
var down_duration := 4.0
var is_down := false
var current_weapon: StringName = &"sword"
var weapon_slots: Array[StringName] = [&"sword", &""]
var weapon_slot_index := 0
var _aim_dir := Vector2.RIGHT
var _recoil_bloom := 0.0
var _held_sprite: Sprite2D
var has_dash := false
var dash_cooldown := 6.0
var dash_cooldown_left := 0.0
var melee_damage := 46
var attack_bonus_level := 0
var vitality_level := 0
var dash_cd_level := 0
const DASH_COOLDOWNS: Array[float] = [6.0, 4.5, 3.5]
var revive_position := Vector2(234.0, 336.0)
var _hit_invuln := 0.0
var _dash_invuln := 0.0
var _dash_elapsed: float = -1.0
var _down_left := 0.0

func configure(game: Node, start_position: Vector2) -> void:
	_game = game
	position = start_position

func _ready() -> void:
	_build_xsxb_actor()
	queue_redraw()

func _process(delta: float) -> void:
	if _game == null:
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack_elapsed < 0.0:
		_combo_window = maxf(_combo_window - delta, 0.0)
	_demo_state_time = maxf(_demo_state_time - delta, 0.0)
	_hit_invuln = maxf(_hit_invuln - delta, 0.0)
	_dash_invuln = maxf(_dash_invuln - delta, 0.0)
	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	_update_down(delta)
	_update_dash(delta)
	_handle_movement(delta)
	_update_aim()
	_update_held_weapon()
	_recoil_bloom = maxf(_recoil_bloom - delta * 18.0, 0.0)
	_update_jump(delta)
	_update_attack(delta)
	_update_animation_state()
	queue_redraw()

func _handle_movement(delta: float) -> void:
	if is_down or _dash_elapsed >= 0.0:
		_move_input = Vector2.ZERO
		return
	var horizontal := 0.0
	var vertical := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		horizontal -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		horizontal += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		vertical -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		vertical += 1.0
	var stick := Vector2.ZERO
	if _game != null and _game.has_method("get_move_stick"):
		stick = _game.call("get_move_stick") as Vector2
	horizontal += stick.x
	vertical += stick.y
	move_in_direction(Vector2(horizontal, vertical), delta)

## Moves within the open defense room and is also used by input-neutral smoke tests.
func move_in_direction(direction: Vector2, delta: float) -> void:
	_move_input = direction.normalized() if not direction.is_zero_approx() else Vector2.ZERO
	if _move_input.is_zero_approx():
		return
	position = _clamp_world(position + _move_input * MOVE_SPEED * maxf(delta, 0.0))
	if absf(_move_input.x) > 0.01 and not WeaponCatalog.is_ranged(current_weapon):
		_apply_facing(1 if _move_input.x > 0.0 else -1)

func get_movement_bounds() -> Rect2:
	return WORLD_BOUNDS

func _clamp_world(next: Vector2) -> Vector2:
	if _game != null and _game.has_method("clamp_hero_position"):
		return _game.call("clamp_hero_position", position, next) as Vector2
	return Vector2(
		clampf(next.x, WORLD_BOUNDS.position.x, WORLD_BOUNDS.end.x),
		clampf(next.y, WORLD_BOUNDS.position.y, WORLD_BOUNDS.end.y)
	)

func _update_jump(delta: float) -> void:
	if _jump_elapsed < 0.0:
		return
	_jump_elapsed += delta
	var jump_duration := _animation_duration(&"jump", JUMP_DURATION)
	var progress := clampf(_jump_elapsed / jump_duration, 0.0, 1.0)
	# Frames are foot-planted in-place after cutout bake. Lift with code, but
	# keep anticipation and the landing squat on the ground.
	var air := clampf((progress - 0.12) / 0.72, 0.0, 1.0)
	_jump_offset = -sin(air * PI) * JUMP_HEIGHT
	if _xsxb_actor != null:
		_xsxb_actor.position.y = _jump_offset
	if progress >= 1.0:
		_jump_elapsed = -1.0
		_jump_offset = 0.0
		if _xsxb_actor != null:
			_xsxb_actor.position.y = 0.0

func _update_attack(delta: float) -> void:
	if _attack_elapsed < 0.0:
		return
	_attack_elapsed += delta
	_emit_current_combo_hit()
	var segment_end := COMBO_END_FRAMES[maxi(_combo_step - 1, 0)]
	if _actor_frame() < segment_end:
		_combo_hold = 0.0
		return
	if _combo_queued and _combo_step < COMBO_END_FRAMES.size():
		_open_next_combo_segment()
		return
	_combo_hold += delta
	if _combo_hold >= COMBO_HOLD:
		_finish_combo()

func _update_animation_state() -> void:
	if is_down or _dash_elapsed >= 0.0 or _attack_elapsed >= 0.0 or _jump_elapsed >= 0.0:
		return
	if not _move_input.is_zero_approx():
		_set_state(&"run")
		return
	if _demo_state_time > 0.0 and not _demo_state.is_empty():
		_set_state(_demo_state)
		return
	_set_state(&"idle")

## Instantiates the only gameplay-visible hero renderer from the XSXB manifest.
func _build_xsxb_actor() -> void:
	var actor_scene := load("res://xsxb_frame_tuner/runtime/xsxb_frame_actor.tscn") as PackedScene
	if actor_scene == null:
		push_error("XSXB hero runtime scene failed to load")
		return
	_xsxb_actor = actor_scene.instantiate() as CharacterBody2D
	_xsxb_actor.name = "XSXBHeroActor"
	_xsxb_actor.set("frame_profile_id", "ember_hero")
	_xsxb_actor.set("frame_animation", "idle")
	_xsxb_actor.set("use_frame_boxes", false)
	_xsxb_actor.set("fallback_visual_scale", 0.2893)
	add_child(_xsxb_actor)
	_held_sprite = Sprite2D.new()
	_held_sprite.name = "HeldWeapon"
	_held_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_held_sprite.centered = true
	_held_sprite.offset = Vector2.ZERO
	_held_sprite.z_index = 8
	_held_sprite.visible = false
	add_child(_held_sprite)
	_refresh_held_weapon()

func _animation_duration(animation_name: StringName, fallback: float) -> float:
	if _xsxb_actor != null and _xsxb_actor.has_method("animation_duration"):
		var duration := float(_xsxb_actor.call("animation_duration", String(animation_name)))
		if duration > 0.0:
			return duration
	return fallback

func request_jump() -> void:
	if is_down or _dash_elapsed >= 0.0:
		return
	if _jump_elapsed >= 0.0 or _attack_elapsed >= 0.0:
		return
	_demo_state = &""
	_demo_state_time = 0.0
	_jump_elapsed = 0.0
	_set_state(&"jump")

func request_attack() -> void:
	if is_down or _dash_elapsed >= 0.0:
		return
	if _jump_elapsed >= 0.0:
		return
	_demo_state = &""
	_demo_state_time = 0.0
	if WeaponCatalog.is_ranged(current_weapon):
		_fire_ranged()
		return
	if _combo_window > 0.0 and _attack_elapsed < 0.0:
		_start_followup_slash()
		return
	if _attack_elapsed >= 0.0:
		if _combo_step < COMBO_END_FRAMES.size() and _attack_hits_sent >= _combo_step:
			_combo_queued = true
		return
	if _attack_cooldown > 0.0:
		return
	_start_combo()

func _fire_ranged() -> void:
	if _attack_cooldown > 0.0:
		return
	var weapon := WeaponCatalog.get_def(current_weapon)
	_attack_cooldown = float(weapon["cooldown"])
	ranged_shots_emitted += 1
	var aim := aim_direction()
	var recoil := float(weapon.get("recoil", 18.0))
	position = _clamp_world(position - aim * recoil)
	_recoil_bloom = minf(14.0, _recoil_bloom + float(weapon.get("bloom", 3.5)))
	ranged_fired.emit(global_position + aim * 28.0 + Vector2(0.0, -18.0 + _jump_offset), aim, current_weapon)

func request_dash() -> void:
	if not has_dash or is_down or _dash_elapsed >= 0.0 or dash_cooldown_left > 0.0:
		return
	if _attack_elapsed >= 0.0:
		_finish_combo()
	_dash_elapsed = 0.0
	_dash_invuln = 0.30
	dash_cooldown_left = dash_cooldown
	_set_state(&"dash")
	dash_used.emit()

var debug_god := false

func take_damage(amount: int) -> void:
	if debug_god or is_down or _hit_invuln > 0.0 or _dash_invuln > 0.0:
		return
	health = maxi(health - maxi(amount, 0), 0)
	_hit_invuln = 0.40
	health_changed.emit(health, max_health)
	if health <= 0:
		_start_down()

func heal_percent(ratio: float) -> void:
	if is_down:
		return
	health = mini(max_health, health + int(floor(float(max_health) * ratio)))
	health_changed.emit(health, max_health)

func equip_weapon(weapon_id: StringName) -> void:
	if _attack_elapsed >= 0.0:
		_finish_combo()
	var found := weapon_slots.find(weapon_id)
	if found >= 0:
		weapon_slot_index = found
	else:
		var empty := weapon_slots.find(&"")
		if empty >= 0:
			weapon_slots[empty] = weapon_id
			weapon_slot_index = empty
		else:
			weapon_slots[weapon_slot_index] = weapon_id
	current_weapon = weapon_slots[weapon_slot_index]
	_attack_cooldown = 0.0
	_recoil_bloom = 0.0
	melee_damage = melee_strike_damage()
	_refresh_held_weapon()

func cycle_weapon() -> bool:
	var other := 1 - weapon_slot_index
	if other < 0 or other >= weapon_slots.size():
		return false
	if weapon_slots[other] == &"":
		return false
	if _attack_elapsed >= 0.0:
		_finish_combo()
	weapon_slot_index = other
	current_weapon = weapon_slots[other]
	_attack_cooldown = 0.0
	_recoil_bloom = 0.0
	melee_damage = melee_strike_damage()
	_refresh_held_weapon()
	return true

func select_weapon_slot(index: int) -> bool:
	if index < 0 or index >= weapon_slots.size() or weapon_slots[index] == &"":
		return false
	if _attack_elapsed >= 0.0:
		_finish_combo()
	weapon_slot_index = index
	current_weapon = weapon_slots[index]
	_attack_cooldown = 0.0
	melee_damage = melee_strike_damage()
	_refresh_held_weapon()
	return true

func melee_strike_damage() -> int:
	var weapon := WeaponCatalog.get_def(current_weapon)
	if weapon["kind"] != &"melee":
		return melee_damage
	return int(weapon["damage"]) + attack_bonus_level * 8

func aim_direction() -> Vector2:
	if _aim_dir.length_squared() < 0.01:
		return Vector2(float(_facing), 0.0)
	return _aim_dir.normalized()

func fire_spread_degrees() -> float:
	var weapon := WeaponCatalog.get_def(current_weapon)
	return float(weapon.get("spread_degrees", 0.0)) + _recoil_bloom

func _apply_facing(next_facing: int) -> void:
	_facing = next_facing
	if _xsxb_actor != null:
		_xsxb_actor.set("facing", _facing)

func _update_aim() -> void:
	if is_down:
		return
	var stick := Vector2.ZERO
	if _game != null and _game.has_method("get_move_stick"):
		stick = _game.call("get_move_stick") as Vector2
	if stick.length() >= 0.25:
		_aim_dir = stick.normalized()
		if WeaponCatalog.is_ranged(current_weapon) or absf(_aim_dir.x) > 0.01:
			_apply_facing(1 if _aim_dir.x >= 0.0 else -1)
		return
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() >= 8.0:
		_aim_dir = to_mouse.normalized()
		if WeaponCatalog.is_ranged(current_weapon):
			_apply_facing(1 if _aim_dir.x >= 0.0 else -1)

func _refresh_held_weapon() -> void:
	if _held_sprite == null:
		return
	var weapon := WeaponCatalog.get_def(current_weapon)
	var hold_path := String(weapon.get("hold_path", ""))
	var texture := load(hold_path) as Texture2D if hold_path != "" else null
	if texture == null:
		var pickup_path := String(weapon.get("pickup_path", ""))
		texture = load(pickup_path) as Texture2D if pickup_path != "" else null
	_held_sprite.texture = texture
	var hold_scale := float(weapon.get("hold_scale", 0.70))
	_held_sprite.scale = Vector2(hold_scale, hold_scale)
	var hold_offset: Variant = weapon.get("hold_offset", Vector2.ZERO)
	_held_sprite.offset = hold_offset as Vector2 if hold_offset is Vector2 else Vector2.ZERO
	_update_held_weapon()

func _update_held_weapon() -> void:
	if _held_sprite == null:
		return
	var weapon := WeaponCatalog.get_def(current_weapon)
	if is_down or _held_sprite.texture == null:
		_held_sprite.visible = false
		return
	_held_sprite.visible = true
	var aim := aim_direction()
	if weapon["kind"] == &"melee":
		var rest: Variant = weapon.get("hold_position", Vector2(14.0, -10.0))
		var strike: Variant = weapon.get("hold_attack_position", Vector2(22.0, -10.0))
		var hold_pos: Vector2 = (strike as Vector2) if _attack_elapsed >= 0.0 and strike is Vector2 else (rest as Vector2 if rest is Vector2 else Vector2(14.0, -10.0))
		_held_sprite.position = Vector2(float(_facing) * absf(hold_pos.x), hold_pos.y + _jump_offset)
		_held_sprite.rotation = deg_to_rad(-28.0 if _attack_elapsed < 0.0 else 18.0)
		if _facing < 0:
			_held_sprite.rotation = PI - _held_sprite.rotation
		_held_sprite.flip_v = _facing < 0
		return
	_held_sprite.position = Vector2(aim.x * 14.0, -8.0 + _jump_offset + aim.y * 8.0)
	_held_sprite.rotation = aim.angle()
	_held_sprite.flip_v = aim.x < 0.0

func unlock_dash() -> void:
	has_dash = true


func apply_attack_upgrade() -> bool:
	if attack_bonus_level >= 3:
		return false
	attack_bonus_level += 1
	melee_damage = melee_strike_damage()
	return true


func apply_vitality_upgrade() -> bool:
	if vitality_level >= 3:
		return false
	vitality_level += 1
	max_health += 20
	health = mini(max_health, health + 20)
	health_changed.emit(health, max_health)
	return true


func apply_dash_cd_upgrade() -> bool:
	if dash_cd_level >= 2:
		return false
	dash_cd_level += 1
	dash_cooldown = DASH_COOLDOWNS[dash_cd_level]
	return true

func get_facing() -> int:
	return _facing

func _start_down() -> void:
	is_down = true
	_down_left = down_duration
	_attack_elapsed = -1.0
	_dash_elapsed = -1.0
	_combo_step = 0
	_set_state(&"down")
	downed.emit()

func _update_down(delta: float) -> void:
	if not is_down:
		return
	_down_left -= delta
	if _down_left > 0.0:
		return
	is_down = false
	health = 40
	position = revive_position
	_hit_invuln = 0.40
	health_changed.emit(health, max_health)
	_set_state(&"idle")
	revived.emit()

func _update_dash(delta: float) -> void:
	if _dash_elapsed < 0.0:
		return
	_dash_elapsed += delta
	var dash_time := 0.22
	var step := 120.0 / dash_time * delta
	position = _clamp_world(position + Vector2(float(_facing) * step, 0.0))
	if _dash_elapsed >= dash_time:
		_dash_elapsed = -1.0

func set_demo_state(next_state: StringName) -> void:
	if next_state == &"jump":
		request_jump()
		return
	if next_state == &"attack":
		request_attack()
		return
	_demo_state = next_state
	_demo_state_time = 1.25
	_set_state(next_state)

func _set_state(next_state: StringName) -> void:
	if _xsxb_actor == null:
		return
	if current_state == next_state:
		return
	current_state = next_state
	_xsxb_actor.set("facing", _facing)
	_xsxb_actor.call("play_frame_animation", String(next_state), next_state in [&"idle", &"run"], true)
	state_changed.emit(next_state)

func _start_combo() -> void:
	_combo_step = 1
	_combo_queued = false
	_combo_hold = 0.0
	_combo_window = 0.0
	_attack_cooldown = 0.0
	_attack_elapsed = 0.0
	_attack_hits_sent = 0
	total_attack_hits_emitted = 0
	if current_state != &"attack":
		_set_state(&"attack")
	elif _xsxb_actor != null:
		_xsxb_actor.call("play_frame_animation", "attack", false, true)
	_apply_attack_playback(COMBO_END_FRAMES[0])


func _open_next_combo_segment() -> void:
	_combo_step += 1
	_combo_queued = false
	_combo_hold = 0.0
	_apply_attack_playback(COMBO_END_FRAMES[_combo_step - 1])


func _start_followup_slash() -> void:
	_combo_window = 0.0
	_combo_step = 2
	_combo_queued = false
	_combo_hold = 0.0
	_attack_elapsed = 0.0
	_attack_hits_sent = 1
	if current_state != &"attack":
		_set_state(&"attack")
	elif _xsxb_actor != null:
		_xsxb_actor.call("play_frame_animation", "attack", false, true)
	if _xsxb_actor != null and _xsxb_actor.has_method("seek_frame"):
		_xsxb_actor.call("seek_frame", FOLLOWUP_START_FRAME)
	_apply_attack_playback(COMBO_END_FRAMES[1])


func _finish_combo() -> void:
	var can_chain := _combo_step == 1
	_attack_elapsed = -1.0
	_combo_step = 0
	_combo_queued = false
	_combo_hold = 0.0
	_combo_window = COMBO_WINDOW if can_chain else 0.0
	if _xsxb_actor != null:
		_xsxb_actor.set("playback_end_frame", -1)
	if _move_input.is_zero_approx():
		_set_state(&"idle")
	else:
		_set_state(&"run")


func _emit_current_combo_hit() -> void:
	if _combo_step <= 0 or _attack_hits_sent >= _combo_step:
		return
	if _actor_frame() < COMBO_HIT_FRAMES[_combo_step - 1]:
		return
	_attack_hits_sent += 1
	total_attack_hits_emitted += 1
	attacked.emit(global_position + Vector2(28.0 * _facing, -18.0 + _jump_offset), _facing)


func _apply_attack_playback(end_frame: int) -> void:
	if _xsxb_actor == null:
		return
	_xsxb_actor.set("playback_speed", ATTACK_PLAYBACK_SPEED)
	if _xsxb_actor.has_method("limit_playback_to_frame"):
		_xsxb_actor.call("limit_playback_to_frame", end_frame)


func _actor_frame() -> int:
	if _xsxb_actor != null and _xsxb_actor.has_method("current_frame_index"):
		return int(_xsxb_actor.current_frame_index())
	if _attack_elapsed > 0.05:
		return clampi(int(_attack_elapsed * 16.0 * ATTACK_PLAYBACK_SPEED), 0, COMBO_END_FRAMES[COMBO_END_FRAMES.size() - 1])
	return 0


func _draw() -> void:
	var shadow_width := 16.0 + absf(_jump_offset) * 0.04
	draw_shadow_ellipse(Vector2(0.0, 4.0), Vector2(shadow_width, 4.0), Color(0.01, 0.03, 0.07, 0.58))
	var bar_y := -58.0 + _jump_offset
	draw_rect(Rect2(-18.0, bar_y - 2.0, 36.0, 6.0), Color(0.01, 0.02, 0.06, 0.86))
	var hp_ratio := clampf(float(health) / float(maxi(max_health, 1)), 0.0, 1.0)
	var hp_color := Color("#7cffb2") if not is_down else Color("#6a7180")
	draw_rect(Rect2(-16.0, bar_y, 32.0 * hp_ratio, 3.0), hp_color)
	if is_down:
		draw_arc(Vector2(0.0, -20.0), 22.0, 0.0, TAU, 20, Color(0.90, 0.30, 0.28, 0.55), 2.0)

func draw_shadow_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

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
const MIN_ATTACK_READ := 0.28
const FOLLOWUP_START_FRAME := 7
const WORLD_BOUNDS := Rect2(-80.0, -680.0, 2560.0, 2300.0)
const WEAPON_SLOT_COUNT := 2
const CLONE_COUNT := 3
const FORGE_CAP := 5
const SKILL_CAP_KNIGHT := 2
const SKILL_CAP_ASSASSIN := 3
const TURRET_HOLD_SCALE := 0.42
const CLONE_RADIUS := 110.0
const CLONE_DURATION := 5.0
const CLONE_MOVE_SPEED := 165.0
const CLONE_LOCK_RANGE := 320.0
const CLONE_ATTACK_RANGE := 118.0
const HERO_LOCK_RANGE := 250.0
const CLONE_HIT_FRAME := 4
const ASSASSIN_VISUAL_SCALE := 0.38
const KNIGHT_VISUAL_SIZE := 0.34
const LEGACY_HOLD_HEIGHT := 74.0

var current_state: StringName = &"idle"
var hero_kind: StringName = &"ember_hero"
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
var turret_stash: Dictionary = {}
var item_stash: Dictionary = {"scrap": 0, "heal": 0, "weapons": []}
var turret_hand := false
var weapon_forge: Dictionary = {}
var skill_levels: Dictionary = {&"ember_hero": 0, &"assassin": 0}
var _aim_dir := Vector2.RIGHT
var _recoil_bloom := 0.0
var _held_sprite: Sprite2D
var _float_sprites: Array[Sprite2D] = []
var _float_time := 0.0
var has_dash := true
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
var _combo_end: Array[int] = COMBO_END_FRAMES.duplicate()
var _combo_hit: Array[int] = COMBO_HIT_FRAMES.duplicate()
var _followup_start := FOLLOWUP_START_FRAME
var _clone_nodes: Array[Node2D] = []
var _clone_spawned := false
var _attack_lock: FrontierEnemy = null

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
	_float_time += delta
	_update_held_weapon()
	_recoil_bloom = maxf(_recoil_bloom - delta * 18.0, 0.0)
	_update_jump(delta)
	_update_attack(delta)
	_update_clones(delta)
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
	# Stick still walks this way. Facing during a swing comes from lock/aim so
	# a mid-attack turn does not restart the clip.
	if _attack_elapsed < 0.0 and absf(_move_input.x) > 0.01 and not WeaponCatalog.is_ranged(combat_weapon_id()):
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
	_keep_melee_clip()
	_emit_current_combo_hit()
	var segment_end := _combo_end[maxi(_combo_step - 1, 0)]
	var segment_time := _combo_segment_duration()
	if _attack_elapsed < MIN_ATTACK_READ:
		_combo_hold = 0.0
		return
	# Trust the playing melee clip's frame. Idle's _current_frame used to
	# trip combo_end on the first tick (body stays idle, overlay sparks).
	if _actor_frame() < segment_end and _attack_elapsed < segment_time * 1.5:
		_combo_hold = 0.0
		return
	if _combo_queued and _combo_step < _combo_end.size():
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
	if _xsxb_actor != null:
		_xsxb_actor.name = "XSXBHeroActorOld"
		if _xsxb_actor.get_parent() == self:
			remove_child(_xsxb_actor)
		_xsxb_actor.queue_free()
		_xsxb_actor = null
	_xsxb_actor = actor_scene.instantiate() as CharacterBody2D
	_xsxb_actor.name = "XSXBHeroActor"
	var assassin := hero_kind == &"assassin"
	_xsxb_actor.set("frame_project_id", "emberline_enemies" if assassin else "emberline_frontier_07_final")
	_xsxb_actor.set("frame_profile_id", "ember_assassin" if assassin else "ember_hero")
	_xsxb_actor.set("frame_animation", "idle")
	_xsxb_actor.set("use_frame_boxes", false)
	_xsxb_actor.set("fallback_visual_scale", ASSASSIN_VISUAL_SCALE if assassin else KNIGHT_VISUAL_SIZE)
	add_child(_xsxb_actor)
	_xsxb_actor.z_index = 1
	_ensure_float_sprites(maxi(_orbit_copy_count(), 1))
	_refresh_held_weapon()


func apply_hero_kind(kind: StringName) -> void:
	var next := &"assassin" if kind == &"assassin" else &"ember_hero"
	if hero_kind == next and _xsxb_actor != null:
		return
	if _attack_elapsed >= 0.0:
		_finish_combo()
	_combo_window = 0.0
	_clear_clones()
	_dash_elapsed = -1.0
	hero_kind = next
	if hero_kind == &"assassin":
		_combo_end = [7, 7]
		_combo_hit = [4, 4]
		_followup_start = 0
	else:
		_combo_end = COMBO_END_FRAMES.duplicate()
		_combo_hit = COMBO_HIT_FRAMES.duplicate()
		_followup_start = FOLLOWUP_START_FRAME
	_build_xsxb_actor()
	current_state = &""
	_set_state(&"idle")
	_refresh_held_weapon()


func _clip_name(state: StringName) -> String:
	if hero_kind != &"assassin":
		return String(state)
	match state:
		&"run":
			return "walk"
		&"dash":
			return "skill_cast"
		_:
			return String(state)

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
	if combat_weapon_id() == &"":
		return
	_demo_state = &""
	_demo_state_time = 0.0
	if WeaponCatalog.is_ranged(combat_weapon_id()):
		_fire_ranged()
		return
	if _combo_window > 0.0 and _attack_elapsed < 0.0:
		_apply_hero_lock()
		_start_followup_slash()
		_update_held_weapon()
		return
	if _attack_elapsed >= 0.0:
		_apply_hero_lock()
		if _combo_step < _combo_end.size() and _attack_hits_sent >= _combo_step:
			_combo_queued = true
		return
	if _attack_cooldown > 0.0:
		return
	_apply_hero_lock()
	_start_combo()
	_update_held_weapon()

func _fire_ranged() -> void:
	if _attack_cooldown > 0.0:
		return
	var weapon_id := combat_weapon_id()
	if weapon_id == &"":
		return
	var weapon := WeaponCatalog.get_def(weapon_id)
	_attack_cooldown = float(weapon["cooldown"])
	ranged_shots_emitted += 1
	_apply_hero_lock()
	_update_held_weapon()
	var aim := aim_direction()
	# Recoil only blooms spread. Shoving `position` made the hero walk backward after each shot.
	_recoil_bloom = minf(14.0, _recoil_bloom + float(weapon.get("bloom", 3.5)))
	var muzzles := combat_float_origins()
	if muzzles.is_empty():
		muzzles.append(global_position + aim * 28.0 + Vector2(0.0, -18.0 + _jump_offset))
	for muzzle: Vector2 in muzzles:
		ranged_fired.emit(muzzle, aim, weapon_id)
	_play_ranged_body_clip()


func _play_ranged_body_clip() -> void:
	# combo_step 0 holds the attack clip without emitting melee hits.
	_combo_step = 0
	_combo_queued = false
	_combo_hold = 0.0
	_combo_window = 0.0
	_attack_elapsed = 0.0
	_attack_hits_sent = 0
	if current_state != &"attack":
		_set_state(&"attack")
	_play_melee_clip(1)
	_apply_attack_playback(_combo_end[0])


func request_dash() -> void:
	if not has_dash or is_down or _dash_elapsed >= 0.0 or dash_cooldown_left > 0.0:
		return
	if _attack_elapsed >= 0.0:
		_finish_combo()
	_dash_elapsed = 0.0
	_clone_spawned = false
	if hero_kind == &"assassin":
		_dash_invuln = _animation_duration(&"skill_cast", 0.80)
		_spawn_shadow_clones()
		_clone_spawned = true
	else:
		_dash_invuln = 0.30
	dash_cooldown_left = dash_cooldown
	_set_state(&"dash")
	if _game != null and _game.has_method("clear_enemy_bullets_in_radius"):
		_game.call("clear_enemy_bullets_in_radius", global_position, 72.0)
	dash_used.emit()

func is_casting_skill() -> bool:
	return _dash_elapsed >= 0.0

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

func combat_weapon_id() -> StringName:
	if weapon_slot_index >= 0 and weapon_slot_index < weapon_slots.size() and weapon_slots[weapon_slot_index] != &"":
		return weapon_slots[weapon_slot_index]
	if current_weapon != &"":
		return current_weapon
	return &""


func floating_weapon_count() -> int:
	if combat_weapon_id() == &"":
		return 0
	if hero_kind == &"assassin":
		return 1
	return mini(skill_level_for(&"ember_hero") + 1, 3)


func combat_float_origins() -> Array[Vector2]:
	var origins: Array[Vector2] = []
	for sprite: Sprite2D in _combat_float_sprites():
		origins.append(sprite.global_position)
	return origins


func _combat_float_sprites() -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	if turret_hand:
		return sprites
	for sprite: Sprite2D in _float_sprites:
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		sprites.append(sprite)
	return sprites


func float_sprite_near(origin: Vector2) -> Sprite2D:
	var best: Sprite2D = null
	var best_d := 40.0 * 40.0
	for sprite: Sprite2D in _combat_float_sprites():
		var d := sprite.global_position.distance_squared_to(origin)
		if d <= best_d:
			best_d = d
			best = sprite
	return best


func slash_swing_tilt_near(origin: Vector2) -> float:
	var best := float_sprite_near(origin)
	if best == null:
		return 0.0
	var tilt := best.rotation
	if _facing < 0:
		tilt = -tilt
	return tilt


func _orbit_copy_count() -> int:
	if turret_hand:
		return 1 if current_turret_kind() != &"" else 0
	return floating_weapon_count()


func _tower_hold_path(kind: StringName) -> String:
	if kind == &"burst":
		return "res://assets/generated/towers/burst-lv1.png"
	if kind == &"frost":
		return "res://assets/generated/towers/frost-lv1.png"
	return "res://assets/generated/towers/tower-lv1.png"


func add_turret(kind: StringName) -> void:
	if not EmberRunSave.is_valid_tower_kind(kind):
		return
	turret_stash[kind] = int(turret_stash.get(kind, 0)) + 1


func set_turret_hand(on: bool) -> bool:
	if on:
		if turret_stash_count() <= 0:
			turret_hand = false
			_refresh_held_weapon()
			return false
		if _attack_elapsed >= 0.0:
			_finish_combo()
		turret_hand = true
		_refresh_held_weapon()
		return true
	var was_on := turret_hand
	turret_hand = false
	_refresh_held_weapon()
	return was_on


func take_turret() -> StringName:
	var kind := current_turret_kind()
	if kind == &"":
		return &""
	var left := int(turret_stash.get(kind, 0)) - 1
	if left <= 0:
		turret_stash.erase(kind)
	else:
		turret_stash[kind] = left
	if turret_stash_count() <= 0:
		turret_hand = false
	_refresh_held_weapon()
	return kind


func current_turret_kind() -> StringName:
	for kind: StringName in [&"pulse", &"burst", &"frost"]:
		if int(turret_stash.get(kind, 0)) > 0:
			return kind
	return &""


func turret_stash_count() -> int:
	var total := 0
	for value: Variant in turret_stash.values():
		total += int(value)
	return total


func turret_kind_count(kind: StringName) -> int:
	return int(turret_stash.get(kind, 0))


func forge_level_for(weapon_id: StringName) -> int:
	return clampi(int(weapon_forge.get(weapon_id, 0)), 0, FORGE_CAP)


func forge_damage_mult(weapon_id: StringName) -> float:
	return 1.0 + 0.10 * float(forge_level_for(weapon_id))


func skill_level_for(kind: StringName) -> int:
	return int(skill_levels.get(kind, 0))


func skill_cap_for(kind: StringName) -> int:
	return SKILL_CAP_ASSASSIN if kind == &"assassin" else SKILL_CAP_KNIGHT


func apply_forge_upgrade(weapon_id: StringName) -> bool:
	if weapon_id == &"" or forge_level_for(weapon_id) >= FORGE_CAP:
		return false
	weapon_forge[weapon_id] = forge_level_for(weapon_id) + 1
	melee_damage = melee_strike_damage()
	return true


func apply_skill_upgrade() -> bool:
	var cap := skill_cap_for(hero_kind)
	var level := skill_level_for(hero_kind)
	if level >= cap:
		return false
	skill_levels[hero_kind] = level + 1
	_ensure_float_sprites(maxi(_orbit_copy_count(), 1))
	_refresh_held_weapon()
	_update_held_weapon()
	return true


func take_current_weapon() -> StringName:
	if turret_hand:
		return &""
	var taken := combat_weapon_id()
	if taken == &"":
		return &""
	weapon_slots[weapon_slot_index] = &""
	var other := 1 - weapon_slot_index
	if other >= 0 and other < weapon_slots.size() and weapon_slots[other] != &"":
		weapon_slot_index = other
		current_weapon = weapon_slots[other]
	else:
		current_weapon = &""
	_attack_cooldown = 0.0
	melee_damage = melee_strike_damage()
	_refresh_held_weapon()
	return taken


func receive_weapon(weapon_id: StringName) -> void:
	if weapon_id == &"" or not WeaponCatalog.has_id(weapon_id):
		return
	var empty := weapon_slots.find(&"")
	if empty >= 0:
		weapon_slots[empty] = weapon_id
		if current_weapon == &"":
			weapon_slot_index = empty
			current_weapon = weapon_id
	else:
		weapon_slots[weapon_slot_index] = weapon_id
		current_weapon = weapon_id
	turret_hand = false
	_refresh_held_weapon()


func equip_weapon(weapon_id: StringName) -> void:
	if _attack_elapsed >= 0.0:
		_finish_combo()
	turret_hand = false
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
	var filled: Array[int] = []
	for index: int in range(weapon_slots.size()):
		if weapon_slots[index] != &"":
			filled.append(index)
	var has_turret := turret_stash_count() > 0
	if turret_hand:
		if filled.is_empty():
			return false
		turret_hand = false
		return select_weapon_slot(filled[0])
	var next_slot := -1
	for index: int in filled:
		if index > weapon_slot_index:
			next_slot = index
			break
	if next_slot >= 0:
		return select_weapon_slot(next_slot)
	if has_turret:
		if _attack_elapsed >= 0.0:
			_finish_combo()
		turret_hand = true
		_refresh_held_weapon()
		return true
	if filled.size() >= 2:
		return select_weapon_slot(filled[0])
	return false

func select_weapon_slot(index: int) -> bool:
	if index < 0 or index >= weapon_slots.size() or weapon_slots[index] == &"":
		return false
	if _attack_elapsed >= 0.0:
		_finish_combo()
	turret_hand = false
	weapon_slot_index = index
	current_weapon = weapon_slots[index]
	_attack_cooldown = 0.0
	melee_damage = melee_strike_damage()
	_refresh_held_weapon()
	return true

func melee_strike_damage() -> int:
	var weapon_id := combat_weapon_id()
	if weapon_id == &"":
		return 0
	var weapon := WeaponCatalog.get_def(weapon_id)
	var base := int(weapon["damage"]) if weapon["kind"] == &"melee" else melee_damage
	base += attack_bonus_level * 8
	return maxi(1, int(round(float(base) * forge_damage_mult(weapon_id))))

func aim_direction() -> Vector2:
	if _aim_dir.length_squared() < 0.01:
		return Vector2(float(_facing), 0.0)
	return _aim_dir.normalized()

func fire_spread_degrees() -> float:
	var weapon := WeaponCatalog.get_def(combat_weapon_id())
	return float(weapon.get("spread_degrees", 0.0)) + _recoil_bloom

func clone_count() -> int:
	return mini(CLONE_COUNT + skill_level_for(&"assassin"), 6)

func _apply_facing(next_facing: int) -> void:
	var face := 1 if next_facing >= 0 else -1
	if _facing == face:
		if _xsxb_actor != null:
			_xsxb_actor.set("facing", face)
		return
	_facing = face
	if _xsxb_actor == null:
		return
	_xsxb_actor.set("facing", _facing)
	# Flip in place. Never seek(0) or replay the live clip.
	if _xsxb_actor.has_method("_apply_frame_visual"):
		_xsxb_actor.call("_apply_frame_visual")

func _apply_hero_lock() -> bool:
	if _game == null or not _game.has_method("find_enemy_in_range"):
		_attack_lock = null
		return false
	var target := _game.call("find_enemy_in_range", global_position, HERO_LOCK_RANGE) as FrontierEnemy
	if target == null:
		_attack_lock = null
		return false
	_attack_lock = target
	_face_lock_target(target)
	return true


func _face_lock_target(target: FrontierEnemy) -> void:
	if target == null or not is_instance_valid(target) or not target.is_active():
		return
	var to := target.hurt_center() - global_position
	if to.length_squared() < 0.0001:
		return
	_aim_dir = to.normalized()
	_apply_facing(1 if _aim_dir.x >= 0.0 else -1)


func _refresh_attack_lock() -> bool:
	if _attack_lock != null:
		if is_instance_valid(_attack_lock) and _attack_lock.is_active() and _attack_lock.hurt_gap(global_position) <= HERO_LOCK_RANGE:
			_face_lock_target(_attack_lock)
			return true
		_attack_lock = null
	return _apply_hero_lock()


func _update_aim() -> void:
	if is_down:
		return
	# Soft lock owns aim while swinging. Stick still moves the body.
	# No enemy in range: keep the tap facing. Do not idle-snap or retarget mid-clip.
	if _attack_elapsed >= 0.0:
		_refresh_attack_lock()
		return
	var stick := Vector2.ZERO
	if _game != null and _game.has_method("get_move_stick"):
		stick = _game.call("get_move_stick") as Vector2
	if stick.length() >= 0.25:
		_aim_dir = stick.normalized()
		if WeaponCatalog.is_ranged(combat_weapon_id()) or absf(_aim_dir.x) > 0.01:
			_apply_facing(1 if _aim_dir.x >= 0.0 else -1)
		return
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() >= 8.0:
		_aim_dir = to_mouse.normalized()
		if WeaponCatalog.is_ranged(combat_weapon_id()):
			_apply_facing(1 if _aim_dir.x >= 0.0 else -1)

func _actor_on_screen_height() -> float:
	# Foot-planted frames keep empty canvas above the head. Scale holds by the
	# opaque body, not the padded canvas, so y=-22 lands on the fist.
	var body_px := 213.0 if hero_kind == &"assassin" else 239.0
	if _xsxb_actor != null:
		var owner := _xsxb_actor.get_node_or_null("VisualOwner") as Node2D
		if owner != null:
			var height := absf(owner.scale.y) * body_px
			if height > 16.0:
				return height
	if hero_kind == &"assassin":
		return body_px * ASSASSIN_VISUAL_SCALE
	return body_px * KNIGHT_VISUAL_SIZE


func _held_pose_scale() -> float:
	return maxf(1.0, _actor_on_screen_height() / LEGACY_HOLD_HEIGHT)


func _ensure_float_sprites(count: int) -> void:
	if _float_sprites.is_empty() and _held_sprite != null:
		_float_sprites.append(_held_sprite)
	while _float_sprites.size() < maxi(count, 1):
		var index := _float_sprites.size()
		var sprite := Sprite2D.new()
		sprite.name = "HeldWeapon" if index == 0 else "HeldOrbit%d" % index
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = true
		sprite.offset = Vector2.ZERO
		sprite.z_index = 0
		sprite.visible = false
		add_child(sprite)
		_float_sprites.append(sprite)
	if not _float_sprites.is_empty():
		_held_sprite = _float_sprites[0]
	for extra: int in range(maxi(count, 0), _float_sprites.size()):
		_float_sprites[extra].visible = false
		_float_sprites[extra].texture = null


func _float_orbit(index: int, count: int) -> Vector2:
	var pose := _held_pose_scale()
	var face := 1.0 if _facing >= 0 else -1.0
	var bob := sin(_float_time * 3.4 + float(index) * 1.7) * 2.6
	var jump := _jump_offset
	var hip_y := -14.0 * pose
	# 256 canvas * visual scale: sit outside the torso, hip-height sides only.
	var visual := HERO_FRAME_SIZE.x * (ASSASSIN_VISUAL_SCALE if hero_kind == &"assassin" else KNIGHT_VISUAL_SIZE)
	var out := visual * 0.5 + 12.0
	var local := Vector2(face * out, hip_y)
	if count == 2:
		var dir := 1.0 if (index % 2) == 0 else -1.0
		local = Vector2(dir * out, hip_y)
	elif count >= 3:
		match index % 3:
			0:
				local = Vector2(out, hip_y)
			1:
				local = Vector2(-out, hip_y)
			_:
				local = Vector2(-face * (out + 10.0), hip_y)
	return Vector2(local.x, local.y + bob + jump)


func _refresh_held_weapon() -> void:
	var copies := _orbit_copy_count()
	_ensure_float_sprites(maxi(copies, 1))
	if copies <= 0 or is_down:
		for sprite: Sprite2D in _float_sprites:
			sprite.visible = false
			sprite.texture = null
		return
	var texture: Texture2D = null
	var pose := _held_pose_scale()
	var hold_scale := 0.70 * pose
	if turret_hand:
		texture = load(_tower_hold_path(current_turret_kind())) as Texture2D
		hold_scale = TURRET_HOLD_SCALE * pose
	else:
		var weapon := WeaponCatalog.get_def(combat_weapon_id())
		var hold_path := String(weapon.get("hold_path", ""))
		texture = load(hold_path) as Texture2D if hold_path != "" else null
		if texture == null:
			var pickup_path := String(weapon.get("pickup_path", ""))
			texture = load(pickup_path) as Texture2D if pickup_path != "" else null
		hold_scale = float(weapon.get("hold_scale", 0.70)) * pose
	for index: int in range(_float_sprites.size()):
		var sprite := _float_sprites[index]
		if index >= copies or texture == null:
			sprite.visible = false
			sprite.texture = null
			continue
		sprite.texture = texture
		sprite.scale = Vector2(hold_scale, hold_scale)
		sprite.offset = Vector2.ZERO
		sprite.visible = true
	_update_held_weapon()


func _update_held_weapon() -> void:
	var copies := _orbit_copy_count()
	if copies <= 0 or is_down:
		for sprite: Sprite2D in _float_sprites:
			sprite.visible = false
		return
	var pose := _held_pose_scale()
	var hold_scale := TURRET_HOLD_SCALE * pose
	var aim := aim_direction()
	var melee := false
	if not turret_hand:
		var weapon := WeaponCatalog.get_def(combat_weapon_id())
		if weapon.is_empty():
			return
		hold_scale = float(weapon.get("hold_scale", 0.70)) * pose
		melee = StringName(weapon.get("kind", &"")) == &"melee"
	for index: int in range(_float_sprites.size()):
		var sprite := _float_sprites[index]
		if index >= copies or sprite.texture == null:
			sprite.visible = false
			continue
		sprite.visible = true
		sprite.scale = Vector2(hold_scale, hold_scale)
		var pos := _float_orbit(index, copies)
		if melee and sprite.texture != null:
			var side := 1.0 if pos.x >= 0.0 else -1.0
			pos.x += side * sprite.texture.get_size().x * hold_scale * 0.16
			if hero_kind == &"assassin" and _attack_elapsed >= 0.0:
				pos.x += side * 14.0
		sprite.position = pos
		sprite.z_index = 0
		if turret_hand:
			sprite.rotation = sin(_float_time * 2.4 + float(index)) * 0.06
			sprite.flip_h = _facing < 0
			sprite.flip_v = false
		elif melee:
			var bob := deg_to_rad(-18.0 + sin(_float_time * 2.4 + float(index)) * 8.0)
			var swing := 0.0
			if _attack_elapsed >= 0.0:
				# Same tap as the body: already in attack pose on frame 0, peak with the hit frame.
				var hit_f := float(_combo_hit[maxi(_combo_step - 1, 0)])
				var punch := clampf(0.58 + 0.42 * (float(_actor_frame()) / maxf(hit_f, 1.0)), 0.0, 1.0)
				swing = punch * deg_to_rad(78.0)
			sprite.rotation = bob + swing
			if _facing < 0:
				sprite.rotation = -sprite.rotation
			sprite.flip_h = _facing < 0
			sprite.flip_v = false
		else:
			sprite.rotation = aim.angle()
			sprite.flip_v = aim.x < 0.0
			sprite.flip_h = false

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
	# Soul Knight endless TD: death ends the run. Game listens on `downed`.
	if _game != null and _game.has_method("notify_hero_defeated"):
		_game.call("notify_hero_defeated")
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
	if hero_kind == &"assassin":
		var skill_time := _animation_duration(&"skill_cast", 0.80)
		if _dash_elapsed >= skill_time:
			_dash_elapsed = -1.0
		return
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
	# Facing flips mid-swing only mirror the sprite. Never replay or drop to idle.
	_xsxb_actor.set("facing", _facing)
	if _attack_elapsed >= 0.0 and next_state != &"attack" and next_state != &"down" and next_state != &"dash":
		return
	if current_state == next_state:
		return
	current_state = next_state
	var clip := _clip_name(next_state)
	var already := str(_xsxb_actor.get("_current_animation")) == clip
	_xsxb_actor.call("play_frame_animation", clip, next_state in [&"idle", &"run"], not already)
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
	_play_melee_clip(_combo_step)
	_apply_attack_playback(_combo_end[0])


func _open_next_combo_segment() -> void:
	_combo_step += 1
	_combo_queued = false
	_combo_hold = 0.0
	_play_melee_clip(_combo_step)
	_apply_attack_playback(_combo_end[_combo_step - 1])


func _start_followup_slash() -> void:
	_combo_window = 0.0
	_combo_step = 2
	_combo_queued = false
	_combo_hold = 0.0
	_attack_elapsed = 0.0
	_attack_hits_sent = 1
	if current_state != &"attack":
		_set_state(&"attack")
	_play_melee_clip(2)
	if hero_kind != &"assassin" and _xsxb_actor != null and _xsxb_actor.has_method("seek_frame"):
		_xsxb_actor.call("seek_frame", _followup_start)
	_apply_attack_playback(_combo_end[1])


func _finish_combo() -> void:
	var can_chain := _combo_step == 1
	_attack_elapsed = -1.0
	_attack_lock = null
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
	if _actor_frame() < _combo_hit[_combo_step - 1]:
		return
	_attack_hits_sent += 1
	total_attack_hits_emitted += 1
	var body_origin := global_position + Vector2(28.0 * _facing, -18.0 + _jump_offset)
	attacked.emit(body_origin, _facing)
	var floats := _combat_float_sprites()
	for extra: int in range(1, floats.size()):
		attacked.emit(floats[extra].global_position, _facing)


func _apply_attack_playback(end_frame: int) -> void:
	if _xsxb_actor == null:
		return
	_xsxb_actor.set("playback_speed", ATTACK_PLAYBACK_SPEED)
	if _xsxb_actor.has_method("limit_playback_to_frame"):
		_xsxb_actor.call("limit_playback_to_frame", end_frame)


func _melee_clip_for_step(step: int) -> String:
	if hero_kind == &"assassin" and step >= 2:
		return "attack_b"
	return "attack"


func _keep_melee_clip() -> void:
	if _xsxb_actor == null:
		return
	var want := _melee_clip_for_step(maxi(_combo_step, 1))
	var playing := str(_xsxb_actor.get("_current_animation"))
	if playing == want:
		return
	# Recover a stolen idle/run clip. Never seek(0) a live attack / attack_b.
	var restart := playing not in ["attack", "attack_b"]
	_xsxb_actor.call("play_frame_animation", want, false, restart)
	_apply_attack_playback(_combo_end[maxi(_combo_step - 1, 0)])


func _combo_segment_duration() -> float:
	var clip := _melee_clip_for_step(maxi(_combo_step, 1))
	var end_frame := _combo_end[maxi(_combo_step - 1, 0)]
	var start_frame := 0
	if hero_kind != &"assassin" and _combo_step >= 2:
		start_frame = _followup_start
	if _xsxb_actor != null and _xsxb_actor.has_method("trail_frame_arrival_time"):
		var t0 := float(_xsxb_actor.call("trail_frame_arrival_time", clip, start_frame, 0.0))
		var t1 := float(_xsxb_actor.call("trail_frame_arrival_time", clip, end_frame, 1.0))
		return maxf(MIN_ATTACK_READ, t1 - t0)
	return maxf(MIN_ATTACK_READ, float(end_frame - start_frame + 1) / 12.0)


func _play_melee_clip(step: int) -> void:
	if _xsxb_actor == null:
		return
	_xsxb_actor.call("play_frame_animation", _melee_clip_for_step(step), false, true)


func _spawn_shadow_clones() -> void:
	_clear_clones()
	var bubble: Array[Texture2D] = []
	for index: int in range(8):
		var frame_path := "res://assets/generated/hero/assassin-bubble-%d.png" % index
		if ResourceLoader.exists(frame_path):
			bubble.append(load(frame_path) as Texture2D)
	if bubble.is_empty():
		return
	var host := _clone_host()
	var clones := clone_count()
	for clone_i: int in range(clones):
		var clone := Node2D.new()
		clone.name = "ShadowClone%d" % clone_i
		clone.z_index = 3
		var angle := TAU * float(clone_i) / float(clones) - 0.35
		var radius := CLONE_RADIUS + (28.0 if clone_i == 0 else 0.0)
		var spawn := global_position + Vector2(cos(angle), sin(angle) * 0.55) * radius
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = true
		sprite.position = Vector2(0.0, -384.0 * ASSASSIN_VISUAL_SCALE * 0.5)
		sprite.scale = Vector2(ASSASSIN_VISUAL_SCALE, ASSASSIN_VISUAL_SCALE)
		sprite.modulate = Color(0.94, 1.0, 0.90, 0.72)
		sprite.flip_h = _facing < 0
		sprite.texture = bubble[0]
		clone.add_child(sprite)
		clone.set_meta("phase", &"bubble")
		clone.set_meta("life", CLONE_DURATION)
		clone.set_meta("index", 0)
		clone.set_meta("accum", 0.0)
		clone.set_meta("delay", 0.12 * float(clone_i))
		clone.set_meta("hit_sent", false)
		clone.set_meta("facing", _facing)
		clone.set_meta("bubble", bubble)
		host.add_child(clone)
		clone.global_position = spawn
		_clone_nodes.append(clone)


func _clone_host() -> Node:
	if _game != null:
		return _game
	return self


func _clone_clip_textures(clip: String) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if _xsxb_actor == null:
		return out
	var anims: Dictionary = _xsxb_actor.get("_animations")
	var frames: Array = (anims.get(clip, {}) as Dictionary).get("frames", []) as Array
	for frame_value: Variant in frames:
		if not frame_value is Dictionary:
			continue
		var tex := (frame_value as Dictionary).get("texture") as Texture2D
		if tex != null:
			out.append(tex)
	return out


func _clone_clip_step(clip: String, fallback_fps: float) -> float:
	var fps := fallback_fps
	if _xsxb_actor != null:
		var anims: Dictionary = _xsxb_actor.get("_animations")
		fps = float((anims.get(clip, {}) as Dictionary).get("fps", fallback_fps))
	return 1.0 / maxf(fps, 1.0)


func _clone_set_frame(clone: Node2D, texture: Texture2D, facing: int) -> void:
	clone.set_meta("facing", facing)
	var sprite := clone.get_child(0) as Sprite2D
	if sprite == null:
		return
	sprite.texture = texture
	sprite.flip_h = facing < 0
	var fade := clampf(float(clone.get_meta("life", CLONE_DURATION)) / 0.25, 0.0, 1.0)
	sprite.modulate = Color(0.94, 1.0, 0.90, 0.72 * fade)


func _clone_pick_target(clone: Node2D) -> FrontierEnemy:
	if clone.has_meta("target"):
		var current: Variant = clone.get_meta("target")
		if current is FrontierEnemy:
			var locked := current as FrontierEnemy
			if is_instance_valid(locked) and locked.is_active() and locked.hurt_gap(clone.global_position) <= CLONE_LOCK_RANGE:
				return locked
		clone.remove_meta("target")
	if _game == null or not _game.has_method("find_enemy_in_range"):
		return null
	return _game.call("find_enemy_in_range", clone.global_position, CLONE_LOCK_RANGE) as FrontierEnemy


func _clone_apply_hit(clone: Node2D) -> void:
	if _game == null or not _game.has_method("apply_clone_melee"):
		return
	var facing := int(clone.get_meta("facing", _facing))
	var origin := clone.global_position + Vector2(28.0 * float(facing), -18.0)
	_game.call("apply_clone_melee", origin, facing)


func _update_clones(delta: float) -> void:
	if _clone_nodes.is_empty():
		return
	var living: Array[Node2D] = []
	for clone: Node2D in _clone_nodes:
		if clone == null or not is_instance_valid(clone):
			continue
		var life := float(clone.get_meta("life", 0.0)) - delta
		clone.set_meta("life", life)
		if life <= 0.0:
			clone.queue_free()
			continue
		var delay := float(clone.get_meta("delay", 0.0))
		if delay > 0.0:
			clone.set_meta("delay", delay - delta)
			clone.visible = false
			living.append(clone)
			continue
		clone.visible = true
		var phase := StringName(clone.get_meta("phase", &"bubble"))
		if phase == &"bubble":
			if _update_clone_bubble(clone, delta):
				living.append(clone)
			continue
		_update_clone_combat(clone, delta)
		living.append(clone)
	_clone_nodes = living


func _update_clone_bubble(clone: Node2D, delta: float) -> bool:
	var bubble: Array = clone.get_meta("bubble", []) as Array
	if bubble.is_empty():
		clone.queue_free()
		return false
	var step := 1.0 / 12.0
	var accum := float(clone.get_meta("accum", 0.0)) + delta
	var index := int(clone.get_meta("index", 0))
	while accum >= step:
		accum -= step
		index += 1
	if index >= bubble.size():
		clone.set_meta("phase", &"idle")
		clone.set_meta("index", 0)
		clone.set_meta("accum", 0.0)
		clone.set_meta("hit_sent", false)
		var idle := _clone_clip_textures("idle")
		if not idle.is_empty():
			_clone_set_frame(clone, idle[0], int(clone.get_meta("facing", _facing)))
		return true
	clone.set_meta("accum", accum)
	clone.set_meta("index", index)
	_clone_set_frame(clone, bubble[index] as Texture2D, int(clone.get_meta("facing", _facing)))
	return true


func _update_clone_combat(clone: Node2D, delta: float) -> void:
	var target := _clone_pick_target(clone)
	if target != null:
		clone.set_meta("target", target)
	elif clone.has_meta("target"):
		clone.remove_meta("target")
	var phase := StringName(clone.get_meta("phase", &"idle"))
	if phase == &"attack":
		_update_clone_attack(clone, delta, target)
		return
	if target == null:
		_play_clone_loop(clone, delta, "idle", 8.0)
		return
	var facing := 1 if target.hurt_center().x >= clone.global_position.x else -1
	if target.hurt_gap(clone.global_position) <= CLONE_ATTACK_RANGE:
		clone.set_meta("phase", &"attack")
		clone.set_meta("index", 0)
		clone.set_meta("accum", 0.0)
		clone.set_meta("hit_sent", false)
		_update_clone_attack(clone, 0.0, target)
		return
	var toward := target.hurt_center() - clone.global_position
	if toward.length_squared() > 4.0:
		var next := clone.global_position + toward.normalized() * CLONE_MOVE_SPEED * delta
		if _game != null and _game.has_method("clamp_hero_position"):
			next = _game.call("clamp_hero_position", clone.global_position, next) as Vector2
		clone.global_position = next
	clone.set_meta("facing", facing)
	_play_clone_loop(clone, delta, "walk", 10.0)


func _play_clone_loop(clone: Node2D, delta: float, clip: String, fps: float) -> void:
	var frames := _clone_clip_textures(clip)
	if frames.is_empty():
		return
	var step := _clone_clip_step(clip, fps)
	var accum := float(clone.get_meta("accum", 0.0)) + delta
	var index := int(clone.get_meta("index", 0))
	while accum >= step:
		accum -= step
		index = (index + 1) % frames.size()
	clone.set_meta("accum", accum)
	clone.set_meta("index", index)
	_clone_set_frame(clone, frames[index], int(clone.get_meta("facing", _facing)))


func _update_clone_attack(clone: Node2D, delta: float, target: FrontierEnemy) -> void:
	var frames := _clone_clip_textures("attack")
	if frames.is_empty():
		clone.set_meta("phase", &"idle")
		return
	var facing := int(clone.get_meta("facing", _facing))
	if target != null and is_instance_valid(target):
		facing = 1 if target.hurt_center().x >= clone.global_position.x else -1
	var step := _clone_clip_step("attack", 12.0)
	var accum := float(clone.get_meta("accum", 0.0)) + delta
	var index := int(clone.get_meta("index", 0))
	while accum >= step:
		accum -= step
		index += 1
	if index >= frames.size():
		clone.set_meta("phase", &"idle")
		clone.set_meta("index", 0)
		clone.set_meta("accum", 0.0)
		clone.set_meta("hit_sent", false)
		return
	clone.set_meta("accum", accum)
	clone.set_meta("index", index)
	clone.set_meta("facing", facing)
	if index >= CLONE_HIT_FRAME and not bool(clone.get_meta("hit_sent", false)):
		clone.set_meta("hit_sent", true)
		_clone_apply_hit(clone)
	_clone_set_frame(clone, frames[mini(index, frames.size() - 1)], facing)


func _clear_clones() -> void:
	for clone: Node2D in _clone_nodes:
		if clone != null and is_instance_valid(clone):
			clone.queue_free()
	_clone_nodes.clear()
	_clone_spawned = false


func _actor_frame() -> int:
	if _xsxb_actor == null:
		return 0
	var playing := str(_xsxb_actor.get("_current_animation"))
	var want := _melee_clip_for_step(maxi(_combo_step, 1))
	if playing != want:
		return 0
	if _xsxb_actor.has_method("current_frame_index"):
		return int(_xsxb_actor.call("current_frame_index"))
	return int(_xsxb_actor.get("_current_frame"))


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

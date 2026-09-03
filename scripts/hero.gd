class_name EmberHero
extends Node2D

signal state_changed(next_state: StringName)
signal attacked(origin: Vector2, facing: int)
signal ranged_fired(origin: Vector2, aim_dir: Vector2, weapon_id: StringName)
signal health_changed(current: int, maximum: int)
signal armor_changed(current: int, maximum: int)
signal hero_kind_changed(kind: StringName)
signal downed
signal revived
signal dash_used
signal dash_hit(origin: Vector2, radius: float)

const HERO_FRAME_SIZE := Vector2(256.0, 256.0)
const MOVE_SPEED := 165.0
const MELEE_MOVE_MULT := 0.42
const MELEE_LUNGE_DIST := 40.0
const MELEE_LUNGE_TIME := 0.12
const SWAP_FADE := 0.10
const CAST_SLIDE_STOP := 0.20
const DASH_DISTANCE := 120.0
const DASH_TIME := 0.22
const JUMP_DURATION := 0.50
const JUMP_HEIGHT := 32.0
const ATTACK_DURATION := 0.50
const ATTACK_PLAYBACK_SPEED := 1.0
const COMBO_END_FRAMES: Array[int] = [6, 19]
const COMBO_HIT_FRAMES: Array[int] = [3, 14]
const COMBO_HOLD := 0.05
const COMBO_WINDOW := 0.20
const MIN_ATTACK_READ := 0.28
const INPUT_BUFFER := 0.12
const FOLLOWUP_START_FRAME := 7
const WORLD_BOUNDS := Rect2(-80.0, -680.0, 2560.0, 2300.0)
const WEAPON_SLOT_COUNT := 2
const CLONE_COUNT := 3
const FORGE_CAP := 5
const REVIVE_STOCK := 4
const SKILL_CAP_KNIGHT := 2
const SKILL_CAP_ASSASSIN := 3
const TURRET_HOLD_SCALE := 0.42
const CLONE_RADIUS := 140.0
const CLONE_DURATION := 5.0
const CLONE_MOVE_SPEED := 165.0
const CLONE_LOCK_RANGE := 320.0
const CLONE_ATTACK_RANGE := 118.0
const HERO_LOCK_RANGE := 250.0
const CLONE_HIT_FRAME := 4
const ASSASSIN_VISUAL_SCALE := 0.38
const ASSASSIN_MODULATE := Color(1.28, 1.20, 1.14, 1.0)
const KNIGHT_VISUAL_SIZE := 0.34
const DASH_DAMAGE := 36
const DASH_HIT_RADIUS := 72.0
const KNIGHT_SKILL_DASH_DAMAGE := 12
const KNIGHT_SKILL_RANGE := 14.0
const KNIGHT_SKILL_SIZE := 1.08
const FROST_FORM_DAMAGE := 1.20
const FROST_SKILL_DAMAGE := 0.10
const FROST_SKILL_SIZE := 1.06
const FROST_SKILL_RANGE := 10.0
const FROST_FORM_DURATION := 8.0
const CLONE_TINT := Color(0.62, 1.0, 0.72, 0.82)
const LEGACY_HOLD_HEIGHT := 74.0
const UNARMED_DAMAGE := 22
const _WeaponPose := preload("res://scripts/weapon_pose.gd")
const HeroStats := preload("res://scripts/hero_stats.gd")
const HeroPackCatalog := preload("res://scripts/hero_pack_catalog.gd")
const HeroPackSpec := preload("res://scripts/hero_pack_spec.gd")
const HeroDefinitionCatalog := preload("res://scripts/hero_definition_catalog.gd")

var current_state: StringName = &"idle"
var hero_kind: StringName = &"ember_hero"
var hero_id: StringName = &"ember_hero"
var visual_pack_id: StringName = &"ember_hero"
var _view: StringName = &"side"
var _view_mode: String = "side_flip"
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
var max_health := 120
var health := 120
var move_speed := MOVE_SPEED
var combat_stats: HeroStats = HeroStats.defaults()
var armor := 0
var armor_max := 0
var defense := 2
var _overdrive_left := 0.0
var _overdrive_ready := false
var down_duration := 4.0
var is_down := false
var revives_left := REVIVE_STOCK
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
var _buffered_attack := 0.0
var _buffered_jump := 0.0
var _queued_attack := false
var _queued_jump := false
var _queued_dash := false
var _pending_hero_kind: StringName = &""
var _pending_pack_id: StringName = &""
var _pending_skip_fade := false
var _transforming := false
var _reverting := false
var form_left := 0.0
var _dash_hit_sent := false
var _dash_dir := Vector2.RIGHT
var _slide_vel := Vector2.ZERO
var _lunge_left := 0.0
var _lunge_dir := Vector2.ZERO
var _swap_fade := 0.0
## Home hub only: match a stamped mascot height (牛来 = 128). 0 keeps combat scale.
var hub_visual_height := 0.0
var hub_hide_weapon := false

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
	_buffered_attack = maxf(_buffered_attack - delta, 0.0)
	_buffered_jump = maxf(_buffered_jump - delta, 0.0)
	if _attack_elapsed < 0.0:
		_combo_window = maxf(_combo_window - delta, 0.0)
	_demo_state_time = maxf(_demo_state_time - delta, 0.0)
	_hit_invuln = maxf(_hit_invuln - delta, 0.0)
	_dash_invuln = maxf(_dash_invuln - delta, 0.0)
	_overdrive_left = maxf(_overdrive_left - delta, 0.0)
	if _overdrive_left <= 0.0:
		_overdrive_ready = false
	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	_tick_frost_form(delta)
	_update_down(delta)
	_update_dash(delta)
	_handle_movement(delta)
	_tick_melee_lunge(delta)
	_tick_swap_fade(delta)
	_update_aim()
	_float_time += delta
	_update_held_weapon()
	_recoil_bloom = maxf(_recoil_bloom - delta * 18.0, 0.0)
	_update_jump(delta)
	_update_attack(delta)
	_flush_pending_hero_kind()
	_flush_action_queue()
	_update_clones(delta)
	_update_animation_state()
	queue_redraw()

func _handle_movement(delta: float) -> void:
	if is_down:
		_move_input = Vector2.ZERO
		return
	if _dash_elapsed >= 0.0:
		if hero_kind != &"assassin":
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
	var speed := move_speed
	if _attack_elapsed >= 0.0 and not WeaponCatalog.is_ranged(combat_weapon_id()):
		speed *= MELEE_MOVE_MULT
	position = _clamp_world(position + _move_input * speed * maxf(delta, 0.0))
	# Stick still walks this way. Facing during a swing comes from lock/aim so
	# a mid-attack turn does not restart the clip.
	if _attack_elapsed < 0.0 and absf(_move_input.x) > 0.01 and not WeaponCatalog.is_ranged(combat_weapon_id()):
		_apply_facing(1 if _move_input.x > 0.0 else -1)
	_apply_view_from_move(_move_input)

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
	var jump_duration := _animation_duration(_clip_name(&"jump"), JUMP_DURATION)
	var progress := clampf(_jump_elapsed / jump_duration, 0.0, 1.0)
	# Clip poses carry the jump; some skins also encode air in the sprite.
	# Code still lifts JUMP_HEIGHT so air walls and landing squat stay in sync.
	var air := clampf((progress - 0.12) / 0.72, 0.0, 1.0)
	_jump_offset = -sin(air * PI) * JUMP_HEIGHT
	_apply_jump_lift(_jump_offset)
	if progress >= 1.0:
		_jump_elapsed = -1.0
		_jump_offset = 0.0
		_apply_jump_lift(0.0)

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
	var pack: Dictionary = HeroPackCatalog.pack_by_id(visual_pack_id)
	if pack.is_empty():
		pack = HeroPackCatalog.pack_by_id(HeroPackCatalog.default_skin_id(hero_id))
	var assassin := hero_kind == &"assassin"
	_view_mode = String(pack.get("view_mode", "side_flip"))
	# Combat stays on the side clip. Front/back are home-walker only.
	if not hub_hide_weapon:
		_view = &"side"
	_xsxb_actor.set("frame_project_id", String(pack.get("frame_project_id", "emberline_enemies" if assassin else "emberline_frontier_07_final")))
	_xsxb_actor.set("frame_profile_id", String(pack.get("frame_profile_id", "ember_assassin" if assassin else "ember_hero")))
	_xsxb_actor.set("frame_animation", _clip_name(&"idle"))
	_xsxb_actor.set("use_frame_boxes", false)
	_xsxb_actor.set("fallback_visual_scale", combat_visual_scale())
	add_child(_xsxb_actor)
	_xsxb_actor.z_index = 1
	_xsxb_actor.modulate = _actor_base_modulate()
	_apply_hub_visual()
	if hub_hide_weapon:
		_clear_held_overlays()
	else:
		_ensure_float_sprites(maxi(_orbit_copy_count(), 1))
		_refresh_held_weapon()


func _actor_base_modulate() -> Color:
	return ASSASSIN_MODULATE if hero_kind == &"assassin" else Color.WHITE


func apply_hero_kind(kind: StringName, pack_id: StringName = &"") -> void:
	var identity := kind
	if not HeroDefinitionCatalog.has_id(identity):
		identity = &"ember_hero"
	var combat := HeroDefinitionCatalog.combat_base(identity)
	var skin := pack_id
	if hub_hide_weapon:
		skin = HeroPackCatalog.resolve_selectable_skin(identity, skin if skin != &"" else HeroPackCatalog.default_skin_id(identity))
	elif skin == &"" or not HeroPackCatalog.can_apply_pack(identity, skin):
		skin = HeroPackCatalog.default_skin_id(identity)
	if hero_id == identity and hero_kind == combat and visual_pack_id == skin and _xsxb_actor != null:
		_pending_hero_kind = &""
		_pending_pack_id = &""
		_pending_skip_fade = false
		return
	if is_down:
		return
	if _attack_elapsed >= 0.0 or _jump_elapsed >= 0.0 or _dash_elapsed >= 0.0:
		_pending_hero_kind = identity
		_pending_pack_id = skin
		_pending_skip_fade = false
		return
	_commit_hero_kind(identity, skin)


func _commit_hero_kind(identity: StringName, pack_id: StringName = &"", skip_fade: bool = false) -> void:
	if _attack_elapsed >= 0.0:
		_finish_combo()
	_combo_window = 0.0
	_clear_clones()
	_dash_elapsed = -1.0
	_transforming = false
	_reverting = false
	_dash_hit_sent = false
	hero_id = identity if HeroDefinitionCatalog.has_id(identity) else &"ember_hero"
	hero_kind = HeroDefinitionCatalog.combat_base(hero_id)
	visual_pack_id = pack_id if pack_id != &"" else HeroPackCatalog.default_skin_id(hero_id)
	if HeroPackCatalog.form_base_id(visual_pack_id) != &"":
		if form_left <= 0.0:
			form_left = FROST_FORM_DURATION
	else:
		form_left = 0.0
	if hero_kind == &"assassin":
		_combo_end = [7, 7]
		_combo_hit = [4, 4]
		_followup_start = 0
	else:
		_combo_end = COMBO_END_FRAMES.duplicate()
		_combo_hit = COMBO_HIT_FRAMES.duplicate()
		_followup_start = FOLLOWUP_START_FRAME
	var resume := &"idle"
	if is_down:
		resume = &"down"
	elif _jump_elapsed >= 0.0:
		resume = &"jump"
	elif not _move_input.is_zero_approx():
		resume = &"run"
	_build_xsxb_actor()
	_sync_melee_windows_from_clip()
	current_state = &""
	_set_state(resume)
	if skip_fade:
		_swap_fade = 0.0
		if _xsxb_actor != null:
			_xsxb_actor.modulate = _actor_base_modulate()
	else:
		_start_swap_fade()
	_refresh_held_weapon()
	hero_kind_changed.emit(hero_kind)


func _clip_name(state: StringName) -> String:
	var view := String(_view) if _view_mode == HeroPackSpec.VIEW_THREE else ""
	if state == &"dash":
		if _reverting:
			var bubble := _skill_bubble_clip()
			if _has_named_clip(bubble):
				return bubble
		# Assassin cast and frost transform use skill_cast. Armed frost dash is a real dash.
		if hero_kind == &"assassin" or _transforming or _is_awaiting_transform():
			var skill := _skill_cast_clip()
			if _has_named_clip(skill):
				return skill
	return HeroPackSpec.clip_name(String(state), String(hero_kind), _view_mode, view)


func _skill_cast_clip() -> String:
	var view := String(_view) if _view_mode == HeroPackSpec.VIEW_THREE else ""
	return HeroPackSpec.clip_name("skill_cast", String(hero_kind), _view_mode, view)


func _skill_bubble_clip() -> String:
	var view := String(_view) if _view_mode == HeroPackSpec.VIEW_THREE else ""
	return HeroPackSpec.clip_name("skill_bubble", String(hero_kind), _view_mode, view)


func _has_named_clip(clip: String) -> bool:
	if clip == "" or _xsxb_actor == null or not _xsxb_actor.has_method("animation_duration"):
		return false
	return float(_xsxb_actor.call("animation_duration", clip)) > 0.0


func _uses_skill_cast() -> bool:
	if hero_kind == &"assassin":
		return _has_named_clip(_skill_cast_clip())
	if _is_transform_form() and not _reverting:
		return false
	return _has_named_clip(_skill_cast_clip())


func _animation_duration(animation_name: StringName, fallback: float) -> float:
	if _xsxb_actor != null and _xsxb_actor.has_method("animation_duration"):
		var duration := float(_xsxb_actor.call("animation_duration", String(animation_name)))
		if duration > 0.0:
			return duration
	return fallback

## How far the feet have left the floor. Air walls shorter than this can be crossed.
func air_clearance() -> float:
	return maxf(0.0, -_jump_offset)


func request_jump() -> void:
	if is_down:
		return
	if _jump_elapsed >= 0.0:
		return
	if _attack_elapsed >= 0.0:
		_queued_jump = true
		return
	if _dash_elapsed >= 0.0:
		_queued_jump = true
		_buffered_jump = INPUT_BUFFER
		return
	_begin_jump()


func _begin_jump() -> void:
	_demo_state = &""
	_demo_state_time = 0.0
	_queued_jump = false
	_buffered_jump = 0.0
	_jump_elapsed = 0.0
	_set_state(&"jump")


func _cancel_jump() -> void:
	if _jump_elapsed < 0.0 and is_equal_approx(_jump_offset, 0.0):
		return
	_jump_elapsed = -1.0
	_jump_offset = 0.0
	_queued_jump = false
	_apply_jump_lift(0.0)


func request_attack() -> void:
	if hub_hide_weapon or is_down:
		return
	if _jump_elapsed >= 0.0:
		_queued_attack = true
		return
	if _dash_elapsed >= 0.0:
		_queued_attack = true
		_buffered_attack = INPUT_BUFFER
		return
	_demo_state = &""
	_demo_state_time = 0.0
	if WeaponCatalog.is_ranged(combat_weapon_id()):
		if _attack_cooldown > 0.0:
			_queued_attack = true
			_buffered_attack = INPUT_BUFFER
			return
		_fire_ranged()
		return
	if _combo_window > 0.0 and _attack_elapsed < 0.0:
		_apply_hero_lock()
		_start_followup_slash()
		_update_held_weapon()
		return
	if _attack_elapsed >= 0.0:
		_apply_hero_lock()
		if _combo_step < _combo_end.size():
			_combo_queued = true
		return
	if _attack_cooldown > 0.0:
		_queued_attack = true
		_buffered_attack = INPUT_BUFFER
		return
	_apply_hero_lock()
	_start_combo()
	_update_held_weapon()


func _flush_action_queue() -> void:
	if is_down or _dash_elapsed >= 0.0:
		return
	if hub_hide_weapon:
		_queued_attack = false
		_queued_dash = false
		_buffered_attack = 0.0
	if _queued_dash:
		if _jump_elapsed >= 0.0:
			return
		if _attack_elapsed >= 0.0 and not _can_cancel_attack_into_skill():
			return
		if _attack_elapsed >= 0.0:
			_finish_combo()
		_queued_dash = false
		if _is_transform_form() and form_left <= 0.0:
			_try_begin_revert()
		else:
			_begin_dash()
		return
	if _queued_jump and _jump_elapsed < 0.0 and _attack_elapsed < 0.0:
		_begin_jump()
		return
	if not _queued_attack or _jump_elapsed >= 0.0 or _attack_elapsed >= 0.0:
		return
	if _attack_cooldown > 0.0:
		if _buffered_attack <= 0.0:
			_queued_attack = false
		return
	_queued_attack = false
	_buffered_attack = 0.0
	request_attack()


func _flush_pending_hero_kind() -> void:
	if _pending_hero_kind == &"":
		return
	if is_down or _attack_elapsed >= 0.0 or _jump_elapsed >= 0.0 or _dash_elapsed >= 0.0:
		return
	var next := _pending_hero_kind
	var pack := _pending_pack_id
	var skip := _pending_skip_fade
	_pending_hero_kind = &""
	_pending_pack_id = &""
	_pending_skip_fade = false
	_commit_hero_kind(next, pack, skip)


## Drop buffered attack/jump/skill and a pending hero swap. Does not touch dash physics.
func _clear_action_queue() -> void:
	_queued_attack = false
	_queued_jump = false
	_queued_dash = false
	_buffered_attack = 0.0
	_buffered_jump = 0.0
	_pending_hero_kind = &""
	_pending_pack_id = &""
	_pending_skip_fade = false
	_lunge_left = 0.0

func _fire_ranged() -> void:
	if _attack_cooldown > 0.0:
		return
	var weapon_id := combat_weapon_id()
	if weapon_id == &"":
		return
	var weapon := WeaponCatalog.get_def(weapon_id)
	var cd_mult := combat_stats.ranged_cooldown_mult if combat_stats != null else 1.0
	_attack_cooldown = float(weapon["cooldown"]) * cd_mult
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
	if hub_hide_weapon or not has_dash or is_down or _dash_elapsed >= 0.0 or dash_cooldown_left > 0.0:
		return
	if _jump_elapsed >= 0.0:
		_queued_dash = true
		return
	if _attack_elapsed >= 0.0 and not _can_cancel_attack_into_skill():
		_queued_dash = true
		return
	if _attack_elapsed >= 0.0:
		_finish_combo()
	if _is_transform_form() and form_left <= 0.0:
		_try_begin_revert()
		return
	_begin_dash()


## Melee can cancel into skill only after the current slash has emitted its hit.
func _can_cancel_attack_into_skill() -> bool:
	if _attack_elapsed < 0.0:
		return true
	if WeaponCatalog.is_ranged(combat_weapon_id()):
		return true
	return _combo_step > 0 and _attack_hits_sent >= _combo_step


## Start the knight dash / assassin cast. Callers must already have cleared busy gates.
func _begin_dash() -> void:
	_queued_dash = false
	_lunge_left = 0.0
	_combo_window = 0.0
	_dash_dir = _dash_intent_dir()
	if absf(_dash_dir.x) > 0.01:
		_apply_facing(1 if _dash_dir.x >= 0.0 else -1)
	_dash_elapsed = 0.0
	_clone_spawned = false
	_dash_hit_sent = false
	_transforming = false
	_reverting = false
	if hero_kind == &"assassin":
		_slide_vel = _move_input * MOVE_SPEED
		_dash_invuln = _animation_duration(&"skill_cast", 0.80)
		_spawn_shadow_clones()
		_clone_spawned = true
	elif _is_awaiting_transform():
		_slide_vel = Vector2.ZERO
		_transforming = true
		_dash_invuln = _animation_duration(_clip_name(&"dash"), 0.80)
	else:
		_slide_vel = Vector2.ZERO
		var guard := combat_stats.dash_invuln_bonus if combat_stats != null else 0.0
		if _uses_skill_cast():
			_dash_invuln = _animation_duration(_clip_name(&"dash"), 0.80)
		else:
			_dash_invuln = 0.30 + guard
		if combat_stats != null and combat_stats.knight_overdrive_stacks > 0:
			_overdrive_left = 2.0
			_overdrive_ready = true
	dash_cooldown_left = dash_cooldown
	_set_state(&"dash")
	_refresh_held_weapon()
	var radius := dash_hit_radius()
	if _game != null and _game.has_method("clear_enemy_bullets_in_radius"):
		_game.call("clear_enemy_bullets_in_radius", global_position, radius)
	if not _transforming and hero_kind != &"assassin":
		_dash_hit_sent = true
		dash_hit.emit(global_position, radius)
	dash_used.emit()


## Move/stick first, then aim, then facing.
func _dash_intent_dir() -> Vector2:
	if not _move_input.is_zero_approx():
		return _move_input.normalized()
	var stick := Vector2.ZERO
	if _game != null and _game.has_method("get_move_stick"):
		stick = _game.call("get_move_stick") as Vector2
	if stick.length() >= 0.25:
		return stick.normalized()
	var aim := aim_direction()
	if aim.length_squared() >= 0.01:
		return aim.normalized()
	return Vector2(float(_facing), 0.0)


## Attack clips already lean. A 40px root-motion step walked the hero a tile per slash.
func _begin_melee_lunge() -> void:
	_lunge_left = 0.0
	_lunge_dir = Vector2.ZERO


func _tick_melee_lunge(delta: float) -> void:
	if _lunge_left <= 0.0 or _attack_elapsed < 0.0:
		_lunge_left = 0.0
		return
	var dt := minf(delta, _lunge_left)
	var step := MELEE_LUNGE_DIST / MELEE_LUNGE_TIME
	position = _clamp_world(position + _lunge_dir * step * dt)
	_lunge_left -= dt


## Brief fade-in after rebuilding the XSXB actor so a kind swap is not a hard cut.
func _start_swap_fade() -> void:
	_swap_fade = SWAP_FADE
	if _xsxb_actor != null:
		var m := _actor_base_modulate()
		m.a = 0.35
		_xsxb_actor.modulate = m


func _tick_swap_fade(delta: float) -> void:
	if _swap_fade <= 0.0:
		return
	_swap_fade = maxf(_swap_fade - delta, 0.0)
	if _xsxb_actor == null:
		return
	var t := 1.0 - _swap_fade / SWAP_FADE
	var m := _actor_base_modulate()
	m.a = lerpf(0.35, 1.0, t)
	_xsxb_actor.modulate = m


func _tick_cast_slide(delta: float) -> void:
	if _slide_vel.length_squared() < 0.25:
		_slide_vel = Vector2.ZERO
		return
	var decel := MOVE_SPEED / CAST_SLIDE_STOP
	_slide_vel = _slide_vel.move_toward(Vector2.ZERO, decel * delta)
	if _slide_vel.length_squared() < 0.25:
		_slide_vel = Vector2.ZERO
		_move_input = Vector2.ZERO
		return
	_move_input = _slide_vel.normalized()
	position = _clamp_world(position + _slide_vel * delta)

func is_casting_skill() -> bool:
	return _dash_elapsed >= 0.0

var debug_god := false

func take_damage(amount: int) -> void:
	if debug_god or is_down or _hit_invuln > 0.0 or _dash_invuln > 0.0:
		return
	var hit := resolve_hit(amount, armor, defense)
	armor = int(hit["armor"])
	if int(hit["armor_spent"]) > 0:
		armor_changed.emit(armor, armor_max)
		if combat_stats != null and combat_stats.knight_counterfire and _game != null and _game.has_method("clear_enemy_bullets_in_radius"):
			_game.call("clear_enemy_bullets_in_radius", global_position, 64.0)
	var hp_lost := int(hit["hp_lost"])
	if hp_lost <= 0:
		return
	health = maxi(health - hp_lost, 0)
	_hit_invuln = 0.40
	health_changed.emit(health, max_health)
	if health <= 0:
		_start_down()


## Armor then defense. Fully absorbed armor hits deal 0 HP; otherwise at least 1 if raw > 0.
static func resolve_hit(raw_damage: int, current_armor: int, current_defense: int) -> Dictionary:
	var raw := maxi(raw_damage, 0)
	var next_armor := current_armor
	var armor_spent := 0
	var remaining := raw
	if next_armor > 0 and raw > 0:
		next_armor -= 1
		armor_spent = 1
		remaining = maxi(raw - 8, 0)
		if remaining <= 0:
			return {"hp_lost": 0, "armor": next_armor, "armor_spent": armor_spent, "absorbed": true}
	var hp_lost := remaining - maxi(current_defense, 0)
	if raw > 0:
		hp_lost = maxi(hp_lost, 1)
	else:
		hp_lost = maxi(hp_lost, 0)
	return {"hp_lost": hp_lost, "armor": next_armor, "armor_spent": armor_spent, "absorbed": false}


## base × attack_power/100 × forge × all × channel × extra, rounded, at least 1.
static func scale_damage(
	base: int,
	attack_power: int,
	forge_mult: float,
	all_mult: float,
	channel_mult: float,
	extra_mult: float
) -> int:
	var raw := (
		float(maxi(base, 0))
		* float(attack_power)
		/ 100.0
		* forge_mult
		* all_mult
		* channel_mult
		* extra_mult
	)
	return maxi(1, int(round(raw)))


## Applies a HeroStats snapshot. refill fills HP/armor; otherwise add deltas.
func apply_combat_stats(stats: HeroStats, refill: bool = false, health_delta: int = 0, armor_delta: int = 0) -> void:
	combat_stats = stats
	max_health = stats.max_health
	armor_max = stats.armor_capacity
	defense = stats.defense
	move_speed = stats.move_speed
	var base_cd := DASH_COOLDOWNS[clampi(dash_cd_level, 0, DASH_COOLDOWNS.size() - 1)]
	dash_cooldown = base_cd * stats.dash_cooldown_mult
	if refill:
		health = max_health
		armor = armor_max
	else:
		if not is_down:
			health = clampi(health + health_delta, 0, max_health)
		armor = clampi(armor + armor_delta, 0, armor_max)
	melee_damage = melee_strike_damage()
	_refresh_combat_visual_scale()
	health_changed.emit(health, max_health)
	armor_changed.emit(armor, armor_max)


## Weapon/unarmed base before attack_power, forge, talents, amplifier.
## Ranged weapons use the sword's catalog damage so the scaled output cache never feeds the next pass.
func melee_base_damage() -> int:
	var weapon_id := combat_weapon_id()
	if weapon_id == &"":
		return maxi(1, UNARMED_DAMAGE + attack_bonus_level * 8)
	var weapon := WeaponCatalog.get_def(weapon_id)
	var base := int(weapon["damage"])
	if weapon["kind"] != &"melee":
		base = int(WeaponCatalog.get_def(&"sword")["damage"])
	return maxi(1, base + attack_bonus_level * 8)


## One combat damage pass. extra_mult is amplifier (or 1).
func scaled_damage(base: int, channel: StringName, extra_mult: float = 1.0, weapon_id: StringName = &"") -> int:
	var stats: HeroStats = combat_stats if combat_stats != null else HeroStats.defaults()
	var wid := weapon_id if weapon_id != &"" else combat_weapon_id()
	var channel_mult := 1.0
	if channel == &"melee" or channel == &"clone":
		channel_mult *= stats.melee_damage_mult
	if channel == &"clone":
		channel_mult *= stats.clone_damage_mult
	channel_mult *= form_damage_mult()
	var over := 1.0
	if _overdrive_ready and _overdrive_left > 0.0 and stats.knight_overdrive_stacks > 0:
		over = 1.0 + 0.25 * float(stats.knight_overdrive_stacks)
		_overdrive_ready = false
	return scale_damage(
		base,
		stats.attack_power,
		forge_damage_mult(wid),
		stats.all_damage_mult,
		channel_mult * over,
		extra_mult
	)


func heal_percent(ratio: float) -> void:
	if is_down:
		return
	health = mini(max_health, health + int(floor(float(max_health) * ratio)))
	health_changed.emit(health, max_health)


func heal_flat(amount: int) -> void:
	if is_down:
		return
	health = mini(max_health, health + maxi(amount, 0))
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
	return 1


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
	if hub_hide_weapon:
		return 0
	if turret_hand:
		return 1 if current_turret_kind() != &"" else 0
	return floating_weapon_count()


func _tower_hold_path(kind: StringName) -> String:
	return EmberTower.icon_path_for(kind)


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
	# Combat pads first (legacy preference), then SK facilities bought into the same stash.
	for kind: StringName in [&"pulse", &"frost", &"hologram", &"burst", &"barrier", &"amplifier", &"pulse_clear", &"energy_orb"]:
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
	return 1.0 + 0.12 * float(forge_level_for(weapon_id))


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
	_refresh_combat_visual_scale()
	return true


func _is_awaiting_transform() -> bool:
	var target := HeroPackCatalog.transform_into(visual_pack_id)
	return target != &"" and target != visual_pack_id


func _is_transform_form() -> bool:
	return HeroPackCatalog.form_base_id(visual_pack_id) != &""


func _tick_frost_form(delta: float) -> void:
	if hub_hide_weapon or is_down or not _is_transform_form() or _reverting:
		return
	form_left = maxf(form_left - delta, 0.0)
	if form_left > 0.0:
		return
	_try_begin_revert()


func _try_begin_revert() -> void:
	if hub_hide_weapon or is_down or _reverting or _transforming:
		return
	if not _is_transform_form():
		return
	if _dash_elapsed >= 0.0:
		return
	if _jump_elapsed >= 0.0:
		_cancel_jump()
	if _attack_elapsed >= 0.0:
		_finish_combo()
	_begin_revert()


func _begin_revert() -> void:
	_queued_dash = false
	_lunge_left = 0.0
	_combo_window = 0.0
	_reverting = true
	_transforming = false
	_dash_hit_sent = true
	_slide_vel = Vector2.ZERO
	var bubble := _skill_bubble_clip()
	if not _has_named_clip(bubble):
		_reverting = false
		var base := HeroPackCatalog.form_base_id(visual_pack_id)
		if base != &"":
			_commit_hero_kind(hero_id, base, true)
		return
	_dash_elapsed = 0.0
	_dash_invuln = _animation_duration(bubble, 0.80)
	_set_state(&"dash")
	_refresh_held_weapon()


func _skill_grows_body() -> bool:
	if hero_kind == &"assassin" or hub_hide_weapon:
		return false
	return not _is_awaiting_transform()


func skill_size_mult() -> float:
	if not _skill_grows_body():
		return 1.0
	var lv := skill_level_for(&"ember_hero")
	var step := FROST_SKILL_SIZE if _is_transform_form() else KNIGHT_SKILL_SIZE
	var mult := 1.0
	for _i: int in range(maxi(lv, 0)):
		mult *= step
	return mult


func skill_range_bonus() -> float:
	if hero_kind == &"assassin" or _is_awaiting_transform():
		return 0.0
	var lv := skill_level_for(&"ember_hero")
	if _is_transform_form():
		return FROST_SKILL_RANGE * float(lv)
	return KNIGHT_SKILL_RANGE * float(lv)


func form_damage_mult() -> float:
	if not _is_transform_form():
		return 1.0
	return FROST_FORM_DAMAGE + FROST_SKILL_DAMAGE * float(skill_level_for(&"ember_hero"))


func combat_visual_scale() -> float:
	if hero_kind == &"assassin":
		return ASSASSIN_VISUAL_SCALE
	return KNIGHT_VISUAL_SIZE * skill_size_mult()


func dash_hit_radius() -> float:
	return DASH_HIT_RADIUS + skill_range_bonus()


func melee_reach_bonus() -> float:
	return skill_range_bonus()


func dash_strike_damage(extra_mult: float = 1.0) -> int:
	var lv := skill_level_for(&"ember_hero") if hero_kind != &"assassin" else 0
	var base := DASH_DAMAGE
	if hero_kind != &"assassin" and not _is_transform_form():
		base += KNIGHT_SKILL_DASH_DAMAGE * lv
	var stats: HeroStats = combat_stats if combat_stats != null else HeroStats.defaults()
	return scale_damage(base, stats.attack_power, 1.0, stats.all_damage_mult, form_damage_mult(), extra_mult)


func _refresh_combat_visual_scale() -> void:
	if _xsxb_actor == null or hub_hide_weapon:
		return
	_xsxb_actor.set("fallback_visual_scale", combat_visual_scale())
	if _xsxb_actor.has_method("_apply_frame_visual"):
		_xsxb_actor.call("_apply_frame_visual")


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
	_combo_window = 0.0
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
	melee_damage = melee_strike_damage()
	_refresh_held_weapon()
	return true

func melee_strike_damage() -> int:
	return scaled_damage(melee_base_damage(), &"melee")

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
	var changed := _facing != face
	_facing = face
	if _xsxb_actor == null:
		return
	_xsxb_actor.set("facing", _visual_facing())
	if not changed:
		return
	# Flip in place. Never seek(0) or replay the live clip.
	if _xsxb_actor.has_method("_apply_frame_visual"):
		_xsxb_actor.call("_apply_frame_visual")


func _visual_facing() -> int:
	if _view_mode == HeroPackSpec.VIEW_THREE and _view != &"side":
		return 1
	return _facing


func _apply_view_from_move(motion: Vector2) -> void:
	if _view_mode != HeroPackSpec.VIEW_THREE:
		return
	# Battlefield never switches to front/back. HomeWalker sets hub_hide_weapon.
	if not hub_hide_weapon:
		if _view != &"side":
			_view = &"side"
			_replay_view_clip()
		return
	var next := HeroPackSpec.view_from_move(motion)
	if next == &"" or next == _view:
		return
	_view = next
	_replay_view_clip()


func _replay_view_clip() -> void:
	if current_state == &"" or _xsxb_actor == null:
		return
	var clip := _clip_name(current_state)
	_xsxb_actor.set("facing", _facing if _view == &"side" else 1)
	_xsxb_actor.call("play_frame_animation", clip, current_state in [&"idle", &"run"], true)

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
	return body_px * combat_visual_scale()


func _held_pose_scale() -> float:
	return maxf(1.0, _actor_on_screen_height() / LEGACY_HOLD_HEIGHT)


func _clear_held_overlays() -> void:
	for sprite: Sprite2D in _float_sprites:
		if not is_instance_valid(sprite):
			continue
		sprite.visible = false
		sprite.texture = null
		var parent := sprite.get_parent()
		if parent != null:
			parent.remove_child(sprite)
		sprite.queue_free()
	_float_sprites.clear()
	_held_sprite = null


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
	var visual := HERO_FRAME_SIZE.x * combat_visual_scale()
	var out := visual * 0.5 + 12.0
	var need := 0.0
	if _held_sprite != null and _held_sprite.texture != null:
		need = float(_held_sprite.texture.get_width()) * absf(_held_sprite.scale.x)
	# Pairwise gap must exceed sprite width * hold_scale for every facing.
	out = maxf(out, need * 0.56 + 10.0)
	var local := Vector2(face * out, hip_y)
	if count == 2:
		var dir := 1.0 if (index % 2) == 0 else -1.0
		local = Vector2(dir * out, hip_y)
	elif count >= 3:
		# Triangle around the torso. Do not put the third copy on a hip:
		# -face*(out+10) stacked with index 0 when facing left.
		var peak := maxf(out * 0.70, need * 0.78)
		match index % 3:
			0:
				local = Vector2(out, hip_y)
			1:
				local = Vector2(-out, hip_y)
			_:
				local = Vector2(0.0, hip_y - peak)
	return Vector2(local.x, local.y + bob + jump)


func _hub_scale() -> float:
	if hub_visual_height <= 0.0:
		return 1.0
	var body := 213.0 if hero_kind == &"assassin" else 239.0
	var base := body * (ASSASSIN_VISUAL_SCALE if hero_kind == &"assassin" else KNIGHT_VISUAL_SIZE)
	return hub_visual_height / maxf(base, 1.0)


func _apply_hub_visual() -> void:
	if _xsxb_actor == null:
		return
	var s := _hub_scale()
	_xsxb_actor.scale = Vector2(s, s)


func _apply_jump_lift(lift: float) -> void:
	if _xsxb_actor == null:
		return
	var sy := _xsxb_actor.scale.y
	_xsxb_actor.position.y = lift / sy if absf(sy) > 0.001 else lift


func _hides_held_overlay() -> bool:
	var pack: Dictionary = HeroPackCatalog.pack_by_id(visual_pack_id)
	if not bool(pack.get("hide_held_overlay", false)):
		return false
	# Baked melee art hides the sword overlay. Guns still need the float sprite.
	if WeaponCatalog.is_ranged(combat_weapon_id()):
		return false
	return true


func _refresh_held_weapon() -> void:
	if hub_hide_weapon or (_uses_skill_cast() and hero_kind != &"assassin" and _dash_elapsed >= 0.0):
		_clear_held_overlays()
		return
	if hero_kind != &"assassin" and _dash_elapsed >= 0.0:
		_clear_held_overlays()
		return
	if hero_kind != &"assassin" and _attack_elapsed >= 0.0 and not turret_hand and not WeaponCatalog.is_ranged(combat_weapon_id()):
		_clear_held_overlays()
		return
	if _hides_held_overlay() and not turret_hand:
		_clear_held_overlays()
		return
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
	if hub_hide_weapon or (_hides_held_overlay() and not turret_hand):
		if not _float_sprites.is_empty():
			_clear_held_overlays()
		return
	if hero_kind != &"assassin" and (_dash_elapsed >= 0.0 or (_attack_elapsed >= 0.0 and not turret_hand and not WeaponCatalog.is_ranged(combat_weapon_id()))):
		if not _float_sprites.is_empty():
			_clear_held_overlays()
		return
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
			# Same tap as the body: already in attack pose on frame 0, peak with the hit frame.
			var punch := 0.0
			if _attack_elapsed >= 0.0:
				var hit_f := float(_combo_hit[maxi(_combo_step - 1, 0)])
				punch = _WeaponPose.melee_punch(true, float(_actor_frame()) / maxf(hit_f, 1.0))
			_WeaponPose.apply_melee(sprite, _float_time, punch, _facing, index)
		else:
			_WeaponPose.apply_ranged(sprite, aim)

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
	_cancel_jump()
	_abort_form_swap_on_down()
	_clear_action_queue()
	_slide_vel = Vector2.ZERO
	_set_state(&"down")
	_refresh_held_weapon()
	downed.emit()


func _abort_form_swap_on_down() -> void:
	var was_transforming := _transforming
	var was_reverting := _reverting
	_transforming = false
	_reverting = false
	_dash_invuln = 0.0
	if was_transforming or not _is_transform_form():
		return
	if not was_reverting and form_left > 0.0:
		return
	var base := HeroPackCatalog.form_base_id(visual_pack_id)
	if base != &"" and base != visual_pack_id:
		_commit_hero_kind(hero_id, base, true)

func _update_down(delta: float) -> void:
	if not is_down:
		return
	_down_left -= delta
	if _down_left > 0.0:
		return
	if revives_left > 0:
		revives_left -= 1
		is_down = false
		health = 40
		position = revive_position
		_hit_invuln = 0.40
		health_changed.emit(health, max_health)
		_set_state(&"idle")
		_refresh_held_weapon()
		revived.emit()
		if _is_transform_form() and form_left <= 0.0:
			_try_begin_revert()
		return
	if _game != null and _game.has_method("notify_hero_defeated"):
		_game.call("notify_hero_defeated")

func _update_dash(delta: float) -> void:
	if _dash_elapsed < 0.0:
		return
	var prev := _dash_elapsed
	_dash_elapsed += delta
	if hero_kind == &"assassin":
		_tick_cast_slide(delta)
		var skill_time := _animation_duration(&"skill_cast", 0.80)
		if _dash_elapsed >= skill_time:
			_dash_elapsed = -1.0
			_slide_vel = Vector2.ZERO
		return
	if _transforming:
		var hold := _animation_duration(_clip_name(&"dash"), 0.80)
		if _dash_elapsed >= hold:
			_dash_elapsed = -1.0
			_transforming = false
			var target := HeroPackCatalog.transform_into(visual_pack_id)
			if target != &"":
				_commit_hero_kind(hero_id, target, true)
		return
	if _reverting:
		var hold := _animation_duration(_clip_name(&"dash"), 0.80)
		if _dash_elapsed >= hold:
			_dash_elapsed = -1.0
			_reverting = false
			var base := HeroPackCatalog.form_base_id(visual_pack_id)
			if base != &"":
				_commit_hero_kind(hero_id, base, true)
		return
	var remain := DASH_TIME - prev
	if remain > 0.0:
		var dir := _dash_dir if _dash_dir.length_squared() >= 0.01 else Vector2(float(_facing), 0.0)
		var dt := minf(delta, remain)
		var step := DASH_DISTANCE / DASH_TIME * dt
		position = _clamp_world(position + dir.normalized() * step)
	var hold := DASH_TIME
	if _uses_skill_cast():
		hold = maxf(DASH_TIME, _animation_duration(_clip_name(&"dash"), DASH_TIME))
	if _dash_elapsed >= hold:
		_dash_elapsed = -1.0
		_refresh_held_weapon()

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
	_xsxb_actor.set("facing", _facing if not (_view_mode == HeroPackSpec.VIEW_THREE and _view != &"side") else 1)
	if _attack_elapsed >= 0.0 and next_state != &"attack" and next_state != &"down" and next_state != &"dash":
		return
	var clip := _clip_name(next_state)
	var already := str(_xsxb_actor.get("_current_animation")) == clip
	if current_state == next_state and already:
		return
	current_state = next_state
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
	_begin_melee_lunge()


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
	_lunge_left = 0.0
	_combo_window = COMBO_WINDOW if can_chain else 0.0
	if _xsxb_actor != null:
		_xsxb_actor.set("playback_end_frame", -1)
		_xsxb_actor.set("playback_speed", 1.0)
	if _move_input.is_zero_approx():
		_set_state(&"idle")
	else:
		_set_state(&"run")
	_refresh_held_weapon()


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
	var clip := _melee_clip_for_step(maxi(_combo_step, 1))
	var start_frame := 0
	if hero_kind != &"assassin" and _combo_step >= 2:
		start_frame = _followup_start
	var natural := _natural_melee_span(clip, start_frame, end_frame)
	var speed := 1.0
	# Single-slash packs: keep every frame and time-compress into ATTACK_DURATION.
	# Two-hit strips (exactly 20 frames) keep authored combo windows and speed.
	var last := _melee_clip_frame_count(clip) - 1
	if last != COMBO_END_FRAMES[1] and natural > ATTACK_DURATION:
		speed = natural / ATTACK_DURATION
	_xsxb_actor.set("playback_speed", speed)
	if _xsxb_actor.has_method("limit_playback_to_frame"):
		_xsxb_actor.call("limit_playback_to_frame", end_frame)


func _melee_clip_frame_count(clip: String = "") -> int:
	if _xsxb_actor == null:
		return 0
	if clip == "":
		clip = _clip_name(&"attack")
	var anims: Variant = _xsxb_actor.get("_animations")
	if typeof(anims) != TYPE_DICTIONARY:
		return 0
	var frames: Array = ((anims as Dictionary).get(clip, {}) as Dictionary).get("frames", []) as Array
	return frames.size()


func _natural_melee_span(clip: String, start_frame: int, end_frame: int) -> float:
	if _xsxb_actor != null and _xsxb_actor.has_method("trail_frame_arrival_time"):
		var t0 := float(_xsxb_actor.call("trail_frame_arrival_time", clip, start_frame, 0.0))
		var t1 := float(_xsxb_actor.call("trail_frame_arrival_time", clip, end_frame, 1.0))
		return maxf(0.001, t1 - t0)
	return maxf(0.001, float(end_frame - start_frame + 1) / 12.0)


func _sync_melee_windows_from_clip() -> void:
	var n := _melee_clip_frame_count()
	if n <= 0:
		return
	var last := n - 1
	if hero_kind == &"assassin":
		var end := mini(7, last)
		var hit := mini(4, last)
		_combo_end = [end, end]
		_combo_hit = [hit, hit]
		_followup_start = 0
		return
	# Default knight attack is a 20-frame two-hit strip. Any other length is
	# one slash: play every frame, and a chained tap replays from 0.
	if n == COMBO_END_FRAMES[1] + 1:
		_combo_end = COMBO_END_FRAMES.duplicate()
		_combo_hit = COMBO_HIT_FRAMES.duplicate()
		_followup_start = FOLLOWUP_START_FRAME
		return
	_combo_end = [last, last]
	var hit := clampi(COMBO_HIT_FRAMES[0], 1, last)
	if last > COMBO_END_FRAMES[0]:
		hit = clampi(int(round(float(last) * 0.45)), 1, last)
	_combo_hit = [hit, hit]
	_followup_start = 0


func _melee_clip_for_step(step: int) -> String:
	if hero_kind == &"assassin" and step >= 2:
		return _clip_name(&"attack_b")
	return _clip_name(&"attack")


func _keep_melee_clip() -> void:
	if _xsxb_actor == null:
		return
	var want := _melee_clip_for_step(maxi(_combo_step, 1))
	var playing := str(_xsxb_actor.get("_current_animation"))
	if playing == want:
		return
	# Recover a stolen idle/run clip. Never seek(0) a live attack / attack_b.
	var restart := not playing.begins_with("attack")
	_xsxb_actor.call("play_frame_animation", want, false, restart)
	_apply_attack_playback(_combo_end[maxi(_combo_step - 1, 0)])


func _combo_segment_duration() -> float:
	var clip := _melee_clip_for_step(maxi(_combo_step, 1))
	var end_frame := _combo_end[maxi(_combo_step - 1, 0)]
	var start_frame := 0
	if hero_kind != &"assassin" and _combo_step >= 2:
		start_frame = _followup_start
	if _xsxb_actor != null and _xsxb_actor.has_method("trail_frame_arrival_time"):
		return maxf(MIN_ATTACK_READ, _natural_melee_span(clip, start_frame, end_frame))
	return maxf(MIN_ATTACK_READ, float(end_frame - start_frame + 1) / 12.0)


func _play_melee_clip(step: int) -> void:
	if _xsxb_actor == null:
		return
	_xsxb_actor.call("play_frame_animation", _melee_clip_for_step(step), false, true)


func _spawn_shadow_clones() -> void:
	_clear_clones()
	var bubble: Array[Texture2D] = _clone_clip_textures(_clip_name(&"skill_bubble"))
	if bubble.is_empty():
		bubble = _clone_clip_textures("skill_bubble")
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
		sprite.modulate = CLONE_TINT
		sprite.flip_h = _facing < 0
		sprite.texture = bubble[0]
		clone.add_child(sprite)
		var mark := Sprite2D.new()
		mark.name = "CloneMark"
		mark.z_index = 4
		mark.centered = true
		mark.position = Vector2(0.0, -36.0)
		mark.texture = _clone_mark_texture()
		mark.modulate = Color(0.55, 1.0, 0.62, 0.95)
		clone.add_child(mark)
		clone.set_meta("phase", &"bubble")
		clone.set_meta("life", CLONE_DURATION + (combat_stats.clone_duration_bonus if combat_stats != null else 0.0))
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


func _clone_mark_texture() -> Texture2D:
	var image := Image.create(18, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y: int in range(18):
		for x: int in range(18):
			var dx := float(x) - 8.5
			var dy := float(y) - 8.5
			var diamond := absf(dx) + absf(dy)
			if diamond <= 7.2 and diamond >= 4.4:
				image.set_pixel(x, y, Color(0.45, 1.0, 0.55, 1.0))
			elif diamond < 4.4:
				image.set_pixel(x, y, Color(0.12, 0.28, 0.14, 0.55))
	return ImageTexture.create_from_image(image)


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
	sprite.modulate = Color(CLONE_TINT.r, CLONE_TINT.g, CLONE_TINT.b, CLONE_TINT.a * fade)
	var mark := clone.get_node_or_null("CloneMark") as Sprite2D
	if mark != null:
		mark.modulate.a = 0.95 * fade


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
	var haste := combat_stats.clone_skill_cooldown_mult if combat_stats != null else 1.0
	var step := _clone_clip_step("attack", 12.0) * maxf(haste, 0.05)
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

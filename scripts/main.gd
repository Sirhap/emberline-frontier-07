extends Node2D

const VIEW_SIZE := Vector2(1280.0, 720.0)
const CAMERA_ROAD_ZOOM := 1.16
const CAMERA_SHOP_ZOOM := 1.22
const LANE_Y := 336.0
const SPAWN_X := 2440.0
const BASE_ENTRY_X := 232.0
const BASE_X := 90.0
const CORE_HIT_X := 154.0
const CORE_GLOW := Vector2(188.0, 263.0) # gem center on grid-battlefield-v6
const CORE_MAX := 10
const CONTACT_INTERVAL := 0.60
const CELL_SIZE := 48.0
const TILE_W := 1280.0 / 1536.0 * 64.0
const TILE_H := 720.0 / 1024.0 * 64.0
const GRID_OX := 0.0
const GRID_OY := -8.0
const LIVE_ENEMY_CAP := 40
const BULLET_CAP := 120
const TOWER_CAP := 8
const CORE_BUILD_CLEAR := 58.0
const CORE_PLATFORM := Rect2(80.0, 210.0, 226.0, 148.0)
const TOWER_PADS: Array[Vector2] = [
	Vector2(456.0, 216.0),
	Vector2(648.0, 216.0),
	Vector2(840.0, 216.0),
	Vector2(984.0, 216.0),
	Vector2(456.0, 456.0),
	Vector2(648.0, 456.0),
	Vector2(840.0, 456.0),
	Vector2(888.0, 360.0),
]
const SPAWN_Y_MIN := 180.0
const SPAWN_Y_MAX := 540.0
const FLOOR_BOUNDS := Rect2(-80.0, -680.0, 2560.0, 2300.0)
const SHOP_WING := Rect2(76.0, -400.0, 1010.0, 512.0)
const HOME_ROOM := SHOP_WING
const COMBAT_ROOM := Rect2(76.0, 72.0, 1684.0, 568.0)
const COMBAT_EXPAND_EAST := Rect2(18.0 * TILE_W, 16.0, 1760.0 - 18.0 * TILE_W, 624.0)
const COMBAT_EXPAND_SOUTH := Rect2(76.0, 540.0, 1684.0, 100.0)
const MOUTH_X0 := 24.0 * TILE_W
const EAST_HOLE_Y0 := 112.0
const EAST_HOLE_Y1 := 568.0
const ROAD_EAST := Rect2(1760.0, 16.0, 12.0 * TILE_W, 624.0)
const ROAD_NORTH := Rect2(MOUTH_X0, 16.0 - 14.0 * TILE_H, 1760.0 + 12.0 * TILE_W - MOUTH_X0, 14.0 * TILE_H + 56.0)
const ROAD_SOUTH := Rect2(MOUTH_X0, 640.0, 1760.0 + 12.0 * TILE_W - MOUTH_X0, 20.0 * TILE_H)
const SPAWN_NORTH := Vector2(MOUTH_X0 + (1760.0 - MOUTH_X0) * 0.5, 16.0 - 14.0 * TILE_H + 56.0)
const SPAWN_SOUTH := Vector2(MOUTH_X0 + (1760.0 + 12.0 * TILE_W - MOUTH_X0) * 0.5, 640.0 + 20.0 * TILE_H - 56.0)
const SPAWN_EAST := Vector2(1760.0 + 12.0 * TILE_W - 56.0, 16.0 + 312.0)
const HOME_HALL := Rect2(-80.0, 80.0, 156.0, 540.0)
const SHOP_ROOM := Rect2(108.0, -280.0, 904.0, 296.0)
const MERCHANT_ROOM := SHOP_ROOM
const TRAINER_ROOM := SHOP_ROOM
const SHOP_DOOR := Rect2(9.0 * TILE_W, 16.0, 3.0 * TILE_W, 56.0)
const MERCHANT_DOOR := SHOP_DOOR
const TRAINER_DOOR := SHOP_DOOR
const NORTH_WALL := Rect2(76.0, 16.0, 1010.0, 56.0)
const SHOP_TOP := Rect2(0.0, 0.0, 0.0, 0.0)
const SHOP_BOTTOM := Rect2(0.0, 0.0, 0.0, 0.0)
const GATE_X_MIN := 360.0
const GATE_X_MAX := 500.0
const HERO_BODY_RADIUS := 16.0
const NPC_BODY_RADIUS := 20.0
const TALK_RADIUS := 56.0
const LEAVE_RADIUS := 72.0
const HOME_REWARD_SPOTS: Array[Vector2] = [
	Vector2(236.0, 188.0),
	Vector2(252.0, 336.0),
	Vector2(236.0, 484.0),
]
const SHOP_SHELVES: Array[Vector2] = [
	Vector2(200.0, -70.0),
	Vector2(320.0, -70.0),
	Vector2(440.0, -70.0),
	Vector2(680.0, -70.0),
	Vector2(800.0, -70.0),
	Vector2(920.0, -70.0),
]
const SHELF_VENDORS: Array[StringName] = [
	&"merchant",
	&"merchant",
	&"merchant",
	&"trainer",
	&"trainer",
	&"trainer",
]
## Overlay / `_handle_dev_key` / AGENTS.md / CLAUDE.md 的唯一按键表。改键只改这里和对应 `fn`，再同步两份记忆里的同一张表。
const DEV_CHEATS: Array[Dictionary] = [
	{"key": KEY_1, "label": "1", "desc": "+500废料", "row": 0, "fn": "_dev_add_scrap"},
	{"key": KEY_2, "label": "2", "desc": "满血/满核", "row": 0, "fn": "_dev_full_heal"},
	{"key": KEY_3, "label": "3", "desc": "冲刺", "row": 0, "fn": "_dev_unlock_dash"},
	{"key": KEY_4, "label": "4", "desc": "开战/跳过准备", "row": 1, "fn": "_dev_start_wave"},
	{"key": KEY_5, "label": "5", "desc": "侦察", "row": 1, "fn": "_dev_spawn_scout"},
	{"key": KEY_6, "label": "6", "desc": "重装", "row": 1, "fn": "_dev_spawn_brute"},
	{"key": KEY_7, "label": "7", "desc": "Boss", "row": 1, "fn": "_dev_spawn_boss"},
	{"key": KEY_8, "label": "8", "desc": "清怪", "row": 2, "fn": "_dev_clear_enemies"},
	{"key": KEY_9, "label": "9", "desc": "核心-1", "row": 2, "fn": "_dev_hurt_core"},
	{"key": KEY_0, "label": "0", "desc": "无敌", "row": 2, "fn": "_dev_toggle_god"},
	{"key": KEY_G, "label": "G", "desc": "手枪", "row": 3, "fn": "_dev_equip_pistol"},
	{"key": KEY_B, "label": "B", "desc": "霰弹", "row": 3, "fn": "_dev_equip_shotgun"},
	{"key": KEY_P, "label": "P", "desc": "全垫脉冲", "row": 3, "fn": "_dev_fill_pads"},
	{"key": KEY_BRACKETLEFT, "label": "[", "desc": "上一把", "row": 4, "fn": "_dev_prev_weapon"},
	{"key": KEY_BRACKETRIGHT, "label": "]", "desc": "下一把", "row": 4, "fn": "_dev_next_weapon"},
]

var scrap := 300
var core_health := 10
var current_wave := 0
var defeated_count := 0
var run_time := 0.0
var simulation_speed := 1.0
var default_tower_kind: StringName = &"pulse"

var _wave_active := false
var _spawn_remaining := 0
var _spawned_in_wave := 0
var _spawn_timer := 0.0
var _wave_clear_timer := 0.0
var _boss_spawned := false
var _is_game_over := false
var _status_cooldown := 0.0
var _core_flash_time := 0.0
var _core_explode_left := 0.0
var _core_exploded := false
var _core_burst: Sprite2D
var _contact_timer := 0.0
var _enemies: Array[FrontierEnemy] = []
var _towers: Array[EmberTower] = []
var _pickups: Array[EmberPickup] = []
var _cell_towers: Dictionary = {}
var _selected_tower: EmberTower
var _live_bullets: Array = []
var _idle_pool: Array = []
var _bullet_pool_root: Node2D
var _restoring_run := false
var _hud: FrontierHud
var _background: Sprite2D
var _base_sprite: Sprite2D
var _npc_merchant: Sprite2D
var _npc_trainer: Sprite2D
var _shop_pen: Node2D
var _shelf_icons: Array[Sprite2D] = []
var _gate_open := 1.0
var _npc_anim := 0.0
var _hero_slot: Node2D
var _hero: EmberHero
var _camera: Camera2D
var _hero_state: StringName = &"idle"
var _director := WaveDirector.new()
var _shop := EmberShop.new()
var _drop_rng := RandomNumberGenerator.new()
var _near_npc: StringName = &""
var _talking_npc: StringName = &""
var _dev_mode := false
var _dev_god := false

func _ready() -> void:
	_drop_rng.randomize()
	_build_background()
	_build_base()
	_build_npcs()
	_build_hero_slot()
	_build_hud()
	_director.prep_started.connect(_on_prep_started)
	_director.combat_started.connect(_on_combat_started)
	_director.wave_cleared.connect(_on_director_wave_cleared)
	_shop.changed.connect(_refresh_shop_ui)
	_hud.sell_pressed.connect(sell_selected_tower)
	_build_bullet_pool()
	_boot_run()
	queue_redraw()

func _build_bullet_pool() -> void:
	_bullet_pool_root = Node2D.new()
	_bullet_pool_root.name = "BulletPool"
	_bullet_pool_root.visible = false
	add_child(_bullet_pool_root)

func _boot_run() -> void:
	var payload := EmberRunSave.load_run()
	if payload.is_empty():
		EmberRunSave.delete_run()
		_director.begin_run()
		return
	if not _apply_run_payload(payload):
		EmberRunSave.delete_run()
		_director.begin_run()

func _build_background() -> void:
	_background = Sprite2D.new()
	_background.name = "GridBattlefield"
	_background.texture = load("res://assets/generated/grid-battlefield-v6.png") as Texture2D
	if _background.texture == null:
		push_error("Grid battlefield failed to load")
		return
	_background.position = VIEW_SIZE * 0.5 + Vector2(0.0, -8.0)
	_background.scale = Vector2(VIEW_SIZE.x / _background.texture.get_width(), VIEW_SIZE.y / _background.texture.get_height())
	_background.flip_h = false
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_background.z_index = -10
	add_child(_background)

func _build_base() -> void:
	_base_sprite = Sprite2D.new()
	_base_sprite.name = "EmberCore"
	_base_sprite.texture = load("res://assets/generated/base/core.png") as Texture2D
	_base_sprite.position = Vector2(BASE_X, LANE_Y - 12.0)
	_base_sprite.scale = Vector2(0.42, 0.42)
	_base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_base_sprite.z_index = 1
	_base_sprite.visible = false
	add_child(_base_sprite)
	_core_burst = Sprite2D.new()
	_core_burst.name = "CoreBurst"
	_core_burst.texture = load("res://assets/generated/fx/core-explode.png") as Texture2D
	_core_burst.position = CORE_GLOW
	_core_burst.scale = Vector2(0.38, 0.38)
	_core_burst.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_core_burst.z_index = 7
	_core_burst.visible = false
	add_child(_core_burst)

func _build_npcs() -> void:
	_shop_pen = (load("res://scripts/shop_pen.gd") as GDScript).new()
	_shop_pen.name = "ShopPen"
	_shop_pen.z_index = 1
	add_child(_shop_pen)
	_shop_pen.merchant_room = MERCHANT_ROOM
	_shop_pen.trainer_room = TRAINER_ROOM
	_shop_pen.merchant_door = MERCHANT_DOOR
	_shop_pen.trainer_door = TRAINER_DOOR
	_shop_pen.north_wall = NORTH_WALL
	_shop_pen.expand_floors.clear()
	_shop_pen.expand_floors.append(COMBAT_EXPAND_EAST)
	_shop_pen.expand_floors.append(COMBAT_EXPAND_SOUTH)
	_shop_pen.expand_floors.append(ROAD_EAST)
	_shop_pen.expand_floors.append(ROAD_NORTH)
	_shop_pen.expand_floors.append(ROAD_SOUTH)
	var wall_v: float = float(_shop_pen.get("_wall_v"))
	var wall_h: float = float(_shop_pen.get("_wall_h"))
	var se_x0 := MOUTH_X0
	_shop_pen.expand_h_walls = [
		Rect2(18.0 * TILE_W, NORTH_WALL.position.y, se_x0 - 18.0 * TILE_W, wall_h),
		Rect2(COMBAT_ROOM.position.x - wall_v, COMBAT_ROOM.end.y, se_x0 - (COMBAT_ROOM.position.x - wall_v), wall_h),
	]
	_shop_pen.expand_v_walls = [
		Rect2(se_x0 - wall_v, COMBAT_ROOM.end.y, wall_v, ROAD_SOUTH.size.y),
		Rect2(se_x0 - wall_v, ROAD_NORTH.position.y, wall_v, ROAD_NORTH.size.y),
	]
	_shop_pen.extra_doors = []
	_shop_pen.spawn_hole = Rect2()
	_shop_pen.mouth_jambs = [
		Rect2(se_x0 - 12.0, COMBAT_ROOM.end.y, 12.0, wall_h),
		Rect2(se_x0 - 12.0, NORTH_WALL.position.y, 12.0, wall_h),
	]
	_build_spawn_portals()
	_npc_merchant = _make_npc("NpcMerchant", "res://assets/generated/npc/merchant.png", Vector2(320.0, -150.0))
	_npc_trainer = _make_npc("NpcTrainer", "res://assets/generated/npc/trainer.png", Vector2(800.0, -150.0))
	_build_shop_shelves()

func _build_spawn_portals() -> void:
	_make_spawn_portal("SpawnPortalNorth", SPAWN_NORTH, 0.50)
	_make_spawn_portal("SpawnPortalSouth", SPAWN_SOUTH, 0.50)
	_make_spawn_portal("SpawnPortalEast", SPAWN_EAST, 0.50)
	_sync_spawn_portals()

func _make_spawn_portal(node_name: String, at: Vector2, visual_scale: float) -> void:
	var portal: Node2D = (load("res://scripts/spawn_portal.gd") as GDScript).new()
	portal.name = node_name
	portal.position = at
	portal.scale = Vector2(visual_scale, visual_scale)
	portal.z_index = 2
	add_child(portal)

func _spawn_holes_for_wave(wave: int) -> Array[Vector2]:
	var holes: Array[Vector2] = []
	match wave:
		1:
			holes.append(SPAWN_EAST)
		2:
			holes.append(SPAWN_NORTH)
		3:
			holes.append(SPAWN_SOUTH)
		4:
			holes.append(SPAWN_EAST)
			holes.append(SPAWN_NORTH)
		5:
			holes.append(SPAWN_EAST)
			holes.append(SPAWN_SOUTH)
		6:
			holes.append(SPAWN_NORTH)
			holes.append(SPAWN_SOUTH)
		_:
			holes.append(SPAWN_EAST)
			holes.append(SPAWN_NORTH)
			holes.append(SPAWN_SOUTH)
	return holes

func _spawn_hole_label(hole: Vector2) -> String:
	if hole == SPAWN_NORTH:
		return "北"
	if hole == SPAWN_SOUTH:
		return "南"
	return "东"

func _spawn_hole_status(wave: int) -> String:
	var labels: PackedStringArray = []
	for hole: Vector2 in _spawn_holes_for_wave(wave):
		labels.append(_spawn_hole_label(hole))
	return "·".join(labels)

func _sync_spawn_portals() -> void:
	var wave := 1
	if _director != null:
		wave = current_wave if _director.is_combat() else _director.upcoming_wave()
	var holes := _spawn_holes_for_wave(wave)
	_set_portal_lit("SpawnPortalEast", holes.has(SPAWN_EAST))
	_set_portal_lit("SpawnPortalNorth", holes.has(SPAWN_NORTH))
	_set_portal_lit("SpawnPortalSouth", holes.has(SPAWN_SOUTH))

func _set_portal_lit(node_name: String, lit: bool) -> void:
	var portal := find_child(node_name, true, false)
	if portal != null and portal.has_method("set_hole_active"):
		portal.call("set_hole_active", lit)

func _build_shop_shelves() -> void:
	if _shop_pen != null and _shop_pen.get("shelf_spots") != null:
		_shop_pen.shelf_spots = SHOP_SHELVES.duplicate()
	var root := Node2D.new()
	root.name = "ShopShelves"
	root.z_index = 3
	add_child(root)
	_shelf_icons.clear()
	for index: int in range(SHOP_SHELVES.size()):
		var icon := Sprite2D.new()
		icon.name = "ShopShelf%d" % index
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.centered = true
		icon.position = SHOP_SHELVES[index] + Vector2(0.0, -6.0)
		icon.visible = false
		root.add_child(icon)
		_shelf_icons.append(icon)

func _make_npc(npc_name: String, texture_path: String, world_position: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = npc_name
	sprite.texture = load(texture_path) as Texture2D
	sprite.position = world_position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 2
	if sprite.texture != null:
		var height := float(sprite.texture.get_height())
		var fit := 92.0 / height if height > 1.0 else 1.0
		sprite.scale = Vector2(fit, fit)
	sprite.set_meta("rest_pos", world_position)
	sprite.set_meta("rest_scale", sprite.scale)
	add_child(sprite)
	return sprite

func _build_hero_slot() -> void:
	_hero_slot = Node2D.new()
	_hero_slot.name = "HeroSlot"
	_hero_slot.z_index = 4
	_hero = EmberHero.new()
	_hero.name = "HeroController"
	_hero.configure(self, Vector2(640.0, LANE_Y))
	_hero.revive_position = Vector2(CORE_HIT_X + 80.0, LANE_Y)
	_hero.attacked.connect(_on_hero_attacked)
	_hero.ranged_fired.connect(_on_hero_ranged_fired)
	_hero.state_changed.connect(_on_hero_state_changed)
	_hero.health_changed.connect(_on_hero_health_changed)
	_hero.downed.connect(_on_hero_downed)
	_hero.revived.connect(_on_hero_revived)
	_hero_slot.add_child(_hero)
	add_child(_hero_slot)
	_build_camera()

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "FollowCam"
	_camera.enabled = true
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 7.0
	_camera.limit_left = int(FLOOR_BOUNDS.position.x) - 40
	_camera.limit_top = int(FLOOR_BOUNDS.position.y) - 40
	_camera.limit_right = int(FLOOR_BOUNDS.end.x)
	_camera.limit_bottom = int(FLOOR_BOUNDS.end.y)
	add_child(_camera)
	_camera.make_current()
	if _hero != null:
		_camera.global_position = camera_target_for(_hero.global_position)
		_camera.zoom = camera_zoom_for(_hero.global_position)

## Returns the framed camera center for narrow roads and the north shop room.
func camera_target_for(world_position: Vector2) -> Vector2:
	var focus := _camera_focus_rect(world_position)
	if focus.size.x <= 1.0 or focus.size.y <= 1.0:
		return world_position
	var zoom := camera_zoom_for(world_position).x
	var half_view := VIEW_SIZE / (zoom * 2.0)
	return Vector2(
		_clamp_camera_axis(world_position.x, focus.position.x, focus.end.x, half_view.x),
		_clamp_camera_axis(world_position.y, focus.position.y, focus.end.y, half_view.y)
	)

## Returns a light contextual zoom that keeps narrow dungeon spaces inside the viewport.
func camera_zoom_for(world_position: Vector2) -> Vector2:
	if _is_shop_interior(world_position) or SHOP_DOOR.has_point(world_position):
		return Vector2(CAMERA_SHOP_ZOOM, CAMERA_SHOP_ZOOM)
	if ROAD_NORTH.has_point(world_position) or ROAD_SOUTH.has_point(world_position) or ROAD_EAST.has_point(world_position):
		return Vector2(CAMERA_ROAD_ZOOM, CAMERA_ROAD_ZOOM)
	return Vector2.ONE

func _camera_focus_rect(world_position: Vector2) -> Rect2:
	if _is_shop_interior(world_position) or SHOP_DOOR.has_point(world_position):
		return Rect2(76.0, -336.0, 1010.0, 568.0)
	if ROAD_NORTH.has_point(world_position):
		return ROAD_NORTH
	if ROAD_SOUTH.has_point(world_position):
		return ROAD_SOUTH
	if ROAD_EAST.has_point(world_position):
		return ROAD_EAST
	return Rect2()

func _clamp_camera_axis(value: float, minimum: float, maximum: float, half_view: float) -> float:
	if maximum - minimum <= half_view * 2.0:
		return (minimum + maximum) * 0.5
	return clampf(value, minimum + half_view, maximum - half_view)

func _build_hud() -> void:
	_hud = FrontierHud.new()
	add_child(_hud)
	_hud.start_wave_pressed.connect(start_wave)
	_hud.restart_pressed.connect(restart_run)
	_hud.speed_pressed.connect(toggle_speed)
	_hud.hero_pressed.connect(_cycle_hero_state)
	_hud.jump_pressed.connect(_play_jump)
	_hud.attack_pressed.connect(_play_attack)
	_hud.upgrade_pressed.connect(upgrade_selected_tower)
	_hud.skill_pressed.connect(_play_dash)
	_hud.shop_slot_pressed.connect(buy_shop_slot)
	_hud.default_tower_pressed.connect(_cycle_default_tower)
	_hud.weapon_switch_pressed.connect(_cycle_hero_weapon)
	_hud.talk_pressed.connect(try_talk_to_nearby_npc)
	_sync_weapon_hud()
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.clear_tower_info()
	_hud.set_hero_state("待命")
	_hud.set_hero_hp(100, 100)
	_hud.set_default_tower(default_tower_kind)
	_hud.set_skill(false, 0.0)

func _process(delta: float) -> void:
	_status_cooldown = maxf(_status_cooldown - delta, 0.0)
	_core_flash_time = maxf(_core_flash_time - delta, 0.0)
	if _base_sprite != null:
		_base_sprite.modulate = Color(1.0, 0.56, 0.42) if _core_flash_time > 0.0 else Color.WHITE
	if _core_exploded:
		_tick_core_explode(delta)
		queue_redraw()
		return
	if _is_game_over:
		queue_redraw()
		return
	run_time += delta
	if _director.is_prep():
		_director.tick(delta)
		_hud.set_wave_button_enabled(true, "提前开战")
		_hud.set_shop_countdown(_director.prep_left)
		_update_npc_talk()
	else:
		var scaled_delta := delta * simulation_speed
		if _wave_active:
			_process_spawning(scaled_delta)
			if _spawn_remaining == 0 and (not _needs_boss() or _boss_spawned) and _enemies.is_empty():
				_wave_clear_timer += scaled_delta
				if _wave_clear_timer >= 1.0:
					_finish_wave()
	_process_hero_contact(delta)
	_process_pickups()
	if _hero != null:
		if _camera != null:
			_camera.global_position = camera_target_for(_hero.global_position)
			var target_zoom := camera_zoom_for(_hero.global_position)
			_camera.zoom = _camera.zoom.lerp(target_zoom, minf(delta * 6.0, 1.0))
		_hud.set_skill(_hero.has_dash, _hero.dash_cooldown_left, _hero.dash_cooldown)
		var enemy_dots: Array[Vector2] = []
		for enemy: FrontierEnemy in _enemies:
			if enemy != null and is_instance_valid(enemy):
				enemy_dots.append(enemy.position)
		var tower_dots: Array[Vector2] = []
		for tower: EmberTower in _towers:
			if tower != null and is_instance_valid(tower):
				tower_dots.append(tower.position)
		_hud.update_minimap(
			_hero.position,
			CORE_GLOW,
			tower_dots,
			MERCHANT_ROOM,
			MERCHANT_DOOR,
			COMBAT_ROOM,
			HOME_HALL,
			enemy_dots,
			is_shop_gate_open()
		)
		_hud.layout_for_home(_in_home_area(_hero.position))
		if _dev_god:
			_hero.debug_god = true
			_hero.set("_hit_invuln", 1.0)
	if _dev_mode:
		_hud.set_dev_overlay(true, _dev_overlay_text())
	var gate_target := 1.0 if is_shop_gate_open() else 0.0
	_gate_open = move_toward(_gate_open, gate_target, delta * 3.2)
	if _shop_pen != null:
		_shop_pen.gate_open = _gate_open
	if not is_shop_gate_open():
		_eject_hero_from_shop()
	_npc_anim += delta
	_animate_npc(_npc_merchant, _npc_anim, 0.0)
	_animate_npc(_npc_trainer, _npc_anim, 1.8)
	queue_redraw()

func _process_spawning(delta: float) -> void:
	if _spawn_remaining > 0:
		_spawn_timer -= delta
		if _spawn_timer > 0.0:
			return
		if get_active_enemies().size() >= LIVE_ENEMY_CAP:
			return
		_spawn_enemy()
		_spawn_remaining -= 1
		_spawned_in_wave += 1
		_spawn_timer = maxf(0.40, 0.90 - float(current_wave) * 0.04)
		return
	if _needs_boss() and not _boss_spawned:
		if get_active_enemies().size() >= LIVE_ENEMY_CAP:
			return
		_spawn_boss()
		_boss_spawned = true

func _needs_boss() -> bool:
	return current_wave > 0 and current_wave % 5 == 0

func _spawn_enemy() -> void:
	var enemy := FrontierEnemy.new()
	var kind := _pick_spawn_variant()
	enemy.variant = kind
	match kind:
		&"brute":
			enemy.max_health = 112 + current_wave * 22
			enemy.move_speed = 31.0 + float(current_wave) * 2.0
			enemy.reward = 35 + current_wave * 5
			enemy.contact_damage = 16
			enemy.core_damage = 1
		&"mage":
			enemy.max_health = 68 + current_wave * 14
			enemy.move_speed = 36.0 + float(current_wave) * 2.0
			enemy.reward = 28 + current_wave * 4
			enemy.contact_damage = 10
			enemy.core_damage = 2
		&"runner":
			enemy.max_health = 34 + current_wave * 8
			enemy.move_speed = 86.0 + float(current_wave) * 5.0
			enemy.reward = 12 + current_wave * 2
			enemy.contact_damage = 6
			enemy.core_damage = 1
		_:
			enemy.max_health = 52 + current_wave * 12
			enemy.move_speed = 57.0 + float(current_wave) * 4.0
			enemy.reward = 16 + current_wave * 3
			enemy.contact_damage = 8
			enemy.core_damage = 1
	enemy.configure_seek(_random_spawn_point(), core_goal(), self)
	_register_enemy(enemy)

func _pick_spawn_variant() -> StringName:
	var slot := _spawned_in_wave
	if current_wave <= 1:
		return &"runner" if slot % 3 == 1 else &"scout"
	if slot % 5 == 4 and current_wave >= 3:
		return &"mage"
	if current_wave >= 2 and slot % 4 == 3:
		return &"brute"
	if slot % 3 == 1:
		return &"runner"
	return &"scout"

func _spawn_boss() -> void:
	var enemy := FrontierEnemy.new()
	enemy.variant = &"boss"
	enemy.max_health = 420 + current_wave * 55
	enemy.move_speed = 24.0 + float(current_wave) * 1.2
	enemy.reward = 120 + current_wave * 15
	enemy.contact_damage = 28
	enemy.core_damage = 2
	enemy.configure_seek(_random_spawn_point(), core_goal(), self)
	_register_enemy(enemy)
	_hud.update_status("前线主宰出现  /  优先集火")

func _register_enemy(enemy: FrontierEnemy) -> void:
	enemy.reached_base.connect(_on_enemy_reached_base)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.hit.connect(_on_enemy_hit)
	enemy.z_index = 3
	_enemies.append(enemy)
	add_child(enemy)

func start_wave() -> void:
	if _is_game_over or _director.is_combat():
		return
	_director.start_wave()

func _on_prep_started(upcoming_wave: int) -> void:
	_wave_active = false
	_close_talk()
	if not _restoring_run:
		scrap += _refresh_shop_stock(upcoming_wave)
	_hud.set_wave_button_enabled(true, "提前开战")
	_hud.set_shop_countdown(_director.prep_duration)
	_sync_spawn_portals()
	_hud.update_status("家厅已开放  /  下波 %s洞出怪  /  向上按 E" % _spawn_hole_status(upcoming_wave))
	_hud.update_stats(scrap, core_health, current_wave)
	_refresh_shop_ui()

func _on_combat_started(wave: int) -> void:
	scrap += _shop.close_and_refund()
	_close_talk()
	_hud.set_npc_prompt(false, Vector2.ZERO)
	_hud.set_shop_countdown(0.0)
	current_wave = wave
	_wave_active = true
	_wave_clear_timer = 0.0
	_spawn_remaining = 4 + current_wave * 2
	_spawned_in_wave = 0
	_spawn_timer = 0.1
	_boss_spawned = false
	_hud.set_wave_button_enabled(false, "第 %02d 波进行中" % current_wave)
	_eject_hero_from_shop()
	_sync_spawn_portals()
	_hud.update_status("作战开始  /  第 %02d 波  /  %s洞" % [current_wave, _spawn_hole_status(current_wave)])
	_hud.update_stats(scrap, core_health, current_wave)

func _on_director_wave_cleared(_wave: int) -> void:
	pass

func _finish_wave() -> void:
	_wave_active = false
	_wave_clear_timer = 0.0
	scrap += 50
	_director.notify_combat_cleared()
	_spawn_home_rewards()
	_write_run_save()
	_hud.update_status("第 %02d 波清除  /  +50，家门有奖励" % current_wave)
	_hud.update_stats(scrap, core_health, current_wave)

func _spawn_home_rewards() -> void:
	_clear_home_consumable_rewards()
	var rolls: Array[Dictionary] = [
		{"kind": &"scrap", "amount": 10},
		{"kind": &"scrap", "amount": 10},
		_roll_home_special_reward(),
	]
	for index: int in range(HOME_REWARD_SPOTS.size()):
		var spec: Dictionary = rolls[index]
		var spot: Vector2 = HOME_REWARD_SPOTS[index]
		match StringName(spec["kind"]):
			&"heal":
				_spawn_world_pickup(&"heal", &"heal", "res://assets/generated/weapons/red-potion.png", 0.34, spot, 0, 24.0)
			&"weapon":
				var weapon_id: StringName = spec["payload"]
				var weapon := WeaponCatalog.get_def(weapon_id)
				_spawn_world_pickup(
					&"weapon",
					weapon_id,
					String(weapon["pickup_path"]),
					float(weapon.get("pickup_scale", 0.36)),
					spot,
					0,
					24.0
				)
			_:
				_spawn_world_pickup(
					&"scrap",
					&"scrap",
					"res://assets/generated/ui/scrap.png",
					0.18,
					spot,
					int(spec.get("amount", 10)),
					24.0
				)

func _roll_home_special_reward() -> Dictionary:
	var roll := _drop_rng.randf()
	var hurt := _hero != null and not _hero.is_down and _hero.health < _hero.max_health
	if hurt and roll < 0.40:
		return {"kind": &"heal"}
	if roll < 0.28:
		return {"kind": &"weapon", "payload": WeaponCatalog.random_basic_weapon(_drop_rng)}
	return {"kind": &"scrap", "amount": 10}

func _clear_home_consumable_rewards() -> void:
	var kept: Array[EmberPickup] = []
	for pickup: EmberPickup in _pickups:
		if not is_instance_valid(pickup):
			continue
		var is_home := pickup.global_position.x < 360.0
		var consumable := pickup.pickup_kind == &"scrap" or pickup.pickup_kind == &"heal"
		if is_home and consumable:
			pickup.queue_free()
			continue
		kept.append(pickup)
	_pickups = kept

func _spawn_world_pickup(
	kind: StringName,
	payload: StringName,
	texture_path: String,
	sprite_scale: float,
	at: Vector2,
	scrap_value: int = 0,
	lifetime: float = EmberPickup.LIFETIME
) -> void:
	var pickup := EmberPickup.new()
	pickup.configure(kind, payload, texture_path, sprite_scale, scrap_value, lifetime)
	pickup.z_index = 5
	pickup.collected.connect(_on_pickup_collected)
	_pickups.append(pickup)
	add_child(pickup)
	pickup.global_position = at

func _on_enemy_reached_base(enemy: FrontierEnemy) -> void:
	_enemies.erase(enemy)
	core_health = maxi(core_health - enemy.core_damage, 0)
	_core_flash_time = 0.32
	spawn_hit_effect(CORE_GLOW, 0.28, 0.34)
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("核心受击  /  剩余完整度 %02d" % core_health)
	if core_health <= 0:
		_explode_core()

func _on_enemy_defeated(enemy: FrontierEnemy, reward: int) -> void:
	_enemies.erase(enemy)
	defeated_count += 1
	scrap += reward
	spawn_hit_effect(enemy.global_position, 0.22, 0.26)
	_maybe_drop_loot(enemy)
	_hud.update_stats(scrap, core_health, current_wave)

func _maybe_drop_loot(enemy: FrontierEnemy) -> void:
	var payload: StringName = &""
	var kind: StringName = &"weapon"
	if enemy.variant == &"boss":
		if _hero != null and not _hero.has_dash:
			kind = &"skill"
			payload = &"dash"
		else:
			payload = WeaponCatalog.random_boss_weapon(_drop_rng)
	elif enemy.variant == &"brute" or enemy.variant == &"mage":
		payload = WeaponCatalog.random_basic_weapon(_drop_rng)
	elif _drop_rng.randf() <= 0.08:
		payload = WeaponCatalog.random_basic_weapon(_drop_rng)
	if payload == &"":
		return
	var texture_path := "res://assets/generated/pickups/dash.png"
	var sprite_scale := 0.36
	if kind == &"weapon":
		var weapon := WeaponCatalog.get_def(payload)
		texture_path = String(weapon["pickup_path"])
		sprite_scale = float(weapon.get("pickup_scale", 0.36))
	_spawn_world_pickup(kind, payload, texture_path, sprite_scale, enemy.global_position)

func _process_pickups() -> void:
	if _hero == null or _hero.is_down:
		return
	var live: Array[EmberPickup] = []
	for pickup in _pickups:
		if is_instance_valid(pickup):
			live.append(pickup)
	_pickups = live
	for pickup: EmberPickup in live:
		pickup.try_collect(_hero.global_position)

func _on_pickup_collected(pickup: EmberPickup) -> void:
	_pickups.erase(pickup)
	if pickup.pickup_kind == &"scrap":
		scrap += maxi(pickup.scrap_value, 0)
		_hud.update_stats(scrap, core_health, current_wave)
		_hud.update_status("拾取废料  /  +%d" % pickup.scrap_value)
		return
	if pickup.pickup_kind == &"heal":
		if _hero != null:
			_hero.heal_percent(0.20)
		_hud.update_status("拾取药剂  /  恢复 20% 生命")
		return
	if pickup.pickup_kind == &"skill":
		_hero.unlock_dash()
		_hud.set_loadout(String(WeaponCatalog.get_def(_hero.current_weapon)["display_name"]), true)
		_hud.update_status("冲刺已解锁  /  空格使用")
		return
	_hero.equip_weapon(pickup.payload)
	_sync_weapon_hud()
	_hud.update_status("已装备%s" % String(WeaponCatalog.get_def(pickup.payload)["display_name"]))

func _on_enemy_hit(enemy: FrontierEnemy, amount: int, source: StringName) -> void:
	if source == &"hero":
		spawn_hit_effect(enemy.hurt_center(), 0.24, 0.28)

func _process_hero_contact(delta: float) -> void:
	if _hero == null or _hero.is_down:
		return
	_contact_timer = maxf(_contact_timer - delta, 0.0)
	if _contact_timer > 0.0:
		return
	for enemy: FrontierEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		if _hero.global_position.distance_to(enemy.global_position) <= 26.0:
			_hero.take_damage(enemy.contact_damage)
			enemy.play_attack(_hero.global_position - enemy.global_position)
			_contact_timer = CONTACT_INTERVAL
			return

func get_active_enemies() -> Array[FrontierEnemy]:
	var live: Array[FrontierEnemy] = []
	for enemy: FrontierEnemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_active():
			live.append(enemy)
	return live

func find_enemy_in_range(origin: Vector2, attack_range: float) -> FrontierEnemy:
	var closest: FrontierEnemy
	var closest_distance := attack_range
	for enemy: FrontierEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		var gap := enemy.hurt_gap(origin)
		if gap <= closest_distance:
			closest = enemy
			closest_distance = gap
	return closest

func apply_splash(origin_enemy: FrontierEnemy, radius: float, amount: int, source: StringName) -> void:
	if not is_instance_valid(origin_enemy):
		return
	for enemy: FrontierEnemy in _enemies:
		if enemy == origin_enemy or not is_instance_valid(enemy) or not enemy.is_active():
			continue
		if origin_enemy.global_position.distance_to(enemy.global_position) <= radius:
			enemy.take_damage(amount, source)

func spawn_projectile(origin: Vector2, target: FrontierEnemy, damage: int, kind: StringName = &"pulse") -> void:
	if not is_instance_valid(target) or not target.is_active():
		return
	var projectile := _acquire_tower_bullet()
	projectile.z_index = 5
	projectile.configure(target, damage, self)
	if kind == &"burst":
		projectile.set_burst(78.0, 0.55)
	elif kind == &"frost":
		projectile.set_frost(0.6, 1.5)
	_register_live_bullet(projectile)
	projectile.global_position = origin
	projectile.visible = true
	projectile.set_process(true)

func spawn_hero_projectile(origin: Vector2, direction: Vector2, weapon: Dictionary) -> void:
	var projectile := _acquire_hero_bullet()
	projectile.z_index = 5
	var texture_path := String(weapon.get("fx_path", ""))
	if texture_path.is_empty() or load(texture_path) == null:
		texture_path = "res://assets/generated/fx/hero-bullet.png"
		if weapon["kind"] == &"shotgun":
			texture_path = "res://assets/generated/fx/hero-pellet.png"
	projectile.configure(
		direction,
		int(weapon["damage"]),
		float(weapon["speed"]),
		float(weapon["max_range"]),
		float(weapon["falloff_range"]),
		int(weapon["falloff_damage"]),
		self,
		texture_path,
		float(weapon.get("fx_scale", 0.22)),
		float(weapon.get("hit_radius", 16.0))
	)
	_register_live_bullet(projectile)
	projectile.global_position = origin
	projectile.visible = true
	projectile.set_process(true)

func recycle_bullet(bullet: Node) -> void:
	if bullet == null or not is_instance_valid(bullet):
		return
	_live_bullets.erase(bullet)
	if bullet.has_method("reset"):
		bullet.call("reset")
	if bullet.get_parent() != _bullet_pool_root and _bullet_pool_root != null:
		if bullet.get_parent() != null:
			bullet.get_parent().remove_child(bullet)
		_bullet_pool_root.add_child(bullet)
	_idle_pool.append(bullet)

func _register_live_bullet(bullet: Node) -> void:
	if bullet.get_parent() != self:
		if bullet.get_parent() != null:
			bullet.get_parent().remove_child(bullet)
		add_child(bullet)
	_live_bullets.append(bullet)

func _acquire_tower_bullet() -> EmberProjectile:
	_recycle_oldest_if_full()
	var idle := _take_idle_of_class("EmberProjectile")
	if idle is EmberProjectile:
		return idle as EmberProjectile
	return EmberProjectile.new()

func _acquire_hero_bullet() -> HeroProjectile:
	_recycle_oldest_if_full()
	var idle := _take_idle_of_class("HeroProjectile")
	if idle is HeroProjectile:
		return idle as HeroProjectile
	return HeroProjectile.new()

func _recycle_oldest_if_full() -> void:
	if _live_bullets.size() < BULLET_CAP:
		return
	recycle_bullet(_live_bullets[0])

func _take_idle_of_class(type_name: String) -> Node:
	for index: int in range(_idle_pool.size()):
		var candidate: Node = _idle_pool[index]
		if candidate == null or not is_instance_valid(candidate):
			continue
		if type_name == "EmberProjectile" and candidate is EmberProjectile:
			_idle_pool.remove_at(index)
			return candidate
		if type_name == "HeroProjectile" and candidate is HeroProjectile:
			_idle_pool.remove_at(index)
			return candidate
	return null

func spawn_hit_effect(effect_position: Vector2, scale_factor: float = 0.18, duration: float = 0.28, texture_path: String = "") -> void:
	var effect := ImpactEffect.new()
	effect.position = effect_position
	effect.z_index = 6
	add_child(effect)
	effect.configure(scale_factor, duration, texture_path)

func _explode_core() -> void:
	if _core_exploded:
		return
	_core_exploded = true
	_core_explode_left = 0.90
	_wave_active = false
	if _core_burst != null:
		_core_burst.visible = true
		_core_burst.modulate = Color.WHITE
		_core_burst.scale = Vector2(0.38, 0.38)
	spawn_hit_effect(CORE_GLOW, 0.72, 0.55, "res://assets/generated/fx/core-explode.png")
	spawn_hit_effect(CORE_GLOW + Vector2(18.0, 12.0), 0.42, 0.40)
	spawn_hit_effect(CORE_GLOW + Vector2(-12.0, -16.0), 0.36, 0.38)
	_hud.update_status("核心过载  /  水晶崩解")

func _tick_core_explode(delta: float) -> void:
	_core_explode_left = maxf(_core_explode_left - delta, 0.0)
	var t := 1.0 - clampf(_core_explode_left / 0.90, 0.0, 1.0)
	if _core_burst != null:
		_core_burst.scale = Vector2(0.38, 0.38) * (0.85 + t * 0.55)
		_core_burst.modulate = Color(1.0, 1.0, 1.0, 1.0 - t * 0.28)
		_core_burst.rotation = t * 0.28
	if _core_explode_left <= 0.0 and not _is_game_over:
		_end_run()

func _on_hero_attacked(origin: Vector2, facing: int) -> void:
	var weapon := WeaponCatalog.get_def(_hero.current_weapon if _hero != null else &"sword")
	var target := _find_hero_target(origin, facing, float(weapon.get("max_range", 118.0)))
	_spawn_melee_slash(origin, facing, weapon)
	if target == null:
		return
	var amount := _hero.melee_strike_damage() if _hero != null else int(weapon["damage"])
	target.take_damage(amount, &"hero")
	EmberHitStop.punch_melee(get_tree())

func _spawn_melee_slash(origin: Vector2, facing: int, weapon: Dictionary) -> void:
	var fx_path := String(weapon.get("fx_path", ""))
	if fx_path.is_empty():
		return
	var fx_offset: Variant = weapon.get("fx_offset", Vector2(36.0, -18.0))
	var offset: Vector2 = fx_offset as Vector2 if fx_offset is Vector2 else Vector2(36.0, -18.0)
	var slash := ImpactEffect.new()
	slash.name = "MeleeSlash"
	slash.position = origin + Vector2(float(facing) * offset.x, offset.y)
	slash.rotation = 0.0 if facing > 0 else PI
	slash.z_index = 6
	add_child(slash)
	slash.configure(float(weapon.get("fx_scale", 0.55)), 0.16, fx_path)

func _on_hero_ranged_fired(origin: Vector2, aim_dir: Vector2, weapon_id: StringName) -> void:
	var weapon := WeaponCatalog.get_def(weapon_id)
	var aim := aim_dir.normalized() if not aim_dir.is_zero_approx() else Vector2.RIGHT
	var base_angle := aim.angle()
	var pellets := int(weapon["pellet_count"])
	var spread := deg_to_rad(_hero.fire_spread_degrees() if _hero != null else float(weapon["spread_degrees"]))
	spawn_muzzle_flash(origin, aim)
	if pellets <= 1:
		var drift := deg_to_rad(randf_range(-_hero.fire_spread_degrees(), _hero.fire_spread_degrees()) if _hero != null else 0.0)
		spawn_hero_projectile(origin, Vector2.from_angle(base_angle + drift), weapon)
		return
	for index: int in range(pellets):
		var t := 0.0 if pellets == 1 else (float(index) / float(pellets - 1)) * 2.0 - 1.0
		spawn_hero_projectile(origin, Vector2.from_angle(base_angle + t * spread), weapon)

func spawn_muzzle_flash(origin: Vector2, aim_dir: Vector2) -> void:
	var flash := ImpactEffect.new()
	flash.name = "MuzzleFlash"
	flash.position = origin
	flash.rotation = aim_dir.angle()
	flash.z_index = 6
	add_child(flash)
	flash.configure(0.28, 0.12, "res://assets/generated/fx/muzzle.png")

func _find_hero_target(origin: Vector2, facing: int, reach: float = 118.0) -> FrontierEnemy:
	var closest: FrontierEnemy
	var closest_gap := reach
	for enemy: FrontierEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		var center := enemy.hurt_center()
		if facing * (center.x - origin.x) < -20.0:
			continue
		var gap := enemy.hurt_gap(origin)
		if gap <= closest_gap:
			closest = enemy
			closest_gap = gap
	return closest

func toggle_speed() -> void:
	simulation_speed = 2.0 if is_equal_approx(simulation_speed, 1.0) else 1.0
	_hud.set_speed_label(simulation_speed)

func restart_run() -> void:
	EmberRunSave.delete_run()
	get_tree().reload_current_scene()

func _end_run() -> void:
	_is_game_over = true
	_wave_active = false
	_close_talk()
	scrap += _shop.close_and_refund()
	EmberRunSave.update_records(current_wave, defeated_count, run_time)
	EmberRunSave.delete_run()
	_hud.set_npc_prompt(false, Vector2.ZERO)
	_hud.show_end_screen(false, defeated_count, current_wave, run_time)
	_hud.update_status("核心失守  /  最高波次 %d" % current_wave)

func buy_shop_slot(index: int) -> void:
	if _is_game_over or not _shop.is_open:
		return
	var result := _shop.buy(index, scrap, _hero.has_dash, core_health, CORE_MAX)
	_hud.update_status(String(result["message"]))
	if not bool(result["ok"]):
		return
	scrap -= int(result["cost"])
	match result["kind"]:
		&"skill":
			_hero.unlock_dash()
			_sync_weapon_hud()
			_shop.offer_trainer_upgrades(
				_director.upcoming_wave() if _director.is_prep() else current_wave,
				_hero.attack_bonus_level,
				_hero.vitality_level,
				_hero.dash_cd_level
			)
		&"heal":
			_hero.heal_percent(0.40)
		&"upgrade":
			_apply_trainer_upgrade(result["payload"])
		&"repair":
			core_health = mini(CORE_MAX, core_health + 1)
		&"scrap":
			scrap += 40
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.set_hero_hp(_hero.health, _hero.max_health, _hero.is_down)
	_refresh_shop_ui()

func _apply_trainer_upgrade(payload: StringName) -> void:
	match payload:
		&"attack":
			_hero.apply_attack_upgrade()
		&"vitality":
			_hero.apply_vitality_upgrade()
		&"dash_cd":
			_hero.apply_dash_cd_upgrade()

func _refresh_shop_stock(upcoming_wave: int) -> int:
	if _hero == null:
		return _shop.refresh(upcoming_wave, false, core_health, CORE_MAX)
	return _shop.refresh(
		upcoming_wave,
		_hero.has_dash,
		core_health,
		CORE_MAX,
		_hero.attack_bonus_level,
		_hero.vitality_level,
		_hero.dash_cd_level
	)

func _refresh_shop_ui() -> void:
	var talking := _talking_npc
	var shop_open := _shop.is_open and not _is_game_over and talking != &""
	_hud.set_shop_slots(_shop.slots, scrap, _shop.held_kind, talking)
	_hud.show_shop(shop_open, talking)
	_hud.set_hold_hint(_shop.held_kind)
	if _npc_merchant != null:
		_npc_merchant.visible = true
	if _npc_trainer != null:
		_npc_trainer.visible = true
	_refresh_shop_shelves()

func _refresh_shop_shelves() -> void:
	var sold_flags: Array[bool] = []
	var filled_flags: Array[bool] = []
	for index: int in range(SHOP_SHELVES.size()):
		sold_flags.append(false)
		filled_flags.append(false)
		if index >= _shelf_icons.size():
			continue
		var icon := _shelf_icons[index]
		var slot_index := _shelf_slot_index(index)
		if not _shop.is_open or _is_game_over or slot_index < 0 or slot_index >= _shop.slots.size():
			icon.visible = false
			continue
		var slot: Dictionary = _shop.slots[slot_index]
		var icon_path := String(slot.get("icon", ""))
		icon.texture = load(icon_path) as Texture2D if icon_path != "" else null
		icon.visible = icon.texture != null
		var sold := bool(slot.get("sold", false))
		sold_flags[index] = sold
		filled_flags[index] = true
		icon.modulate = Color(0.45, 0.45, 0.48, 0.70) if sold else Color.WHITE
		var kind: StringName = slot.get("kind", &"")
		icon.scale = Vector2(0.28, 0.28) if kind == &"tower" else Vector2(0.34, 0.34)
	if _shop_pen != null:
		_shop_pen.set("shelf_sold", sold_flags)
		_shop_pen.set("shelf_filled", filled_flags)
		_shop_pen.queue_redraw()

func _shelf_vendor(shelf_index: int) -> StringName:
	if shelf_index < 0 or shelf_index >= SHELF_VENDORS.size():
		return &"merchant"
	return SHELF_VENDORS[shelf_index]

func _shelf_slot_index(shelf_index: int) -> int:
	var vendor := _shelf_vendor(shelf_index)
	var local := 0
	for prior: int in range(shelf_index):
		if _shelf_vendor(prior) == vendor:
			local += 1
	var seen := 0
	for slot_index: int in range(_shop.slots.size()):
		if StringName(_shop.slots[slot_index].get("vendor", &"merchant")) != vendor:
			continue
		if seen == local:
			return slot_index
		seen += 1
	return -1

func _cycle_default_tower() -> void:
	match default_tower_kind:
		&"pulse":
			default_tower_kind = &"burst"
		&"burst":
			default_tower_kind = &"frost"
		_:
			default_tower_kind = &"pulse"
	_hud.set_default_tower(default_tower_kind)
	_hud.update_status("默认建造  /  %s" % EmberTower.kind_display_name(default_tower_kind, 1))

func _set_hero_state(next_state: StringName) -> void:
	if _hero == null:
		return
	_hero.set_demo_state(next_state)

func _cycle_hero_state() -> void:
	match _hero_state:
		&"idle":
			_set_hero_state(&"run")
		&"run":
			_set_hero_state(&"jump")
		&"jump":
			_set_hero_state(&"attack")
		_:
			_set_hero_state(&"idle")

func _play_attack() -> void:
	if _hero != null:
		_hero.request_attack()

func _play_jump() -> void:
	if _hero != null:
		_hero.request_jump()

func _play_dash() -> void:
	if _hero != null:
		_hero.request_dash()

func _on_hero_state_changed(next_state: StringName) -> void:
	_hero_state = next_state
	_hud.set_hero_state(_hero_state_display_name(next_state))

func _on_hero_health_changed(current: int, maximum: int) -> void:
	_hud.set_hero_hp(current, maximum, _hero.is_down)

func _on_hero_downed() -> void:
	_hud.set_hero_hp(0, _hero.max_health, true)
	_hud.update_status("英雄倒地  /  即将在核心附近复活")

func _on_hero_revived() -> void:
	_hud.set_hero_hp(_hero.health, _hero.max_health, false)
	_hud.update_status("英雄已复活  /  生命 40")

func _hero_state_display_name(state: StringName) -> String:
	match state:
		&"run":
			return "奔跑"
		&"jump":
			return "跳跃"
		&"attack":
			return "攻击"
		&"dash":
			return "冲刺"
		&"down":
			return "倒地"
		_:
			return "待命"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.keycode == KEY_QUOTELEFT:
			_toggle_dev_mode()
			get_viewport().set_input_as_handled()
			return
		if _dev_mode and _handle_dev_key(event.keycode):
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_J:
			_play_attack()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_K:
			_play_jump()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE:
			_play_dash()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			try_talk_to_nearby_npc()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Q:
			_cycle_hero_weapon()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _hud != null and event.position.x > 1000.0 and event.position.y > 520.0:
			_hud.poke_action_cluster()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB:
				toggle_speed()
			KEY_I:
				_set_hero_state(&"idle")
			KEY_R:
				_set_hero_state(&"run")
			KEY_H:
				_cycle_hero_state()
			KEY_U:
				upgrade_selected_tower()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world := get_global_mouse_position()
		if _try_buy_shelf(world):
			get_viewport().set_input_as_handled()
			return
		_handle_field_click(world)

func _try_buy_shelf(world_position: Vector2) -> bool:
	if not is_shop_gate_open() or not _shop.is_open:
		return false
	for index: int in range(SHOP_SHELVES.size()):
		if world_position.distance_to(SHOP_SHELVES[index]) > 26.0:
			continue
		var slot_index := _shelf_slot_index(index)
		if slot_index < 0:
			return true
		buy_shop_slot(slot_index)
		return true
	return false

func _notification(what: int) -> void:
	pass

func _handle_field_click(click_position: Vector2) -> void:
	if _is_game_over:
		return
	_try_place_tower(click_position)

func _cell_at(world_position: Vector2) -> Vector2i:
	return Vector2i(
		int(floor((world_position.x - GRID_OX) / TILE_W)),
		int(floor((world_position.y - GRID_OY) / TILE_H))
	)

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(GRID_OX + (float(cell.x) + 0.5) * TILE_W, GRID_OY + (float(cell.y) + 0.5) * TILE_H)

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(GRID_OX + float(cell.x) * TILE_W, GRID_OY + float(cell.y) * TILE_H, TILE_W, TILE_H)

func _cell_is_buildable(cell: Vector2i) -> bool:
	var center := _cell_center(cell)
	if not (
		COMBAT_ROOM.has_point(center)
		or ROAD_EAST.has_point(center)
		or ROAD_NORTH.has_point(center)
		or ROAD_SOUTH.has_point(center)
	):
		return false
	if _is_shop_interior(center):
		return false
	if _cell_rect(cell).intersects(CORE_PLATFORM) or center.distance_to(CORE_GLOW) < CORE_BUILD_CLEAR:
		return false
	var parked: Variant = _cell_towers.get(cell, null)
	if parked is EmberTower and is_instance_valid(parked):
		return false
	return true

func _tower_at(world_position: Vector2) -> EmberTower:
	var cell := _cell_at(world_position)
	var parked: Variant = _cell_towers.get(cell, null)
	if parked is EmberTower and is_instance_valid(parked):
		return parked as EmberTower
	for tower: EmberTower in _towers:
		if is_instance_valid(tower) and tower.position.distance_to(world_position) <= 28.0:
			return tower
	return null

func get_move_stick() -> Vector2:
	if _hud == null:
		return Vector2.ZERO
	return _hud.move_stick

func is_shop_gate_open() -> bool:
	return _director.is_prep() and not _is_game_over

func clamp_hero_position(_from: Vector2, next: Vector2) -> Vector2:
	next = _clamp_to_walkable(_from, next)
	next = _separate_from_npcs(next)
	next = _clamp_to_walkable(_from, next)
	return _separate_from_npcs(next)

func clamp_enemy_position(_from: Vector2, next: Vector2) -> Vector2:
	return _clamp_to_walkable(_from, next)

func enemy_path_point(from: Vector2, want: Vector2) -> Vector2:
	var room := COMBAT_ROOM
	if from.y < room.position.y + 8.0:
		var south_y := room.position.y + 64.0
		if from.x > room.end.x:
			return Vector2(from.x, ROAD_EAST.position.y + 72.0)
		return Vector2(from.x, south_y)
	if from.y > room.end.y - 8.0:
		return Vector2(from.x, room.end.y - 64.0)
	if from.x > room.end.x + 8.0:
		return Vector2(room.end.x - 48.0, from.y)
	return want

func _is_shop_interior(point: Vector2) -> bool:
	return (
		MERCHANT_ROOM.has_point(point)
		or TRAINER_ROOM.has_point(point)
		or MERCHANT_DOOR.has_point(point)
		or TRAINER_DOOR.has_point(point)
	)

func _in_home_area(point: Vector2) -> bool:
	return SHOP_WING.has_point(point) or HOME_HALL.has_point(point) or _is_shop_interior(point)

func _is_walkable(point: Vector2) -> bool:
	return (
		COMBAT_ROOM.has_point(point)
		or ROAD_EAST.has_point(point)
		or ROAD_NORTH.has_point(point)
		or ROAD_SOUTH.has_point(point)
		or HOME_HALL.has_point(point)
		or _is_shop_interior(point)
	)

func _clamp_to_walkable(_from: Vector2, next: Vector2) -> Vector2:
	next.x = clampf(next.x, FLOOR_BOUNDS.position.x, FLOOR_BOUNDS.end.x)
	next.y = clampf(next.y, FLOOR_BOUNDS.position.y, FLOOR_BOUNDS.end.y)
	if _is_walkable(next):
		return next
	var slide_x := Vector2(_from.x, next.y)
	var slide_y := Vector2(next.x, _from.y)
	if _is_walkable(slide_x):
		return slide_x
	if _is_walkable(slide_y):
		return slide_y
	return _from

func _animate_npc(npc: Sprite2D, time: float, phase: float) -> void:
	if npc == null:
		return
	var rest: Vector2 = npc.get_meta("rest_pos", npc.position)
	var rest_scale: Vector2 = npc.get_meta("rest_scale", npc.scale)
	npc.position = rest + Vector2(sin(time * 2.0 + phase) * 1.1, sin(time * 3.6 + phase) * 2.6)
	var breathe := 1.0 + sin(time * 3.6 + phase) * 0.04
	npc.scale = rest_scale * Vector2(breathe, 2.0 - breathe)
	npc.rotation = sin(time * 1.5 + phase) * 0.05

func _npc_body_position(npc: Sprite2D) -> Vector2:
	var rest: Vector2 = npc.get_meta("rest_pos", npc.global_position)
	return rest + Vector2(0.0, 24.0)


func _npc_for_id(npc_id: StringName) -> Sprite2D:
	if npc_id == &"merchant":
		return _npc_merchant
	if npc_id == &"trainer":
		return _npc_trainer
	return null


func _distance_to_npc(npc_id: StringName) -> float:
	var npc := _npc_for_id(npc_id)
	if npc == null or _hero == null:
		return 9999.0
	return _hero.position.distance_to(_npc_body_position(npc))


func _closest_npc_id() -> StringName:
	var best := &""
	var best_dist := 9999.0
	for npc_id: StringName in [&"merchant", &"trainer"]:
		var dist := _distance_to_npc(npc_id)
		if dist < best_dist:
			best_dist = dist
			best = npc_id
	return best


func _update_npc_talk() -> void:
	if _hero == null or not is_shop_gate_open() or _is_game_over:
		_near_npc = &""
		_close_talk()
		_hud.set_npc_prompt(false, Vector2.ZERO)
		return
	var closest := _closest_npc_id()
	var closest_dist := _distance_to_npc(closest)
	if _near_npc != &"" and closest == _near_npc and closest_dist <= LEAVE_RADIUS:
		pass
	elif closest_dist <= TALK_RADIUS:
		_near_npc = closest
	else:
		_near_npc = &""
	if _talking_npc != &"" and _distance_to_npc(_talking_npc) > LEAVE_RADIUS:
		_close_talk()
	var show_bubble := _near_npc != &"" and _talking_npc == &""
	_hud.set_talk_enabled(_near_npc != &"")
	if show_bubble:
		var npc := _npc_for_id(_near_npc)
		var rest: Vector2 = npc.get_meta("rest_pos", npc.global_position) if npc != null else Vector2.ZERO
		_hud.set_npc_prompt(true, rest + Vector2(0.0, -58.0), "按 E 交谈")
	else:
		_hud.set_npc_prompt(false, Vector2.ZERO)


func try_talk_to_nearby_npc() -> bool:
	if not is_shop_gate_open() or _is_game_over or _hero == null:
		return false
	var npc_id := _closest_npc_id()
	if npc_id == &"" or _distance_to_npc(npc_id) > TALK_RADIUS:
		return false
	_open_talk(npc_id)
	return true


func _open_talk(npc_id: StringName) -> void:
	_talking_npc = npc_id
	_near_npc = npc_id
	_hud.set_npc_prompt(false, Vector2.ZERO)
	if npc_id == &"trainer":
		if _hero != null and _hero.has_dash:
			_hud.update_status("想打得更狠，还是站得更久？")
		else:
			_hud.update_status("练冲刺，还是包扎？")
	else:
		_hud.update_status("要火器还是炮台？")
	_refresh_shop_ui()


func _close_talk() -> void:
	if _talking_npc == &"":
		_refresh_shop_ui()
		return
	_talking_npc = &""
	_refresh_shop_ui()

func _separate_from_npcs(next: Vector2) -> Vector2:
	for npc: Sprite2D in [_npc_merchant, _npc_trainer]:
		if npc == null or not is_instance_valid(npc):
			continue
		var body := _npc_body_position(npc)
		var away := next - body
		var min_dist := HERO_BODY_RADIUS + NPC_BODY_RADIUS
		var dist := away.length()
		if dist >= min_dist:
			continue
		if dist <= 0.001:
			away = Vector2.UP
			dist = 1.0
		next = body + away * (min_dist / dist)
	return next

## Moves a hero trapped behind the closing shop wall to the walkable south-door tile.
func _eject_hero_from_shop() -> void:
	_near_npc = &""
	if _talking_npc != &"":
		_close_talk()
	if _hero != null and _is_shop_interior(_hero.position):
		var exit_position: Vector2 = Vector2(SHOP_DOOR.get_center().x, SHOP_DOOR.end.y + HERO_BODY_RADIUS + 4.0)
		_hero.position = exit_position
	if _hud != null:
		_hud.set_talk_enabled(false)
		_hud.set_npc_prompt(false, Vector2.ZERO)

func hero_seek_position() -> Vector2:
	if _hero != null and is_instance_valid(_hero) and not _hero.is_down:
		return _hero.global_position
	return Vector2.INF

## Returns the fixed gameplay target; CORE_GLOW remains visual-only.
func core_goal() -> Vector2:
	return Vector2(CORE_HIT_X, LANE_Y)

func enemy_target_position(_from: Vector2, enemy: Node = null) -> Vector2:
	if enemy is FrontierEnemy and is_instance_valid(enemy):
		return enemy.get("_goal") as Vector2
	return core_goal()

func tower_avoidance(from: Vector2, direction: Vector2) -> Vector2:
	return steer_enemy(from, direction, null)

func steer_enemy(from: Vector2, direction: Vector2, self_enemy: Node) -> Vector2:
	var steer := direction
	for tower: EmberTower in _towers:
		if not is_instance_valid(tower):
			continue
		var away := from - tower.position
		var distance := away.length()
		if distance < 52.0 and distance > 0.01:
			steer += away.normalized() * ((52.0 - distance) / 52.0) * 1.8
	var others: Array = get_tree().get_nodes_in_group("ember_enemies") if get_tree() != null else []
	for other in others:
		if other == self_enemy or not is_instance_valid(other):
			continue
		var away_e: Vector2 = from - (other as Node2D).global_position
		var dist := away_e.length()
		var other_kind: StringName = other.get("variant")
		var radius := 42.0 if other_kind == &"boss" else 32.0 if other_kind == &"brute" else 28.0 if other_kind == &"mage" else 24.0 if other_kind == &"runner" else 26.0
		if dist < 0.01:
			var slot := float((other.get_instance_id() + (self_enemy.get_instance_id() if self_enemy != null else 1)) % 12)
			away_e = Vector2.from_angle(slot * TAU / 12.0)
			dist = 0.01
		if dist < radius:
			steer += away_e.normalized() * ((radius - dist) / radius) * 2.8
	if _hero != null and is_instance_valid(_hero) and not _hero.is_down:
		var away_h := from - _hero.global_position
		var hero_dist := away_h.length()
		if hero_dist < 28.0 and hero_dist > 0.01:
			steer += away_h.normalized() * ((28.0 - hero_dist) / 28.0) * 1.6
	if steer.is_zero_approx():
		return direction
	return steer.normalized()

func _random_spawn_point() -> Vector2:
	var holes := _spawn_holes_for_wave(current_wave)
	if holes.is_empty():
		holes.append(SPAWN_EAST)
	var hole: Vector2 = holes[_spawned_in_wave % holes.size()]
	if hole == SPAWN_NORTH:
		return Vector2(_drop_rng.randf_range(MOUTH_X0 + 56.0, 1760.0 - 56.0), hole.y + _drop_rng.randf_range(0.0, 24.0))
	if hole == SPAWN_SOUTH:
		return Vector2(_drop_rng.randf_range(MOUTH_X0 + 56.0, 1760.0 + 12.0 * TILE_W - 56.0), hole.y + _drop_rng.randf_range(-24.0, 8.0))
	return hole + Vector2(_drop_rng.randf_range(-12.0, 12.0), _drop_rng.randf_range(-90.0, 90.0))

func _try_place_tower(click_position: Vector2) -> void:
	if _is_game_over:
		return
	var parked := _tower_at(click_position)
	if parked != null:
		_select_tower(parked)
		_hud.update_status("已选中防御塔  /  按 U 升级或出售")
		return
	var cell := _cell_at(click_position)
	if not _cell_is_buildable(cell):
		_hud.update_status("这里不能建造")
		return
	if _towers.size() >= TOWER_CAP:
		_hud.update_status("没有空余建造位")
		return
	var place_kind := default_tower_kind
	var planted_weapon: StringName = &""
	var using_held := _shop.held_kind != &""
	if using_held:
		place_kind = _shop.held_kind
		if WeaponCatalog.has_id(place_kind):
			planted_weapon = place_kind
			place_kind = &"pulse"
	elif _director.is_prep():
		_hud.update_status("先去商人处购买  /  走近按 E 再点地放下")
		return
	else:
		var cost := EmberTower.build_cost(default_tower_kind)
		if scrap < cost:
			_hud.update_status("资源不足  /  建造需要 %d 资源" % cost)
			return
		scrap -= cost
	var tower := _spawn_tower_at(_cell_center(cell), place_kind, 1, planted_weapon)
	if using_held:
		_shop.mark_tower_placed()
	_hud.update_stats(scrap, core_health, current_wave)
	var placed_name := EmberTower.kind_display_name(place_kind, 1)
	if tower != null and tower.weapon_id != &"":
		placed_name = String(WeaponCatalog.get_def(tower.weapon_id).get("display_name", "武器"))
	_hud.update_status("%s已部署  /  自动索敌已开启" % placed_name)
	_refresh_shop_ui()

func _spawn_tower_on_pad(pad: int, place_kind: StringName, saved_level: int = 1) -> EmberTower:
	var spot := TOWER_PADS[pad] if pad >= 0 and pad < TOWER_PADS.size() else _cell_center(_cell_at(Vector2.ZERO))
	return _spawn_tower_at(spot, place_kind, saved_level)

func _spawn_tower_at(world_pos: Vector2, place_kind: StringName, saved_level: int = 1, planted_weapon: StringName = &"") -> EmberTower:
	var cell := _cell_at(world_pos)
	var tower := EmberTower.new()
	tower.pad_index = -1
	tower.position = _cell_center(cell)
	tower.z_index = 2
	tower.configure(self, place_kind, planted_weapon)
	if saved_level > 1 and planted_weapon == &"":
		tower.restore_level(saved_level)
	tower.upgraded.connect(_on_tower_upgraded)
	_towers.append(tower)
	_cell_towers[cell] = tower
	add_child(tower)
	_select_tower(tower)
	return tower

func _select_tower(tower: EmberTower) -> void:
	_selected_tower = tower
	for other_tower: EmberTower in _towers:
		other_tower.selected = other_tower == tower
		other_tower.queue_redraw()
	if tower == null:
		_hud.clear_tower_info()
		return
	_hud.set_tower_info(
		tower.level,
		tower.attack_damage,
		tower.attack_range,
		tower.get_upgrade_cost(),
		tower.weapon_id == &"" and scrap >= tower.get_upgrade_cost() and tower.level < 3,
		tower.kind if tower.weapon_id == &"" else tower.weapon_id,
		tower.sell_value(),
		true
	)

func upgrade_selected_tower() -> void:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		_hud.update_status("请先选中防御塔  /  点击已放下的塔")
		return
	var cost := _selected_tower.get_upgrade_cost()
	if cost <= 0:
		_hud.update_status("这座防御塔已经满级")
		return
	if scrap < cost:
		_hud.update_status("资源不足  /  升级需要 %d 资源" % cost)
		return
	scrap -= cost
	_selected_tower.upgrade()
	_select_tower(_selected_tower)
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("防御塔升级完成  /  等级 %d 已生效" % _selected_tower.level)

func sell_selected_tower() -> void:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		_hud.update_status("请先选中防御塔  /  点击已放下的塔")
		return
	var tower := _selected_tower
	var refund := tower.sell_value() if tower.has_method("sell_value") else EmberTower.sell_refund(tower.kind)
	scrap += refund
	var cell := _cell_at(tower.position)
	_towers.erase(tower)
	_cell_towers.erase(cell)
	tower.queue_free()
	_select_tower(null)
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("已出售  /  返还 %d 资源" % refund)
	_refresh_shop_ui()

func _on_tower_upgraded(tower: EmberTower, new_level: int) -> void:
	spawn_hit_effect(tower.global_position + Vector2(0.0, -24.0), 0.20, 0.3)

func get_route_contract() -> Dictionary:
	var routes: Array[PackedVector2Array] = [
		PackedVector2Array([SPAWN_EAST, core_goal()]),
		PackedVector2Array([SPAWN_NORTH, core_goal()]),
		PackedVector2Array([SPAWN_SOUTH, core_goal()]),
	]
	return {
		"spawn_x": SPAWN_EAST.x,
		"lane_y": LANE_Y,
		"base_entry_x": BASE_ENTRY_X,
		"base_x": BASE_X,
		"enemy_goal_x": core_goal().x,
		"route_count": 0,
		"layout": &"open_arena",
		"routes": routes,
		"is_open": BASE_X < core_goal().x and core_goal().x < BASE_ENTRY_X,
	}

func _toggle_dev_mode() -> void:
	_dev_mode = not _dev_mode
	if not _dev_mode:
		_dev_god = false
		if _hero != null:
			_hero.debug_god = false
		_hud.set_dev_overlay(false, "")
		_hud.update_status("开发者模式关闭")
		return
	_hud.set_dev_overlay(true, _dev_overlay_text())
	_hud.update_status("开发者模式  /  F1 开关")

func _dev_overlay_text() -> String:
	var live := get_active_enemies().size()
	var phase := "准备" if _director.is_prep() else "作战" if _director.is_combat() else "—"
	var lines: Array[String] = [
		"开发者 F1/` 关",
		"E %d/%d  B %d/%d  T %d/%d  波 %d %s" % [
			live,
			LIVE_ENEMY_CAP,
			_live_bullets.size(),
			BULLET_CAP,
			_towers.size(),
			TOWER_CAP,
			current_wave,
			phase,
		],
	]
	var current_row := -1
	var parts: Array[String] = []
	for cheat: Dictionary in DEV_CHEATS:
		var row := int(cheat["row"])
		if row != current_row:
			if not parts.is_empty():
				lines.append("   ".join(parts))
				parts.clear()
			current_row = row
		var desc := String(cheat["desc"])
		if int(cheat["key"]) == KEY_0:
			desc += " %s" % ("开" if _dev_god else "关")
		parts.append("%s %s" % [String(cheat["label"]), desc])
	if not parts.is_empty():
		lines.append("   ".join(parts))
	return "\n".join(lines)

func _handle_dev_key(keycode: Key) -> bool:
	for cheat: Dictionary in DEV_CHEATS:
		if int(cheat["key"]) == keycode:
			call(String(cheat["fn"]))
			return true
	return false

func _dev_add_scrap() -> void:
	scrap += 500
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("开发者  /  +500 废料")

func _dev_full_heal() -> void:
	core_health = CORE_MAX
	if _hero != null and not _hero.is_down:
		_hero.health = _hero.max_health
		_hero.health_changed.emit(_hero.health, _hero.max_health)
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("开发者  /  英雄与核心回满")

func _dev_unlock_dash() -> void:
	if _hero != null:
		_hero.unlock_dash()
		_hud.set_loadout(String(WeaponCatalog.get_def(_hero.current_weapon)["display_name"]), true)
		_hud.set_skill(true, _hero.dash_cooldown_left, _hero.dash_cooldown)
	_hud.update_status("开发者  /  冲刺已解锁")

func _dev_start_wave() -> void:
	if _director.is_prep():
		start_wave()
	_hud.update_status("开发者  /  开战")

func _dev_spawn_scout() -> void:
	_dev_spawn(&"scout")

func _dev_spawn_brute() -> void:
	_dev_spawn(&"brute")

func _dev_spawn_boss() -> void:
	_dev_spawn(&"boss")

func _dev_clear_enemies() -> void:
	for enemy: FrontierEnemy in _enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	_hud.update_status("开发者  /  场上敌人已清")

func _dev_hurt_core() -> void:
	core_health = maxi(core_health - 1, 0)
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("开发者  /  核心 -1")
	if core_health <= 0:
		_explode_core()

func _dev_toggle_god() -> void:
	_dev_god = not _dev_god
	if _hero != null:
		_hero.debug_god = _dev_god
	_hud.update_status("开发者  /  无敌 %s" % ("开" if _dev_god else "关"))

func _dev_equip_pistol() -> void:
	_dev_equip_named(&"pistol")

func _dev_equip_shotgun() -> void:
	_dev_equip_named(&"shotgun")

func _dev_prev_weapon() -> void:
	_dev_cycle_weapon(-1)

func _dev_next_weapon() -> void:
	_dev_cycle_weapon(1)

func _dev_cycle_weapon(step: int) -> void:
	if _hero == null:
		return
	var ids := WeaponCatalog.all_ids()
	if ids.is_empty():
		return
	var index := ids.find(_hero.current_weapon)
	if index < 0:
		index = 0
	_dev_equip_named(ids[(index + step + ids.size()) % ids.size()])

func _dev_equip_named(weapon_id: StringName) -> void:
	if _hero == null:
		return
	_hero.equip_weapon(weapon_id)
	var display := String(WeaponCatalog.get_def(weapon_id)["display_name"])
	_sync_weapon_hud()
	_hud.update_status("开发者  /  %s" % display)

func _dev_spawn(kind: StringName) -> void:
	var enemy := FrontierEnemy.new()
	enemy.variant = kind
	match kind:
		&"brute":
			enemy.max_health = 112 + current_wave * 22
			enemy.move_speed = 31.0 + float(maxi(current_wave, 1)) * 2.0
			enemy.reward = 35
			enemy.contact_damage = 16
			enemy.core_damage = 1
		&"boss":
			enemy.max_health = 420 + maxi(current_wave, 1) * 55
			enemy.move_speed = 24.0
			enemy.reward = 120
			enemy.contact_damage = 28
			enemy.core_damage = 2
		_:
			enemy.max_health = 52 + maxi(current_wave, 1) * 12
			enemy.move_speed = 57.0
			enemy.reward = 16
			enemy.contact_damage = 8
			enemy.core_damage = 1
	var start := Vector2(980.0, LANE_Y)
	if _hero != null:
		start = _hero.global_position + Vector2(120.0, 0.0)
	enemy.configure_seek(start, core_goal(), self)
	_register_enemy(enemy)
	_hud.update_status("开发者  /  刷出 %s" % String(kind))

func _dev_fill_pads() -> void:
	scrap += 800
	for spot: Vector2 in TOWER_PADS:
		if _towers.size() >= TOWER_CAP:
			break
		var cell := _cell_at(spot)
		if not _cell_is_buildable(cell):
			continue
		_spawn_tower_at(_cell_center(cell), &"pulse", 1)
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("开发者  /  8 座脉冲")

func _write_run_save() -> void:
	var towers_payload: Array = []
	for tower: EmberTower in _towers:
		if tower != null and is_instance_valid(tower):
			var entry := {
				"x": tower.position.x,
				"y": tower.position.y,
				"kind": String(tower.kind),
				"level": tower.level,
			}
			if tower.weapon_id != &"":
				entry["weapon"] = String(tower.weapon_id)
			towers_payload.append(entry)
	var slots_payload: Array = []
	for slot: Dictionary in _shop.slots:
		slots_payload.append(slot.duplicate(true))
	if slots_payload.is_empty():
		return
	var payload := {
		"version": 1,
		"cleared_wave": current_wave,
		"scrap": scrap,
		"core_health": core_health,
		"run_time": run_time,
		"defeated_count": defeated_count,
		"default_tower_kind": String(default_tower_kind),
		"hero": {
			"health": _hero.health if _hero != null else 100,
			"max_health": _hero.max_health if _hero != null else 100,
			"weapon": String(_hero.current_weapon) if _hero != null else "sword",
			"weapons": [
				String(_hero.weapon_slots[0]) if _hero != null and _hero.weapon_slots.size() > 0 else "sword",
				String(_hero.weapon_slots[1]) if _hero != null and _hero.weapon_slots.size() > 1 else "",
			],
			"weapon_slot": _hero.weapon_slot_index if _hero != null else 0,
			"has_dash": _hero.has_dash if _hero != null else false,
			"attack_bonus_level": _hero.attack_bonus_level if _hero != null else 0,
			"vitality_level": _hero.vitality_level if _hero != null else 0,
			"dash_cd_level": _hero.dash_cd_level if _hero != null else 0,
			"position": [_hero.position.x if _hero != null else 640.0, _hero.position.y if _hero != null else LANE_Y],
		},
		"towers": towers_payload,
		"drop_rng_state": _drop_rng.state,
		"shop_rng_state": _shop.rng.state,
		"slots": slots_payload,
	}
	EmberRunSave.write_run(payload)

func _apply_run_payload(payload: Dictionary) -> bool:
	var slots_raw: Variant = payload.get("slots", [])
	if not (slots_raw is Array) or (slots_raw as Array).is_empty():
		return false
	scrap = int(payload.get("scrap", 300))
	core_health = clampi(int(payload.get("core_health", CORE_MAX)), 0, CORE_MAX)
	run_time = float(payload.get("run_time", 0.0))
	defeated_count = int(payload.get("defeated_count", 0))
	var kind_name := StringName(String(payload.get("default_tower_kind", "pulse")))
	if EmberRunSave.is_valid_tower_kind(kind_name):
		default_tower_kind = kind_name
	current_wave = int(payload.get("cleared_wave", 0))
	var towers_raw: Variant = payload.get("towers", [])
	if towers_raw is Array:
		for item in towers_raw:
			if not (item is Dictionary):
				continue
			var entry: Dictionary = item
			var tower_kind := StringName(String(entry.get("kind", "")))
			var planted := StringName(String(entry.get("weapon", "")))
			var level := int(entry.get("level", 1))
			if planted != &"" and not EmberRunSave.is_valid_weapon(planted):
				continue
			if planted == &"" and not EmberRunSave.is_valid_tower_kind(tower_kind):
				continue
			var spot := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
			if spot == Vector2.ZERO:
				var pad := int(entry.get("pad", -1))
				if pad < 0 or pad >= TOWER_PADS.size():
					continue
				spot = TOWER_PADS[pad]
			if _towers.size() >= TOWER_CAP:
				break
			if not _cell_is_buildable(_cell_at(spot)):
				continue
			if planted != &"":
				_spawn_tower_at(spot, &"pulse", 1, planted)
			else:
				_spawn_tower_at(spot, tower_kind, clampi(level, 1, 3))
	if _hero != null:
		var hero_data: Dictionary = payload.get("hero", {})
		var weapon_id := StringName(String(hero_data.get("weapon", "sword")))
		if not EmberRunSave.is_valid_weapon(weapon_id):
			weapon_id = &"sword"
		var bag: Variant = hero_data.get("weapons", [])
		if bag is Array and (bag as Array).size() >= 1:
			_hero.weapon_slots = [&"", &""]
			for bag_i: int in range(mini((bag as Array).size(), 2)):
				var bag_id := StringName(String((bag as Array)[bag_i]))
				if EmberRunSave.is_valid_weapon(bag_id) or bag_id == &"":
					_hero.weapon_slots[bag_i] = bag_id
			if _hero.weapon_slots[0] == &"":
				_hero.weapon_slots[0] = weapon_id
		_hero.equip_weapon(weapon_id)
		_hero.weapon_slot_index = clampi(int(hero_data.get("weapon_slot", 0)), 0, 1)
		if _hero.weapon_slots[_hero.weapon_slot_index] != &"":
			_hero.current_weapon = _hero.weapon_slots[_hero.weapon_slot_index]
		_hero.attack_bonus_level = 0
		_hero.vitality_level = 0
		_hero.dash_cd_level = 0
		_hero.melee_damage = 46
		_hero.max_health = 100
		var vitality := clampi(int(hero_data.get("vitality_level", 0)), 0, 3)
		for _i in range(vitality):
			_hero.apply_vitality_upgrade()
		var attack := clampi(int(hero_data.get("attack_bonus_level", 0)), 0, 3)
		for _j in range(attack):
			_hero.apply_attack_upgrade()
		if bool(hero_data.get("has_dash", false)):
			_hero.unlock_dash()
			var dash_cd := clampi(int(hero_data.get("dash_cd_level", 0)), 0, 2)
			for _k in range(dash_cd):
				_hero.apply_dash_cd_upgrade()
		_hero.health = clampi(int(hero_data.get("health", _hero.max_health)), 1, _hero.max_health)
		var pos_raw: Variant = hero_data.get("position", [640.0, LANE_Y])
		if pos_raw is Array and (pos_raw as Array).size() >= 2:
			_hero.position = Vector2(float(pos_raw[0]), float(pos_raw[1]))
		_hud.set_hero_hp(_hero.health, _hero.max_health, _hero.is_down)
		_sync_weapon_hud()
		_hud.set_skill(_hero.has_dash, _hero.dash_cooldown_left, _hero.dash_cooldown)
		_hud.set_default_tower(default_tower_kind)
	_drop_rng.state = int(payload.get("drop_rng_state", 0))
	_shop.rng.state = int(payload.get("shop_rng_state", 0))
	_restoring_run = true
	_director.restore(current_wave)
	_shop.restore_slots(slots_raw as Array)
	_refresh_shop_ui()
	_hud.update_stats(scrap, core_health, current_wave)
	_restoring_run = false
	return true

func _sync_weapon_hud() -> void:
	if _hud == null or _hero == null:
		return
	_hud.set_weapon_dock(_hero.weapon_slots, _hero.weapon_slot_index)

func _cycle_hero_weapon() -> void:
	if _hero == null:
		return
	if _hero.cycle_weapon():
		_sync_weapon_hud()
		_hud.update_status("切换武器  /  %s" % String(WeaponCatalog.get_def(_hero.current_weapon)["display_name"]))
	else:
		_hud.update_status("只有一把武器  /  再捡一把就能 Q 切换")

func _world_to_hud(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos

func _draw_home_annex() -> void:
	var void_color := Color("#111318")
	var north_fill := Rect2(FLOOR_BOUNDS.position.x, FLOOR_BOUNDS.position.y, FLOOR_BOUNDS.size.x, 16.0 - FLOOR_BOUNDS.position.y)
	draw_rect(north_fill, void_color, true)
	var west := Rect2(FLOOR_BOUNDS.position.x, 16.0, 0.0 - FLOOR_BOUNDS.position.x, FLOOR_BOUNDS.end.y - 16.0)
	draw_rect(west, void_color, true)
	var east := Rect2(COMBAT_ROOM.end.x, FLOOR_BOUNDS.position.y, FLOOR_BOUNDS.end.x - COMBAT_ROOM.end.x, FLOOR_BOUNDS.size.y)
	draw_rect(east, void_color, true)
	var south := Rect2(FLOOR_BOUNDS.position.x, COMBAT_ROOM.end.y, FLOOR_BOUNDS.size.x, FLOOR_BOUNDS.end.y - COMBAT_ROOM.end.y)
	draw_rect(south, void_color, true)

func _draw() -> void:
	_draw_home_annex()
	var core := CORE_GLOW
	if _core_exploded:
		var t := 1.0 - clampf(_core_explode_left / 0.90, 0.0, 1.0)
		draw_circle(core, 20.0 + t * 70.0, Color(1.0, 0.45, 0.18, 0.22 * (1.0 - t)))
		draw_circle(core, 8.0 + t * 40.0, Color(1.0, 0.86, 0.40, 0.35 * (1.0 - t)))
		draw_arc(core, 16.0 + t * 54.0, 0.0, TAU, 28, Color(1.0, 0.62, 0.22, 0.70 * (1.0 - t)), 3.0)
	else:
		var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.004)
		draw_circle(core, 34.0 + pulse * 10.0, Color(1.0, 0.42, 0.72, 0.06 + pulse * 0.07))
		draw_circle(core, 16.0 + pulse * 4.0, Color(1.0, 0.78, 0.38, 0.10 + pulse * 0.08))
		draw_arc(core, 20.0 + pulse * 3.0, -1.2, 1.2, 20, Color(1.0, 0.69, 0.31, 0.55 + pulse * 0.35), 2.0)
	var holding := _shop != null and _shop.held_kind != &""
	var hover_cell := _cell_at(get_global_mouse_position())
	if _cell_is_buildable(hover_cell):
		var hover_rect := _cell_rect(hover_cell)
		if holding:
			draw_rect(hover_rect, Color(0.98, 0.82, 0.32, 0.22), true)
			draw_rect(hover_rect, Color(0.98, 0.82, 0.32, 0.92), false, 2.0)
		else:
			draw_rect(hover_rect, Color(0.83, 0.69, 0.42, 0.16), true)
			draw_rect(hover_rect, Color(0.83, 0.69, 0.42, 0.70), false, 1.0)
	if _dev_mode:
		for enemy: FrontierEnemy in _enemies:
			if not is_instance_valid(enemy) or not enemy.is_active():
				continue
			var pos := enemy.global_position
			var aggro := bool(enemy.get("_aggro"))
			draw_arc(pos, FrontierEnemy.AGGRO_RADIUS, 0.0, TAU, 32, Color(1.0, 0.35, 0.28, 0.55 if aggro else 0.28), 1.5)
			draw_arc(pos, FrontierEnemy.LEASH_RADIUS, 0.0, TAU, 32, Color(1.0, 0.82, 0.28, 0.22), 1.0)

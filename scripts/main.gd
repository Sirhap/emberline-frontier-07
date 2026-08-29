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
## Painted grout on grid-battlefield-v6 is phase (4, 42) atlas px, not (0, 0).
const FLOOR_GRID_OX := 1280.0 / 1536.0 * 4.0
const FLOOR_GRID_OY := GRID_OY + 720.0 / 1024.0 * 42.0
const LIVE_ENEMY_CAP := 40
const BULLET_CAP := 120
const TOWER_CAP := 16
const CORE_BUILD_CLEAR := 58.0
const CORE_PLATFORM := Rect2(80.0, 210.0, 226.0, 148.0)
const TOWER_PADS: Array[Vector2] = [
	Vector2(456.0, 280.0),
	Vector2(648.0, 280.0),
	Vector2(840.0, 280.0),
	Vector2(984.0, 280.0),
	Vector2(456.0, 400.0),
	Vector2(648.0, 400.0),
	Vector2(840.0, 400.0),
	Vector2(888.0, 336.0),
]
const SPAWN_Y_MIN := 180.0
const SPAWN_Y_MAX := 540.0
const FLOOR_BOUNDS := Rect2(-80.0, -680.0, 2560.0, 2300.0)
const SHOP_ROOM := Rect2()
const SHOP_THRESHOLD := Rect2()
const SHOP_WING := Rect2()
const HOME_ROOM := Rect2(76.0, 72.0, 1100.0, 568.0)
## Floor-cell edges (grout). 20 covers the painted east pit; 33 is the east-road join.
const FLOOR_X_PIT := FLOOR_GRID_OX + 20.0 * TILE_W
const EAST_JOIN_X := FLOOR_GRID_OX + 33.0 * TILE_W
const COMBAT_ROOM := Rect2(76.0, 72.0, EAST_JOIN_X - 76.0, 568.0)
const COMBAT_EXPAND_EAST := Rect2(FLOOR_X_PIT, 16.0, EAST_JOIN_X - FLOOR_X_PIT, 624.0)
const COMBAT_EXPAND_SOUTH := Rect2(76.0, 540.0, EAST_JOIN_X - 76.0, 100.0)
const MOUTH_X0 := FLOOR_GRID_OX + 24.0 * TILE_W
const MOUTH_W := 5.0 * TILE_W
const EAST_WALL_X := FLOOR_GRID_OX + 41.0 * TILE_W
const EAST_ROAD_Y0 := FLOOR_GRID_OY + 4.0 * TILE_H
const EAST_ROAD_H := 5.0 * TILE_H
const EAST_HOLE_Y0 := FLOOR_GRID_OY + 6.0 * TILE_H
const EAST_HOLE_Y1 := FLOOR_GRID_OY + 8.0 * TILE_H
const NORTH_MOUTH := Rect2(MOUTH_X0, 16.0, MOUTH_W, 56.0)
const NORTH_THRESHOLD := Rect2(MOUTH_X0, GRID_OY, MOUTH_W, 16.0 - GRID_OY)
const SOUTH_MOUTH := Rect2(MOUTH_X0, 640.0, MOUTH_W, 56.0)
const ROAD_EAST := Rect2(EAST_JOIN_X, EAST_ROAD_Y0, 8.0 * TILE_W, EAST_ROAD_H)
const ROAD_NORTH := Rect2(MOUTH_X0, FLOOR_GRID_OY - 12.0 * TILE_H, MOUTH_W, 12.0 * TILE_H)
const ROAD_SOUTH := Rect2(MOUTH_X0, 640.0, MOUTH_W, 16.0 * TILE_H)
const SPAWN_NORTH := Vector2(MOUTH_X0 + MOUTH_W * 0.5, FLOOR_GRID_OY - 12.0 * TILE_H + 40.0)
const SPAWN_SOUTH := Vector2(MOUTH_X0 + MOUTH_W * 0.5, 640.0 + 16.0 * TILE_H - 40.0)
const SPAWN_EAST := Vector2(EAST_WALL_X - 28.0, 336.0)
const SPAWN_NORTH_W := Vector2(MOUTH_X0 + MOUTH_W * 0.28, FLOOR_GRID_OY - 12.0 * TILE_H + 40.0)
const SPAWN_NORTH_E := Vector2(MOUTH_X0 + MOUTH_W * 0.72, FLOOR_GRID_OY - 12.0 * TILE_H + 40.0)
const SPAWN_SOUTH_W := Vector2(MOUTH_X0 + MOUTH_W * 0.28, 640.0 + 16.0 * TILE_H - 40.0)
const HOME_HALL := Rect2(-80.0, 80.0, 156.0, 540.0)
## Separate dungeon rooms. Not glued to combat — a corridor sits between each pair of walls.
const SHOP_ROOM_W := 17.0 * TILE_W
const SHOP_ROOM_H := 6.0 * TILE_H
const SHOP_HALL_H := 4.0 * TILE_H
const SHOP_ROOM_X := FLOOR_GRID_OX + 2.0 * TILE_W
const SHOP_DOOR_X := FLOOR_GRID_OX + 8.0 * TILE_W
const SHOP_DOOR_W := 3.0 * TILE_W
const WALL_BAND_H := 80.0 * 720.0 / 1024.0
const TOP_ROOM := Rect2(SHOP_ROOM_X, 16.0 - WALL_BAND_H - SHOP_HALL_H - SHOP_ROOM_H, SHOP_ROOM_W, SHOP_ROOM_H)
const TOP_DOOR := Rect2(SHOP_DOOR_X, TOP_ROOM.end.y, SHOP_DOOR_W, WALL_BAND_H)
const NORTH_HALL := Rect2(SHOP_DOOR_X, TOP_ROOM.end.y, SHOP_DOOR_W, 16.0 - TOP_ROOM.end.y)
const SHOP_DOOR := Rect2(SHOP_DOOR_X, 16.0, SHOP_DOOR_W, WALL_BAND_H)
const SOUTH_SHOP_DOOR := Rect2(SHOP_DOOR_X, 640.0, SHOP_DOOR_W, WALL_BAND_H)
const BOTTOM_ROOM := Rect2(SHOP_ROOM_X, 640.0 + WALL_BAND_H + SHOP_HALL_H, SHOP_ROOM_W, SHOP_ROOM_H)
const BOTTOM_DOOR := Rect2(SHOP_DOOR_X, BOTTOM_ROOM.position.y - WALL_BAND_H, SHOP_DOOR_W, WALL_BAND_H)
const SOUTH_HALL := Rect2(SHOP_DOOR_X, 640.0, SHOP_DOOR_W, BOTTOM_ROOM.position.y - 640.0)
const MERCHANT_ROOM := TOP_ROOM
const TRAINER_ROOM := BOTTOM_ROOM
const MERCHANT_DOOR := SHOP_DOOR
const TRAINER_DOOR := SOUTH_SHOP_DOOR
const NORTH_WALL := Rect2(76.0, 16.0, 1010.0, 56.0)
const GATE_X_MIN := 360.0
const GATE_X_MAX := 500.0
const HERO_BODY_RADIUS := 16.0
const NPC_BODY_RADIUS := 20.0
const NPC_IDLE_FPS := 5.0
const NPC_RESTOCK_FPS := 10.0
const NPC_SHELF_OFFSET := Vector2(0.0, -64.0)
const NPC_RUN_SPEED := 220.0
const NPC_SHELF_DWELL := 0.55
const TALK_RADIUS := 110.0
const LEAVE_RADIUS := 110.0
## Mid combat corridor: conveyors east of the core.
const HOME_REWARD_SPOTS: Array[Vector2] = [
	Vector2(268.0, 250.0),
	Vector2(268.0, 320.0),
	Vector2(268.0, 390.0),
]
## Stalls live inside the separate 上房间 / 下房间, not on the combat floor.
const SHOP_SHELVES: Array[Vector2] = [
	Vector2(SHOP_ROOM_X + 132.0, TOP_ROOM.position.y + 150.0),
	Vector2(SHOP_ROOM_X + 312.0, TOP_ROOM.position.y + 150.0),
	Vector2(SHOP_ROOM_X + 402.0, TOP_ROOM.position.y + 150.0),
	Vector2(SHOP_ROOM_X + 492.0, TOP_ROOM.position.y + 150.0),
	Vector2(SHOP_ROOM_X + 132.0, BOTTOM_ROOM.position.y + 150.0),
	Vector2(SHOP_ROOM_X + 222.0, BOTTOM_ROOM.position.y + 150.0),
	Vector2(SHOP_ROOM_X + 452.0, BOTTOM_ROOM.position.y + 150.0),
	Vector2(SHOP_ROOM_X + 542.0, BOTTOM_ROOM.position.y + 150.0),
	Vector2(SHOP_ROOM_X + 632.0, BOTTOM_ROOM.position.y + 150.0),
]
const SHELF_VENDORS: Array[StringName] = [
	&"mechanic",
	&"merchant",
	&"merchant",
	&"merchant",
	&"summoner",
	&"summoner",
	&"trainer",
	&"trainer",
	&"trainer",
]
const NPC_STAND_MECHANIC := Vector2(SHOP_ROOM_X + 52.0, TOP_ROOM.position.y + 110.0)
const NPC_STAND_MERCHANT := Vector2(SHOP_ROOM_X + 232.0, TOP_ROOM.position.y + 110.0)
const NPC_STAND_SUMMONER := Vector2(SHOP_ROOM_X + 52.0, BOTTOM_ROOM.position.y + 110.0)
const NPC_STAND_OFFICER := Vector2(SHOP_ROOM_X + 312.0, BOTTOM_ROOM.position.y + 110.0)
const NPC_STAND_TRAINER := Vector2(SHOP_ROOM_X + 372.0, BOTTOM_ROOM.position.y + 110.0)
## No gold rails inside combat. Rooms are separate shells.
const LANE_RAIL_YS: Array[float] = []
const LANE_RAIL_X0 := 0.0
const LANE_RAIL_X1 := 0.0
const LANE_RAIL_HALF_H := 0.0
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
	{"key": KEY_P, "label": "P", "desc": "仓库铺满脉冲", "row": 3, "fn": "_dev_place_pulses"},
	{"key": KEY_T, "label": "T", "desc": "+1脉冲仓库", "row": 4, "fn": "_dev_grant_pulse"},
	{"key": KEY_Y, "label": "Y", "desc": "炮台手", "row": 4, "fn": "_dev_toggle_turret_hand"},
	{"key": KEY_F, "label": "F", "desc": "锻造+1", "row": 4, "fn": "_dev_bump_forge"},
	{"key": KEY_N, "label": "N", "desc": "技能+1", "row": 4, "fn": "_dev_bump_skill"},
	{"key": KEY_BRACKETLEFT, "label": "[", "desc": "上一把", "row": 5, "fn": "_dev_prev_weapon"},
	{"key": KEY_BRACKETRIGHT, "label": "]", "desc": "下一把", "row": 5, "fn": "_dev_next_weapon"},
	{"key": KEY_H, "label": "H", "desc": "切换英雄", "row": 5, "fn": "_dev_toggle_hero"},
	{"key": KEY_M, "label": "M", "desc": "装上炮台", "row": 5, "fn": "_dev_mount_weapon"},
]

var scrap := 300
var core_health := 10
var current_wave := 0
var defeated_count := 0
var run_time := 0.0
var simulation_speed := 1.0

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
var _targeted_pickup: EmberPickup
var _warehouse_open := false
var _cell_towers: Dictionary = {}
var _wrecked_cells: Dictionary = {}
var _wreck_markers: Dictionary = {}
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
var _npc_summoner: Sprite2D
var _npc_mechanic: Sprite2D
var _npc_officer: Sprite2D
var _npc_keepers: Array[Sprite2D] = []
var _home_conveyors: Array[Sprite2D] = []
var _mech_level := 0
var _hero_armor := 0
var _hero_armor_max := 0
var _mass_wave := false
var _elite_spawned := false
var _npc_route_i := 0
var _npc_route_dir := 1
var _npc_dwell := 0.0
var _npc_job: StringName = &"route"
var _npc_job_shelf := 0
var _npc_restock_queue: Array[int] = []
var _shop_pen: Node2D
var _shelf_icons: Array[Sprite2D] = []
var _gate_open := 1.0
var _npc_anim := 0.0
var _hero_slot: Node2D
var _hero: EmberHero
var _camera: Camera2D
var _place_ghost: Sprite2D
var _place_fill: Polygon2D
var _place_stroke: Line2D
var _place_shadow: Polygon2D
var _place_preview_world := Vector2.INF
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
	_build_place_ghost()
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
	_shop_pen.expand_floors.append(TOP_ROOM)
	_shop_pen.expand_floors.append(BOTTOM_ROOM)
	_shop_pen.expand_floors.append(NORTH_HALL)
	_shop_pen.expand_floors.append(SOUTH_HALL)
	_shop_pen.expand_floors.append(ROAD_EAST)
	_shop_pen.expand_floors.append(ROAD_NORTH)
	_shop_pen.expand_floors.append(ROAD_SOUTH)
	_shop_pen.expand_floors.append(NORTH_THRESHOLD)
	_shop_pen.set("_grid_ox", FLOOR_GRID_OX)
	_shop_pen.set("_grid_oy", FLOOR_GRID_OY)
	_shop_pen.painted_floor = Rect2(0.0, COMBAT_ROOM.position.y, FLOOR_X_PIT, COMBAT_ROOM.size.y)
	_shop_pen.cover_voids = [
		Rect2(EAST_JOIN_X, -8.0, EAST_WALL_X - EAST_JOIN_X + 160.0, EAST_ROAD_Y0 + 8.0),
		Rect2(EAST_JOIN_X, EAST_ROAD_Y0 + EAST_ROAD_H, EAST_WALL_X - EAST_JOIN_X + 160.0, 800.0),
	]
	var wall_v: float = TILE_W
	var wall_h: float = float(_shop_pen.get("_wall_h"))
	var expand_left := FLOOR_GRID_OX + 18.0 * TILE_W
	var mouth_x1 := MOUTH_X0 + MOUTH_W
	var north_end_y := ROAD_NORTH.position.y - wall_h
	var south_end_y := ROAD_SOUTH.end.y
	var hole_w := 3.0 * TILE_W
	var hole_x := MOUTH_X0 + TILE_W
	_shop_pen.expand_h_walls = [
		Rect2(expand_left, NORTH_WALL.position.y, MOUTH_X0 - expand_left, wall_h),
		Rect2(mouth_x1, NORTH_WALL.position.y, EAST_JOIN_X - mouth_x1, wall_h),
		Rect2(expand_left, COMBAT_ROOM.end.y, MOUTH_X0 - expand_left, wall_h),
		Rect2(mouth_x1, COMBAT_ROOM.end.y, EAST_JOIN_X - mouth_x1, wall_h),
		Rect2(MOUTH_X0 - wall_v, north_end_y, hole_x - (MOUTH_X0 - wall_v), wall_h),
		Rect2(hole_x + hole_w, north_end_y, (mouth_x1 + wall_v) - (hole_x + hole_w), wall_h),
		Rect2(MOUTH_X0 - wall_v, south_end_y, hole_x - (MOUTH_X0 - wall_v), wall_h),
		Rect2(hole_x + hole_w, south_end_y, (mouth_x1 + wall_v) - (hole_x + hole_w), wall_h),
		Rect2(EAST_JOIN_X - wall_v, EAST_ROAD_Y0 - wall_h, EAST_WALL_X + 2.0 * TILE_W - (EAST_JOIN_X - wall_v), wall_h),
		Rect2(EAST_JOIN_X - wall_v, EAST_ROAD_Y0 + EAST_ROAD_H, EAST_WALL_X + 2.0 * TILE_W - (EAST_JOIN_X - wall_v), wall_h),
	]
	_shop_pen.expand_v_walls = [
		Rect2(MOUTH_X0 - wall_v, north_end_y, wall_v, NORTH_MOUTH.end.y - north_end_y),
		Rect2(mouth_x1, north_end_y, wall_v, NORTH_MOUTH.end.y - north_end_y),
		Rect2(MOUTH_X0 - wall_v, COMBAT_ROOM.end.y, wall_v, south_end_y + wall_h - COMBAT_ROOM.end.y),
		Rect2(mouth_x1, COMBAT_ROOM.end.y, wall_v, south_end_y + wall_h - COMBAT_ROOM.end.y),
		Rect2(EAST_JOIN_X - wall_v, NORTH_WALL.position.y, wall_v, EAST_ROAD_Y0 - NORTH_WALL.position.y),
		Rect2(EAST_JOIN_X - wall_v, EAST_ROAD_Y0 + EAST_ROAD_H, wall_v, 640.0 + wall_h - (EAST_ROAD_Y0 + EAST_ROAD_H)),
		Rect2(EAST_WALL_X, EAST_ROAD_Y0 - wall_h, wall_v, EAST_ROAD_H + wall_h * 2.0),
		Rect2(EAST_WALL_X + TILE_W, EAST_ROAD_Y0 - wall_h, wall_v, EAST_ROAD_H + wall_h * 2.0),
	]
	_shop_pen.extra_doors = [NORTH_MOUTH, SOUTH_MOUTH, SHOP_DOOR, SOUTH_SHOP_DOOR]
	_shop_pen.expand_v_walls.append(Rect2(NORTH_HALL.position.x - TILE_W, NORTH_HALL.position.y, TILE_W, NORTH_HALL.size.y + wall_h))
	_shop_pen.expand_v_walls.append(Rect2(NORTH_HALL.end.x, NORTH_HALL.position.y, TILE_W, NORTH_HALL.size.y + wall_h))
	_shop_pen.expand_v_walls.append(Rect2(SOUTH_HALL.position.x - TILE_W, SOUTH_HALL.position.y, TILE_W, SOUTH_HALL.size.y + wall_h))
	_shop_pen.expand_v_walls.append(Rect2(SOUTH_HALL.end.x, SOUTH_HALL.position.y, TILE_W, SOUTH_HALL.size.y + wall_h))
	_shop_pen.east_door = Rect2(EAST_WALL_X, EAST_HOLE_Y0, 2.0 * TILE_W, EAST_HOLE_Y1 - EAST_HOLE_Y0)
	_shop_pen.spawn_hole = Rect2()
	_shop_pen.portal_holes = [
		Rect2(hole_x, north_end_y, hole_w, wall_h),
		Rect2(hole_x, south_end_y, hole_w, wall_h),
	]
	_shop_pen.mouth_jambs = []
	_build_spawn_portals()
	_build_shelf_keepers()
	_build_shop_shelves()

func _build_spawn_portals() -> void:
	var wall_h: float = float(_shop_pen.get("_wall_h"))
	var mouth_mid := MOUTH_X0 + MOUTH_W * 0.5
	_make_spawn_portal("SpawnPortalNorth", Vector2(mouth_mid, ROAD_NORTH.position.y - wall_h * 0.5), 0.28)
	_make_spawn_portal("SpawnPortalNorthW", Vector2(MOUTH_X0 + MOUTH_W * 0.28, ROAD_NORTH.position.y - wall_h * 0.5), 0.24)
	_make_spawn_portal("SpawnPortalNorthE", Vector2(MOUTH_X0 + MOUTH_W * 0.72, ROAD_NORTH.position.y - wall_h * 0.5), 0.24)
	_make_spawn_portal("SpawnPortalSouth", Vector2(mouth_mid, ROAD_SOUTH.end.y + wall_h * 0.5), 0.28)
	_make_spawn_portal("SpawnPortalSouthW", Vector2(MOUTH_X0 + MOUTH_W * 0.28, ROAD_SOUTH.end.y + wall_h * 0.5), 0.24)
	_make_spawn_portal("SpawnPortalEast", Vector2(EAST_WALL_X + TILE_W, (EAST_HOLE_Y0 + EAST_HOLE_Y1) * 0.5), 0.36)
	_sync_spawn_portals()

func _make_spawn_portal(node_name: String, at: Vector2, visual_scale: float) -> void:
	var portal: Node2D = (load("res://scripts/spawn_portal.gd") as GDScript).new()
	portal.name = node_name
	portal.position = at
	portal.scale = Vector2(visual_scale, visual_scale)
	portal.z_index = 2
	add_child(portal)

func _spawn_holes_for_wave(wave: int) -> Array[Vector2]:
	var unlocked := mini(3 + int(floor(float(maxi(wave - 1, 0)) / 90.0)), 6)
	var all_holes: Array[Vector2] = [
		SPAWN_EAST, SPAWN_NORTH, SPAWN_SOUTH, SPAWN_NORTH_W, SPAWN_NORTH_E, SPAWN_SOUTH_W,
	]
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
			for i: int in range(mini(unlocked, all_holes.size())):
				holes.append(all_holes[i])
	# Cap by unlocked portal count (SK: +1 mouth every 90 waves up to 6).
	while holes.size() > unlocked:
		holes.pop_back()
	if holes.is_empty():
		holes.append(SPAWN_EAST)
	return holes

func _spawn_hole_label(hole: Vector2) -> String:
	if hole == SPAWN_NORTH or hole == SPAWN_NORTH_W or hole == SPAWN_NORTH_E:
		return "北"
	if hole == SPAWN_SOUTH or hole == SPAWN_SOUTH_W:
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
	_set_portal_lit("SpawnPortalNorthW", holes.has(SPAWN_NORTH_W))
	_set_portal_lit("SpawnPortalNorthE", holes.has(SPAWN_NORTH_E))
	_set_portal_lit("SpawnPortalSouth", holes.has(SPAWN_SOUTH))
	_set_portal_lit("SpawnPortalSouthW", holes.has(SPAWN_SOUTH_W))

func _set_portal_lit(node_name: String, lit: bool) -> void:
	var portal := find_child(node_name, true, false)
	if portal != null and portal.has_method("set_hole_active"):
		portal.call("set_hole_active", lit)
	if portal != null:
		# Red = active / Blue = idle sealed (SK portal color cue).
		portal.modulate = Color(1.15, 0.55, 0.45, 1.0) if lit else Color(0.55, 0.75, 1.15, 1.0)

func _build_shelf_keepers() -> void:
	for keeper: Sprite2D in _npc_keepers:
		if keeper != null and is_instance_valid(keeper):
			keeper.queue_free()
	_npc_keepers.clear()
	for npc: Sprite2D in [_npc_merchant, _npc_trainer, _npc_summoner, _npc_mechanic, _npc_officer]:
		if npc != null and is_instance_valid(npc):
			npc.queue_free()
	_npc_merchant = null
	_npc_trainer = null
	_npc_summoner = null
	_npc_mechanic = null
	_npc_officer = null
	_npc_restock_queue.clear()
	_npc_merchant = _make_npc("NpcMerchant", "res://assets/generated/npc/merchant.png", NPC_STAND_MERCHANT)
	_init_vendor_runner(_npc_merchant, &"merchant")
	_npc_mechanic = _make_npc("NpcMechanic", "res://assets/generated/npc/mechanic.png", NPC_STAND_MECHANIC)
	_init_vendor_runner(_npc_mechanic, &"mechanic")
	_npc_trainer = _make_npc("NpcTrainer", "res://assets/generated/npc/mentor.png", NPC_STAND_TRAINER)
	_init_vendor_runner(_npc_trainer, &"trainer")
	_npc_summoner = _make_npc("NpcSummoner", "res://assets/generated/npc/summoner.png", NPC_STAND_SUMMONER)
	_init_vendor_runner(_npc_summoner, &"summoner")
	_npc_officer = _make_npc("NpcOfficer", "res://assets/generated/npc/officer.png", NPC_STAND_OFFICER)
	# Officer is atmosphere / talk only — no restock route.
	_npc_officer.set_meta("vendor", &"officer")
	_npc_officer.set_meta("home_pos", NPC_STAND_OFFICER)
	_npc_officer.set_meta("job", &"idle")

func _build_shop_shelves() -> void:
	if _shop_pen != null and _shop_pen.get("shelf_spots") != null:
		_shop_pen.shelf_spots = SHOP_SHELVES.duplicate()
		_shop_pen.rail_ys = LANE_RAIL_YS.duplicate()
		_shop_pen.queue_redraw()
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
		icon.position = SHOP_SHELVES[index] + Vector2(0.0, -22.0)
		icon.z_index = 4
		icon.visible = false
		root.add_child(icon)
		_shelf_icons.append(icon)
	_build_home_conveyors()

func _build_home_conveyors() -> void:
	for old: Sprite2D in _home_conveyors:
		if old != null and is_instance_valid(old):
			old.queue_free()
	_home_conveyors.clear()
	var tex := _load_png_tex("res://assets/generated/ui/home-conveyor.png")
	if tex == null:
		return
	var root := Node2D.new()
	root.name = "HomeConveyors"
	root.z_index = 1
	add_child(root)
	for index: int in range(HOME_REWARD_SPOTS.size()):
		var pad := Sprite2D.new()
		pad.name = "HomeConveyor%d" % index
		pad.texture = tex
		pad.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pad.centered = true
		pad.position = HOME_REWARD_SPOTS[index] + Vector2(0.0, 8.0)
		pad.scale = Vector2(1.25, 1.25)
		pad.z_index = 2
		root.add_child(pad)
		_home_conveyors.append(pad)


func _load_png_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


func _make_npc(npc_name: String, texture_path: String, world_position: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = npc_name
	sprite.texture = _load_png_tex(texture_path)
	sprite.position = world_position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 2
	var folder := _npc_anim_folder(npc_name, texture_path)
	var idle_frames := _load_npc_frames("res://assets/generated/npc/%s/idle" % folder)
	var restock_frames := _load_npc_frames("res://assets/generated/npc/%s/restock" % folder)
	if not idle_frames.is_empty():
		sprite.texture = idle_frames[0]
	if sprite.texture != null:
		var height := float(sprite.texture.get_height())
		var fit := 92.0 / height if height > 1.0 else 1.0
		sprite.scale = Vector2(fit, fit)
	_plant_npc_feet(sprite)
	sprite.set_meta("rest_pos", world_position)
	sprite.set_meta("rest_scale", sprite.scale)
	sprite.set_meta("idle_frames", idle_frames)
	sprite.set_meta("restock_frames", restock_frames)
	sprite.set_meta("clip", &"idle")
	sprite.set_meta("frame_i", 0)
	sprite.set_meta("frame_t", 0.0)
	sprite.set_meta("npc_folder", folder)
	add_child(sprite)
	return sprite


func _npc_anim_folder(npc_name: String, texture_path: String) -> String:
	var key := "%s|%s" % [npc_name.to_lower(), texture_path.to_lower()]
	if key.contains("merchant"):
		return "merchant"
	if key.contains("summoner"):
		return "summoner"
	if key.contains("mechanic"):
		return "mechanic"
	if key.contains("officer"):
		return "officer"
	if key.contains("mentor") or key.contains("trainer"):
		return "mentor"
	return "mentor"


func _load_npc_frames(folder: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var index := 0
	while true:
		var path := "%s/frame_%02d.png" % [folder, index]
		var tex: Texture2D = null
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img != null and not img.is_empty():
				tex = ImageTexture.create_from_image(img)
		elif ResourceLoader.exists(path):
			tex = load(path) as Texture2D
		if tex == null:
			break
		frames.append(tex)
		index += 1
	return frames


func _start_npc_restock(npc: Sprite2D) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	var frames: Array = npc.get_meta("restock_frames", [])
	if frames.is_empty():
		return
	npc.set_meta("clip", &"restock")
	npc.set_meta("frame_i", 0)
	npc.set_meta("frame_t", 0.0)
	npc.texture = frames[0] as Texture2D


func _plant_npc_feet(npc: Sprite2D) -> void:
	if npc == null or npc.texture == null:
		return
	var height := float(npc.texture.get_height()) * npc.scale.y
	npc.centered = true
	npc.offset = Vector2(0.0, -height * 0.5)


func _on_shop_crate(point: Vector2) -> bool:
	for spot: Vector2 in SHOP_SHELVES:
		if Rect2(spot - Vector2(26.0, 20.0), Vector2(52.0, 40.0)).has_point(point):
			return true
	return false


func _shelf_stand(shelf_index: int) -> Vector2:
	var i := clampi(shelf_index, 0, SHOP_SHELVES.size() - 1)
	var spot := SHOP_SHELVES[i]
	# Restock stand is a step toward the vendor home (north of top shelves, south of bottom).
	var toward_home := -40.0 if spot.y < 300.0 else 40.0
	return spot + Vector2(0.0, toward_home)


func _vendor_shelf_list(vendor: StringName) -> Array[int]:
	var shelves: Array[int] = []
	for i: int in range(SHELF_VENDORS.size()):
		if SHELF_VENDORS[i] == vendor:
			shelves.append(i)
	return shelves


func _first_vendor_shelf(vendor: StringName) -> int:
	var shelves := _vendor_shelf_list(vendor)
	return shelves[0] if not shelves.is_empty() else 0


func _npc_for_vendor(vendor: StringName) -> Sprite2D:
	if vendor == &"trainer":
		return _npc_trainer
	if vendor == &"summoner":
		return _npc_summoner
	if vendor == &"mechanic":
		return _npc_mechanic
	if vendor == &"officer":
		return _npc_officer
	return _npc_merchant


func _init_vendor_runner(npc: Sprite2D, vendor: StringName) -> void:
	if npc == null:
		return
	var start := _first_vendor_shelf(vendor)
	var home: Vector2 = npc.get_meta("rest_pos", npc.position)
	npc.set_meta("vendor", vendor)
	npc.set_meta("home_pos", home)
	npc.set_meta("job", &"idle")
	npc.set_meta("job_shelf", start)
	npc.set_meta("route_i", start)
	npc.set_meta("route_dir", 1)
	npc.set_meta("dwell", 0.0)
	npc.set_meta("queue", [])


func _request_merchant_restock(shelf_index: int) -> void:
	_request_vendor_restock(shelf_index)


func _request_vendor_restock(shelf_index: int) -> void:
	var shelf := clampi(shelf_index, 0, SHOP_SHELVES.size() - 1)
	var npc := _npc_for_vendor(_shelf_vendor(shelf))
	if npc == null or not is_instance_valid(npc):
		return
	var job: StringName = npc.get_meta("job", &"idle")
	if (job == &"restock" or job == &"run_to") and int(npc.get_meta("job_shelf", -1)) == shelf:
		return
	if job == &"idle" or job == &"go_home" or job == &"route":
		npc.set_meta("job", &"run_to")
		npc.set_meta("job_shelf", shelf)
		npc.set_meta("dwell", 0.0)
		return
	var queue: Array = npc.get_meta("queue", [])
	if not queue.has(shelf):
		queue.append(shelf)
		npc.set_meta("queue", queue)


func _play_keeper_restock(shelf_index: int) -> void:
	_request_vendor_restock(shelf_index)


func _play_npc_restock(npc_id: StringName) -> void:
	_request_vendor_restock(_first_vendor_shelf(npc_id))


func _slot_shelf_index(slot_index: int) -> int:
	for shelf: int in range(SHOP_SHELVES.size()):
		if _shelf_slot_index(shelf) == slot_index:
			return shelf
	return -1


func _tick_merchant_runner(delta: float) -> void:
	_tick_vendor_runner(_npc_merchant, delta)
	_tick_vendor_runner(_npc_mechanic, delta)
	_tick_vendor_runner(_npc_trainer, delta)
	_tick_vendor_runner(_npc_summoner, delta)
	_animate_npc(_npc_officer, _npc_anim, 0.0)
	_bob_shelf_icons()


func _bob_shelf_icons() -> void:
	for index: int in range(_shelf_icons.size()):
		var icon := _shelf_icons[index]
		if icon == null or not is_instance_valid(icon) or not icon.visible:
			continue
		var base_y := SHOP_SHELVES[index].y - 22.0
		icon.position.x = SHOP_SHELVES[index].x
		icon.position.y = base_y + sin(_npc_anim * 3.4 + float(index) * 0.7) * 2.2


func _tick_vendor_runner(npc: Sprite2D, delta: float) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	if not is_shop_gate_open() or _is_game_over:
		_animate_npc(npc, _npc_anim, 0.0)
		return
	var vendor: StringName = npc.get_meta("vendor", &"merchant")
	var shelves := _vendor_shelf_list(vendor)
	if shelves.is_empty():
		_animate_npc(npc, _npc_anim, 0.0)
		return
	var job: StringName = npc.get_meta("job", &"idle")
	var home: Vector2 = npc.get_meta("home_pos", npc.get_meta("rest_pos", npc.position))
	if job == &"idle":
		npc.set_meta("rest_pos", home)
		_animate_npc(npc, _npc_anim, 0.0)
		return
	if job == &"restock":
		_animate_npc(npc, _npc_anim, 0.0)
		if npc.get_meta("clip", &"idle") != &"restock":
			var queue: Array = npc.get_meta("queue", [])
			if not queue.is_empty():
				npc.set_meta("job", &"run_to")
				npc.set_meta("job_shelf", int(queue.pop_front()))
				npc.set_meta("queue", queue)
				npc.set_meta("dwell", 0.0)
			else:
				# Bought and restocked — walk back to the stand beside their goods.
				npc.set_meta("job", &"go_home")
				npc.set_meta("dwell", 0.0)
		return
	if job == &"go_home":
		var pos_home: Vector2 = npc.get_meta("rest_pos", npc.position)
		var to_home := home - pos_home
		if to_home.length() > 3.0:
			var step_h := minf(NPC_RUN_SPEED * delta, to_home.length())
			pos_home += to_home.normalized() * step_h
			npc.set_meta("rest_pos", pos_home)
			npc.flip_h = to_home.x < -0.5
			_animate_npc(npc, _npc_anim, 0.0)
			return
		npc.set_meta("rest_pos", home)
		npc.set_meta("job", &"idle")
		_animate_npc(npc, _npc_anim, 0.0)
		return
	var route_i := int(npc.get_meta("route_i", shelves[0]))
	var target_shelf := int(npc.get_meta("job_shelf", route_i)) if job == &"run_to" else route_i
	if shelves.find(target_shelf) < 0:
		target_shelf = shelves[0]
	var target := _shelf_stand(target_shelf)
	var pos: Vector2 = npc.get_meta("rest_pos", npc.position)
	var to := target - pos
	if to.length() > 3.0:
		var step := minf(NPC_RUN_SPEED * delta, to.length())
		pos += to.normalized() * step
		npc.set_meta("rest_pos", pos)
		npc.flip_h = to.x < -0.5
		_animate_npc(npc, _npc_anim, 0.0)
		return
	npc.set_meta("rest_pos", target)
	if job == &"run_to":
		_start_npc_restock(npc)
		npc.set_meta("job", &"restock")
		npc.set_meta("route_i", target_shelf)
		_animate_npc(npc, _npc_anim, 0.0)
		return
	# Legacy route patrol — park at home instead of wandering.
	npc.set_meta("job", &"go_home")
	_animate_npc(npc, _npc_anim, 0.0)

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
	var zoom := camera_zoom_for(world_position).x
	var view := _active_view_size()
	var inset := _camera_hud_inset(world_position)
	var play_half := Vector2(
		maxf((view.x - inset.x - inset.z) / (zoom * 2.0), 80.0),
		maxf((view.y - inset.y - inset.w) / (zoom * 2.0), 80.0)
	)
	var bias := Vector2(inset.x - inset.z, inset.y - inset.w) * 0.5 / zoom
	var focus := _camera_focus_rect(world_position)
	var follow := world_position
	if focus.size.x > 1.0 and focus.size.y > 1.0:
		follow = Vector2(
			_clamp_camera_axis(world_position.x, focus.position.x, focus.end.x, play_half.x),
			_clamp_camera_axis(world_position.y, focus.position.y, focus.end.y, play_half.y)
		)
	return follow + bias

## Returns a light contextual zoom that keeps narrow dungeon spaces inside the viewport.
func camera_zoom_for(world_position: Vector2) -> Vector2:
	if _is_shop_interior(world_position) or SHOP_DOOR.has_point(world_position):
		return Vector2(CAMERA_SHOP_ZOOM, CAMERA_SHOP_ZOOM)
	if ROAD_NORTH.has_point(world_position) or ROAD_SOUTH.has_point(world_position) or ROAD_EAST.has_point(world_position):
		return Vector2(CAMERA_ROAD_ZOOM, CAMERA_ROAD_ZOOM)
	return Vector2.ONE

func _camera_focus_rect(world_position: Vector2) -> Rect2:
	if _is_shop_interior(world_position) or SHOP_DOOR.has_point(world_position):
		return _shop_shelf_focus_rect()
	if ROAD_NORTH.has_point(world_position):
		return ROAD_NORTH
	if ROAD_SOUTH.has_point(world_position):
		return ROAD_SOUTH
	if ROAD_EAST.has_point(world_position):
		return ROAD_EAST
	if COMBAT_ROOM.has_point(world_position) or HOME_HALL.has_point(world_position):
		return _combat_play_focus_rect(world_position)
	return Rect2()


## Five counters plus the price band above them — not the whole north room.
func _shop_shelf_focus_rect() -> Rect2:
	var bounds := Rect2()
	var started := false
	for spot: Vector2 in SHOP_SHELVES:
		var piece := Rect2(spot + Vector2(-42.0, -48.0), Vector2(84.0, 64.0))
		if started:
			bounds = bounds.merge(piece)
		else:
			bounds = piece
			started = true
	return bounds.grow(32.0)


## Keep the hero and nearby core in the playable hole so thumbs do not eat the lane.
func _combat_play_focus_rect(world_position: Vector2) -> Rect2:
	var pad := 90.0
	var bounds := Rect2(world_position - Vector2(pad, pad), Vector2(pad * 2.0, pad * 2.0))
	if world_position.distance_to(CORE_GLOW) < 420.0:
		var core := Rect2(CORE_GLOW - Vector2(70.0, 70.0), Vector2(140.0, 140.0))
		bounds = bounds.merge(core)
	return bounds


func _active_view_size() -> Vector2:
	if get_viewport() != null:
		var visible := get_viewport().get_visible_rect().size
		if visible.x > 1.0 and visible.y > 1.0:
			return visible
	return VIEW_SIZE


func _camera_hud_inset(world_position: Vector2) -> Vector4:
	var measured := Vector4(16.0, 64.0, 16.0, 48.0)
	if _hud != null and _hud.has_method("chrome_inset"):
		measured = _hud.chrome_inset()
	if _is_shop_interior(world_position) or SHOP_DOOR.has_point(world_position):
		var map_w := 176.0
		if _hud != null:
			var mini := _hud.get("_minimap") as Control
			if mini != null and mini.visible:
				map_w = maxf(mini.size.x + 16.0, 160.0)
		return Vector4(maxf(measured.x, 20.0), maxf(measured.y, 92.0), maxf(measured.z, map_w), 28.0)
	if COMBAT_ROOM.has_point(world_position) or HOME_HALL.has_point(world_position):
		return Vector4(maxf(measured.x, 28.0), maxf(measured.y, 64.0), maxf(measured.z, 28.0), 72.0)
	return measured

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
	_hud.skill_pressed.connect(_on_skill_or_interact)
	_hud.shop_slot_pressed.connect(buy_shop_slot)
	_hud.weapon_switch_pressed.connect(_cycle_hero_weapon)
	_hud.talk_pressed.connect(try_talk_to_nearby_npc)
	_hud.hero_kind_pressed.connect(_on_hero_kind_pressed)
	_hud.pickup_pressed.connect(_collect_targeted_pickup)
	_hud.discard_pressed.connect(_discard_targeted_pickup)
	_hud.warehouse_pressed.connect(_toggle_warehouse)
	_hud.warehouse_use_pressed.connect(_use_warehouse_item)
	_sync_weapon_hud()
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.clear_tower_info()
	_hud.set_hero_state("待命")
	_hud.set_hero_hp(100, 100)
	_sync_skill_hud()

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
			if _spawn_remaining == 0 and (not _needs_boss() or _boss_spawned) and (not _needs_elite() or _elite_spawned) and _enemies.is_empty():
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
		_sync_skill_hud()
		var enemy_dots: Array[Vector2] = []
		for enemy: FrontierEnemy in _enemies:
			if enemy != null and is_instance_valid(enemy):
				enemy_dots.append(enemy.position)
		var tower_dots: Array[Vector2] = []
		for tower: EmberTower in _towers:
			if tower != null and is_instance_valid(tower):
				tower_dots.append(tower.position)
		var npc_dots: Array[Vector2] = []
		for npc: Sprite2D in [_npc_merchant, _npc_mechanic, _npc_trainer, _npc_summoner, _npc_officer]:
			if npc != null and is_instance_valid(npc) and npc.visible:
				npc_dots.append(npc.position)
		_hud.update_minimap(
			_hero.position,
			CORE_GLOW,
			tower_dots,
			SHOP_ROOM,
			SHOP_DOOR,
			COMBAT_ROOM,
			HOME_HALL,
			enemy_dots,
			is_shop_gate_open(),
			SHOP_SHELVES,
			npc_dots
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
	_tick_merchant_runner(delta)
	if _hero != null:
		_hero.position = _separate_from_npcs(_hero.position)
	_sync_place_preview()
	_update_rebuild_prompt()
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
		return
	if _needs_elite() and not _elite_spawned:
		if get_active_enemies().size() >= LIVE_ENEMY_CAP:
			return
		_spawn_elite()
		_elite_spawned = true
		return

func _needs_boss() -> bool:
	# SK-ish: big boss every 15 waves; wave 5/10 still get a mini elite pack via `_needs_elite`.
	return current_wave > 0 and current_wave % 15 == 0


func _needs_elite() -> bool:
	return current_wave > 0 and current_wave % 5 == 0 and current_wave % 15 != 0


func _is_mass_wave(wave: int = -1) -> bool:
	var w := current_wave if wave < 0 else wave
	var mod := w % 10
	return mod == 3 or mod == 8

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
	if slot % 5 == 4 and current_wave >= 2:
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


func _spawn_elite() -> void:
	var enemy := FrontierEnemy.new()
	enemy.variant = &"brute"
	enemy.max_health = 180 + current_wave * 28
	enemy.move_speed = 34.0 + float(current_wave) * 2.2
	enemy.reward = 55 + current_wave * 6
	enemy.contact_damage = 18
	enemy.core_damage = 1
	enemy.configure_seek(_random_spawn_point(), core_goal(), self)
	_register_enemy(enemy)
	_hud.update_status("精英重装出现  /  注意集火")

func _register_enemy(enemy: FrontierEnemy) -> void:
	enemy.reached_base.connect(_on_enemy_reached_base)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.hit.connect(_on_enemy_hit)
	enemy.shot_fired.connect(_on_enemy_shot_fired)
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
		_request_merchant_restock(0)
		_request_vendor_restock(_first_vendor_shelf(&"trainer"))
	_hud.set_wave_button_enabled(true, "提前开战")
	_hud.set_shop_countdown(_director.prep_duration)
	_sync_spawn_portals()
	_hud.update_status("客厅已开放  /  下波 %s洞出怪  /  点柜台购买" % _spawn_hole_status(upcoming_wave))
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
	if _is_mass_wave(current_wave):
		_spawn_remaining = int(ceil(float(_spawn_remaining) * 1.55))
		_mass_wave = true
	else:
		_mass_wave = false
	_spawned_in_wave = 0
	_spawn_timer = 0.1
	_boss_spawned = false
	_elite_spawned = false
	_hud.set_wave_button_enabled(false, "第 %02d 波进行中" % current_wave)
	_eject_hero_from_shop()
	_sync_spawn_portals()
	var tag := "潮汐波" if _mass_wave else ("Boss波" if _needs_boss() else ("精英波" if _needs_elite() else "作战"))
	_hud.update_status("%s  /  第 %02d 波  /  %s洞" % [tag, current_wave, _spawn_hole_status(current_wave)])
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
				_spawn_world_pickup(&"heal", &"heal", "res://assets/generated/ui/home-potion.png", 0.70, spot + Vector2(0.0, -18.0), 0, EmberPickup.LIFETIME)
			&"weapon":
				var weapon_id: StringName = spec["payload"]
				var weapon := WeaponCatalog.get_def(weapon_id)
				_spawn_world_pickup(
					&"weapon",
					weapon_id,
					String(weapon.get("pickup_path", "res://assets/generated/ui/scrap.png")),
					0.42,
					spot + Vector2(0.0, -18.0),
					0,
					EmberPickup.LIFETIME
				)
			_:
				_spawn_world_pickup(
					&"scrap",
					&"scrap",
					"res://assets/generated/ui/scrap.png",
					0.38,
					spot + Vector2(0.0, -18.0),
					int(spec.get("amount", 10)),
					EmberPickup.LIFETIME
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
	pickup.expired.connect(_on_pickup_expired)
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
	var live: Array[EmberPickup] = []
	for pickup in _pickups:
		if is_instance_valid(pickup):
			live.append(pickup)
	_pickups = live
	if _hero == null or _hero.is_down:
		_set_targeted_pickup(null)
		return
	var nearest: EmberPickup = null
	var nearest_d := EmberPickup.INTERACT_RADIUS
	for pickup: EmberPickup in live:
		var dist := pickup.global_position.distance_to(_hero.global_position)
		if dist < nearest_d:
			nearest = pickup
			nearest_d = dist
	_set_targeted_pickup(nearest)

func _set_targeted_pickup(pickup: EmberPickup) -> void:
	if _targeted_pickup == pickup:
		if _hud != null:
			_hud.set_pickup_actions(pickup != null and is_instance_valid(pickup))
		return
	if is_instance_valid(_targeted_pickup):
		_targeted_pickup.set_targeted(false)
	_targeted_pickup = pickup
	if is_instance_valid(_targeted_pickup):
		_targeted_pickup.set_targeted(true)
	if _hud != null:
		_hud.set_pickup_actions(is_instance_valid(_targeted_pickup))

func _collect_targeted_pickup() -> void:
	if is_instance_valid(_targeted_pickup):
		_collect_world_pickup(_targeted_pickup)

func _discard_targeted_pickup() -> void:
	if is_instance_valid(_targeted_pickup):
		_targeted_pickup.stash_away()

func _collect_world_pickup(pickup: EmberPickup) -> void:
	if pickup == null or not is_instance_valid(pickup):
		return
	if _hero == null or _hero.is_down:
		return
	pickup.collect_now()

func _try_click_pickup(world_position: Vector2) -> bool:
	var best: EmberPickup = null
	var best_d := EmberPickup.CLICK_RADIUS
	for pickup: EmberPickup in _pickups:
		if not is_instance_valid(pickup):
			continue
		var dist := pickup.global_position.distance_to(world_position)
		if dist < best_d:
			best = pickup
			best_d = dist
	if best == null:
		return false
	_collect_world_pickup(best)
	return true

func _on_pickup_expired(pickup: EmberPickup) -> void:
	if _targeted_pickup == pickup:
		_set_targeted_pickup(null)
	_pickups.erase(pickup)
	_stash_pickup_payload(pickup)
	if _hud != null:
		_hud.update_status("地上物资已收入仓库")
	_refresh_warehouse_hud()

func _stash_pickup_payload(pickup: EmberPickup) -> void:
	if _hero == null or pickup == null:
		return
	match pickup.pickup_kind:
		&"scrap":
			_hero.item_stash["scrap"] = int(_hero.item_stash.get("scrap", 0)) + maxi(pickup.scrap_value, 0)
		&"heal":
			_hero.item_stash["heal"] = int(_hero.item_stash.get("heal", 0)) + 1
		&"skill":
			_hero.unlock_dash()
		_:
			var weapons: Array = _hero.item_stash.get("weapons", [])
			weapons.append(String(pickup.payload))
			_hero.item_stash["weapons"] = weapons

func _toggle_warehouse() -> void:
	_warehouse_open = not _warehouse_open
	_refresh_warehouse_hud()

func _refresh_warehouse_hud() -> void:
	if _hud == null:
		return
	_hud.set_warehouse(_warehouse_open, _warehouse_rows())

func _warehouse_rows() -> Array:
	var rows: Array = []
	if _hero == null:
		return rows
	var scrap_n := int(_hero.item_stash.get("scrap", 0))
	if scrap_n > 0:
		rows.append({
			"kind": &"scrap",
			"title": "废料 +%d" % scrap_n,
			"icon": "res://assets/generated/ui/scrap.png",
			"index": 0,
			"payload": &"",
		})
	var heal_n := int(_hero.item_stash.get("heal", 0))
	if heal_n > 0:
		rows.append({
			"kind": &"heal",
			"title": "药剂 x%d" % heal_n,
			"icon": "res://assets/generated/weapons/red-potion.png",
			"index": 0,
			"payload": &"heal",
		})
	var weapons: Array = _hero.item_stash.get("weapons", [])
	for index: int in range(weapons.size()):
		var weapon_id := StringName(String(weapons[index]))
		var weapon := WeaponCatalog.get_def(weapon_id)
		rows.append({
			"kind": &"weapon",
			"title": String(weapon.get("display_name", weapon_id)),
			"icon": String(weapon.get("pickup_path", "")),
			"index": index,
			"payload": weapon_id,
		})
	for kind: StringName in [&"pulse", &"burst", &"frost"]:
		var count := _hero.turret_kind_count(kind)
		if count <= 0:
			continue
		var icon := "res://assets/generated/towers/tower-lv1.png"
		if kind == &"burst":
			icon = "res://assets/generated/towers/burst-lv1.png"
		elif kind == &"frost":
			icon = "res://assets/generated/towers/frost-lv1.png"
		rows.append({
			"kind": &"tower",
			"title": "%s x%d" % [EmberTower.kind_display_name(kind, 1), count],
			"icon": icon,
			"index": 0,
			"payload": kind,
		})
	return rows

func _use_warehouse_item(kind: StringName, index: int, payload: StringName) -> void:
	if _hero == null:
		return
	match kind:
		&"scrap":
			var amount := int(_hero.item_stash.get("scrap", 0))
			if amount <= 0:
				return
			scrap += amount
			_hero.item_stash["scrap"] = 0
			_hud.update_stats(scrap, core_health, current_wave)
			_hud.update_status("仓库取出废料  /  +%d" % amount)
		&"heal":
			var left := int(_hero.item_stash.get("heal", 0))
			if left <= 0:
				return
			_hero.heal_percent(0.20)
			_hero.item_stash["heal"] = left - 1
			_hud.update_status("仓库使用药剂  /  恢复 20% 生命")
		&"weapon":
			var bag: Array = _hero.item_stash.get("weapons", [])
			if index < 0 or index >= bag.size():
				return
			var weapon_id := StringName(String(bag[index]))
			bag.remove_at(index)
			_hero.item_stash["weapons"] = bag
			var displaced := &""
			if _hero.weapon_slots.find(weapon_id) < 0 and _hero.weapon_slots.find(&"") < 0:
				displaced = _hero.combat_weapon_id()
			_hero.equip_weapon(weapon_id)
			if displaced != &"":
				var stored: Array = _hero.item_stash.get("weapons", [])
				stored.append(String(displaced))
				_hero.item_stash["weapons"] = stored
			_sync_weapon_hud()
			_hud.update_status("仓库装备%s" % String(WeaponCatalog.get_def(weapon_id).get("display_name", weapon_id)))
		&"tower":
			if payload != &"":
				_hero.set_turret_hand(true)
				_sync_weapon_hud()
				_hud.update_status("手持炮台  /  点击地砖放下")
	_refresh_warehouse_hud()

func _on_pickup_collected(pickup: EmberPickup) -> void:
	if _targeted_pickup == pickup:
		_set_targeted_pickup(null)
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
		_hud.update_status("冲刺已解锁")
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
	for enemy: FrontierEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		if not bool(enemy.get("_aggro")):
			continue
		if enemy.consume_contact_hit():
			if _hero.global_position.distance_to(enemy.global_position) <= 48.0:
				_hero.take_damage(enemy.contact_damage)
		if _contact_timer > 0.0:
			continue
		if _hero.global_position.distance_to(enemy.global_position) <= 26.0:
			enemy.play_attack(_hero.global_position - enemy.global_position)
			_contact_timer = CONTACT_INTERVAL

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
	var weapon_id := StringName(weapon.get("id", &"sword"))
	var forge := weapon_forge_mult(weapon_id) * amplifier_damage_mult(origin)
	projectile.configure(
		direction,
		maxi(1, int(round(float(weapon["damage"]) * forge))),
		float(weapon["speed"]),
		float(weapon["max_range"]),
		float(weapon["falloff_range"]),
		maxi(1, int(round(float(weapon["falloff_damage"]) * forge))),
		self,
		texture_path,
		float(weapon.get("fx_scale", 0.40)),
		float(weapon.get("hit_radius", 16.0))
	)
	_register_live_bullet(projectile)
	projectile.global_position = origin
	projectile.visible = true
	projectile.set_process(true)
	EmberHitStop.punch_ranged(get_tree())

func spawn_enemy_projectile(origin: Vector2, direction: Vector2, damage: int) -> void:
	var projectile := _acquire_enemy_bullet()
	projectile.z_index = 5
	projectile.configure(direction, damage, self)
	_register_live_bullet(projectile)
	projectile.global_position = origin
	projectile.visible = true
	projectile.set_process(true)

func _on_enemy_shot_fired(enemy: FrontierEnemy, direction: Vector2, damage: int) -> void:
	if not is_instance_valid(enemy) or _hero == null or _hero.is_down:
		return
	spawn_enemy_projectile(enemy.global_position + Vector2(0.0, -28.0), direction, damage)

func hurt_hero(amount: int, at: Vector2 = Vector2.ZERO) -> void:
	if _hero == null or _hero.is_down:
		return
	var dmg := maxi(amount, 0)
	if _hero_armor > 0 and dmg > 0:
		_hero_armor -= 1
		_sync_hero_armor_hud()
		dmg = maxi(dmg - 8, 0)
		if dmg <= 0:
			spawn_hit_effect(at if at != Vector2.ZERO else _hero.global_position, 0.12)
			return
	_hero.take_damage(dmg)
	var fx_at := at if at != Vector2.ZERO else _hero.global_position
	spawn_hit_effect(fx_at, 0.16)

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

func _acquire_enemy_bullet() -> EnemyProjectile:
	_recycle_oldest_if_full()
	var idle := _take_idle_of_class("EnemyProjectile")
	if idle is EnemyProjectile:
		return idle as EnemyProjectile
	return EnemyProjectile.new()

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
		if type_name == "EnemyProjectile" and candidate is EnemyProjectile:
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

func weapon_forge_mult(weapon_id: StringName) -> float:
	if _hero == null:
		return 1.0
	return _hero.forge_damage_mult(weapon_id)


func clear_enemy_bullets_in_radius(origin: Vector2, radius: float) -> int:
	var cleared := 0
	var victims: Array = []
	for bullet in _live_bullets:
		if bullet == null or not is_instance_valid(bullet):
			continue
		if not (bullet is EnemyProjectile):
			continue
		if (bullet as Node2D).global_position.distance_to(origin) <= radius:
			victims.append(bullet)
	for bullet in victims:
		spawn_hit_effect((bullet as Node2D).global_position, 0.14, 0.18)
		recycle_bullet(bullet)
		cleared += 1
	return cleared


func regen_hero_dash(amount: float) -> void:
	if _hero == null or _hero.is_down:
		return
	_hero.dash_cooldown_left = maxf(_hero.dash_cooldown_left - amount, 0.0)
	_sync_skill_hud()


func amplifier_damage_mult(at: Vector2) -> float:
	var mult := 1.0
	for tower: EmberTower in _towers:
		if tower == null or not is_instance_valid(tower) or not tower.is_facility():
			continue
		if tower.kind != &"amplifier":
			continue
		if at.distance_to(tower.global_position) <= tower.attack_range:
			mult = maxf(mult, tower.damage_mult_aura())
	return mult


func repair_all_mechs() -> int:
	var repaired := 0
	for tower: EmberTower in _towers:
		if tower == null or not is_instance_valid(tower):
			continue
		if tower.health < tower.max_health:
			tower.health = tower.max_health
			tower.queue_redraw()
			repaired += 1
	_mech_level += 1
	return repaired


func notify_hero_defeated() -> void:
	if _is_game_over:
		return
	_hud.update_status("英雄阵亡  /  防线崩溃")
	_end_run(&"hero")


func _on_hero_attacked(origin: Vector2, facing: int) -> void:
	var weapon_id := _hero.combat_weapon_id() if _hero != null else &"sword"
	var weapon := WeaponCatalog.get_def(weapon_id)
	var amount := _hero.melee_strike_damage() if _hero != null else int(weapon["damage"])
	amount = maxi(1, int(round(float(amount) * amplifier_damage_mult(origin))))
	var reach := float(weapon.get("max_range", 118.0))
	clear_enemy_bullets_in_radius(origin, reach)
	var target := _find_hero_target(origin, facing, reach)
	_spawn_melee_slash(origin, facing, weapon)
	if target == null:
		return
	target.take_damage(amount, &"hero")
	EmberHitStop.punch_melee(get_tree())


func apply_clone_melee(origin: Vector2, facing: int) -> void:
	if _hero == null:
		return
	var weapon := WeaponCatalog.get_def(&"sword")
	var reach := float(weapon.get("max_range", 118.0))
	clear_enemy_bullets_in_radius(origin, reach)
	var target := _find_hero_target(origin, facing, reach)
	_spawn_melee_slash(origin, facing, weapon)
	if target == null:
		return
	var amount := maxi(1, int(round(float(_hero.melee_strike_damage()) * amplifier_damage_mult(origin))))
	target.take_damage(amount, &"hero")

func _spawn_melee_slash(origin: Vector2, facing: int, weapon: Dictionary) -> void:
	var fx_path := String(weapon.get("fx_path", ""))
	if fx_path.is_empty():
		return
	var slash := ImpactEffect.new()
	slash.name = "MeleeSlash"
	slash.z_as_relative = false
	slash.z_index = 20
	var host: Sprite2D = null
	if _hero != null and _hero.has_method("float_sprite_near"):
		host = _hero.call("float_sprite_near", origin) as Sprite2D
	var tilt := 0.0
	if _hero != null and _hero.has_method("slash_swing_tilt_near"):
		tilt = float(_hero.call("slash_swing_tilt_near", origin))
	if host != null:
		host.add_child(slash)
		# Signed-off: sit on the float sword, draw in front, stay world-flat 0/PI.
		# Following the blade tilt (~66°) smears the arc under the sword.
		slash.position = Vector2(16.0, 0.0)
		slash.global_rotation = 0.0 if facing > 0 else PI
	else:
		add_child(slash)
		slash.position = origin + Vector2(float(facing) * 16.0, 0.0)
		slash.rotation = 0.0 if facing > 0 else PI
	slash.configure(float(weapon.get("fx_scale", 0.55)), 0.16, fx_path, false)

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
	flash.configure(0.95, 0.14, "res://assets/generated/fx/muzzle.png")

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

func _end_run(reason: StringName = &"core") -> void:
	_is_game_over = true
	_wave_active = false
	_close_talk()
	scrap += _shop.close_and_refund()
	EmberRunSave.update_records(current_wave, defeated_count, run_time)
	EmberRunSave.delete_run()
	_hud.set_npc_prompt(false, Vector2.ZERO)
	var title := "英雄阵亡" if reason == &"hero" else "核心失守"
	_hud.show_end_screen(false, defeated_count, current_wave, run_time, title)
	_hud.update_status("%s  /  最高波次 %d" % [title, current_wave])

func buy_shop_slot(index: int) -> void:
	if _is_game_over or not _shop.is_open:
		return
	var weapon_id := _hero.combat_weapon_id() if _hero != null else &"sword"
	var result := _shop.buy(
		index,
		scrap,
		_hero.forge_level_for(weapon_id) if _hero != null else 0,
		_hero.skill_level_for(_hero.hero_kind) if _hero != null else 0,
		_hero.hero_kind if _hero != null else &"ember_hero"
	)
	_hud.update_status(String(result["message"]))
	if not bool(result["ok"]):
		return
	scrap -= int(result["cost"])
	match result["kind"]:
		&"weapon":
			_hero.equip_weapon(result["payload"])
			_sync_weapon_hud()
		&"tower":
			_hero.add_turret(result["payload"])
			_sync_weapon_hud()
		&"forge":
			var forged := _hero.combat_weapon_id()
			if forged != &"":
				_hero.apply_forge_upgrade(forged)
				_refresh_forged_towers(forged)
		&"skill":
			_hero.apply_skill_upgrade()
		&"vitality":
			_apply_vitality_purchase(StringName(result["payload"]))
		&"mech_repair":
			var n := repair_all_mechs()
			_hud.update_status("机械修复  /  恢复 %d 座" % n)
		&"summon":
			_resolve_summoner_roll()
		&"half_price":
			pass
	## Restock runs to the bought pedestal (not a random first shelf), plays clip, returns home.
	var shelf := _slot_shelf_index(index)
	if shelf >= 0:
		_play_keeper_restock(shelf)
	else:
		var vendor: StringName = &"merchant"
		var kind: StringName = result["kind"]
		if kind == &"forge" or kind == &"skill" or kind == &"vitality":
			vendor = &"trainer"
		elif kind == &"mech_repair":
			vendor = &"mechanic"
		elif kind == &"summon" or kind == &"half_price":
			vendor = &"summoner"
		_play_npc_restock(vendor)
	_sync_trainer_counters()
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.set_hero_hp(_hero.health, _hero.max_health, _hero.is_down)
	_sync_hero_armor_hud()
	_refresh_shop_ui()


func _apply_vitality_purchase(payload: StringName) -> void:
	if _hero == null:
		return
	match payload:
		&"energy":
			_hero.apply_dash_cd_upgrade()
			_hero.dash_cooldown_left = 0.0
			_sync_skill_hud()
		&"shield":
			_hero_armor_max += 1
			_hero_armor = _hero_armor_max
			_sync_hero_armor_hud()
		_:
			_hero.apply_vitality_upgrade()


func _resolve_summoner_roll() -> void:
	var roll := _drop_rng.randf()
	if roll < 0.35:
		scrap += 40
		_hud.update_status("召唤师  /  废料矿 +40")
	elif roll < 0.60:
		if _hero != null:
			_hero.heal_percent(0.35)
		_hud.update_status("召唤师  /  回复药剂")
	elif roll < 0.80:
		scrap += 80
		_hud.update_status("召唤师  /  金矿 +80")
	else:
		# Bomb hazard near hero — small self damage unless armored.
		hurt_hero(12, _hero.global_position if _hero != null else Vector2.ZERO)
		_hud.update_status("召唤师  /  炸出意外！")


func _sync_hero_armor_hud() -> void:
	if _hud != null and _hud.has_method("set_hero_armor"):
		_hud.call("set_hero_armor", _hero_armor, _hero_armor_max)

func _shop_wave() -> int:
	if _director != null and _director.is_prep():
		return _director.upcoming_wave()
	return maxi(current_wave, 1)

func _sync_trainer_counters() -> void:
	if _shop == null or _hero == null:
		return
	_shop.sync_trainer(
		_hero.combat_weapon_id(),
		_hero.forge_level_for(_hero.combat_weapon_id()),
		_hero.hero_kind,
		_hero.skill_level_for(_hero.hero_kind),
		_shop_wave(),
		_shop.vitality_level,
		_mech_level
	)

func _refresh_forged_towers(weapon_id: StringName) -> void:
	for tower: EmberTower in _towers:
		if tower != null and is_instance_valid(tower) and tower.weapon_id == weapon_id:
			tower.refresh_weapon_stats()

func _refresh_shop_stock(upcoming_wave: int) -> int:
	if _hero == null:
		return _shop.refresh(upcoming_wave)
	return _shop.refresh(
		upcoming_wave,
		_hero.combat_weapon_id(),
		_hero.forge_level_for(_hero.combat_weapon_id()),
		_hero.hero_kind,
		_hero.skill_level_for(_hero.hero_kind)
	)

func _hold_hint_text() -> String:
	if _hero == null:
		return ""
	if _hero.turret_hand:
		var kind := _hero.current_turret_kind()
		if kind == &"":
			return ""
		return "手持炮台：%s x%d — 点击地砖放下" % [
			EmberTower.kind_display_name(kind, 1),
			_hero.turret_kind_count(kind),
		]
	return ""

func _refresh_shop_ui() -> void:
	var talking := _talking_npc
	var shop_open := _shop.is_open and not _is_game_over and _vendor_opens_shop(talking)
	_sync_trainer_counters()
	_hud.set_shop_slots(_shop.slots, scrap, talking)
	_hud.show_shop(shop_open, talking)
	_hud.set_hold_hint(_hold_hint_text())
	if _npc_merchant != null and is_instance_valid(_npc_merchant):
		_npc_merchant.visible = true
	_refresh_shop_shelves()

func _refresh_shop_shelves() -> void:
	var sold_flags: Array[bool] = []
	var filled_flags: Array[bool] = []
	var captions: Array[String] = []
	for index: int in range(SHOP_SHELVES.size()):
		sold_flags.append(false)
		filled_flags.append(false)
		captions.append("")
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
		if icon.texture != null:
			var longest := maxf(float(icon.texture.get_width()), float(icon.texture.get_height()))
			var shown := longest * icon.scale.x
			if shown > 40.0 and longest > 1.0:
				var fit := 40.0 / longest
				icon.scale = Vector2(fit, fit)
		var title := String(slot.get("title", ""))
		var cost := int(slot.get("cost", 0))
		captions[index] = "%s %d" % [title, cost] if not sold else "%s 已售" % title
	if _shop_pen != null:
		if _shop_pen.has_method("apply_shelf_state"):
			_shop_pen.call("apply_shelf_state", sold_flags, filled_flags, captions)
		else:
			_shop_pen.set("shelf_sold", sold_flags)
			_shop_pen.set("shelf_filled", filled_flags)
			_shop_pen.set("shelf_captions", captions)
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

func _nearest_shelf_index() -> int:
	if _hero == null or _shop == null or not is_shop_gate_open() or not _shop.is_open or _is_game_over:
		return -1
	var best := -1
	var best_d := LEAVE_RADIUS
	for index: int in range(SHOP_SHELVES.size()):
		var dist := _hero.position.distance_to(SHOP_SHELVES[index])
		if dist <= best_d:
			best_d = dist
			best = index
	return best

func _on_skill_or_interact() -> void:
	var shelf := _nearest_shelf_index()
	if shelf >= 0:
		_try_buy_shelf(SHOP_SHELVES[shelf])
		return
	if is_instance_valid(_targeted_pickup):
		_collect_targeted_pickup()
		return
	var mount_tower := _nearby_mount_tower()
	if mount_tower != null:
		_mount_or_swap_weapon(mount_tower)
		return
	_play_dash()

func _on_hero_state_changed(next_state: StringName) -> void:
	_hero_state = next_state
	_hud.set_hero_state(_hero_state_display_name(next_state))

func _on_hero_health_changed(current: int, maximum: int) -> void:
	_hud.set_hero_hp(current, maximum, _hero.is_down)

func _on_hero_downed() -> void:
	_hud.set_hero_hp(0, _hero.max_health, true)
	_hud.update_status("英雄阵亡  /  防线崩溃")

func _on_hero_revived() -> void:
	# Kept for save/dev edge cases; normal play ends on down.
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
			return "影分身" if _hero != null and _hero.hero_kind == &"assassin" else "冲刺"
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
		if _hero != null and _hero.position.distance_to(SHOP_SHELVES[index]) > LEAVE_RADIUS:
			_hud.update_status("走近柜台再买")
			return true
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
	if _try_click_pickup(click_position):
		return
	_try_place_tower(click_position)

func _cell_at(world_position: Vector2) -> Vector2i:
	return Vector2i(
		int(floor((world_position.x - FLOOR_GRID_OX) / TILE_W)),
		int(floor((world_position.y - FLOOR_GRID_OY) / TILE_H))
	)

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(FLOOR_GRID_OX + (float(cell.x) + 0.5) * TILE_W, FLOOR_GRID_OY + (float(cell.y) + 0.5) * TILE_H)

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(FLOOR_GRID_OX + float(cell.x) * TILE_W, FLOOR_GRID_OY + float(cell.y) * TILE_H, TILE_W, TILE_H)


func _build_place_ghost() -> void:
	var root := Node2D.new()
	root.name = "PlacePreview"
	root.z_index = 3
	add_child(root)
	_place_fill = Polygon2D.new()
	_place_fill.name = "PlaceFill"
	_place_fill.visible = false
	root.add_child(_place_fill)
	_place_stroke = Line2D.new()
	_place_stroke.name = "PlaceStroke"
	_place_stroke.width = 2.0
	_place_stroke.closed = true
	_place_stroke.joint_mode = Line2D.LINE_JOINT_SHARP
	_place_stroke.visible = false
	root.add_child(_place_stroke)
	_place_shadow = Polygon2D.new()
	_place_shadow.name = "PlaceShadow"
	_place_shadow.color = Color(0.01, 0.02, 0.06, 0.55)
	_place_shadow.visible = false
	root.add_child(_place_shadow)
	_place_ghost = Sprite2D.new()
	_place_ghost.name = "PlaceGhost"
	_place_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_place_ghost.centered = true
	_place_ghost.visible = false
	_place_ghost.modulate = Color(1.0, 1.0, 1.0, 0.78)
	root.add_child(_place_ghost)


func _place_preview_world_pos() -> Vector2:
	if _place_preview_world.is_finite():
		return _place_preview_world
	return get_global_mouse_position()


func _can_place_preview() -> bool:
	if _is_game_over:
		return false
	return _hero != null and _hero.turret_hand and _hero.turret_stash_count() > 0


func _place_preview_spec() -> Dictionary:
	var kind: StringName = _hero.current_turret_kind() if _hero != null else &"pulse"
	var path := ""
	match kind:
		&"burst":
			path = "res://assets/generated/towers/burst-lv1.png"
		&"frost":
			path = "res://assets/generated/towers/frost-lv1.png"
		_:
			path = "res://assets/generated/towers/tower-lv1.png"
	return {"path": path, "scale": 0.48}


func _hide_place_preview() -> void:
	if _place_ghost != null:
		_place_ghost.visible = false
	if _place_fill != null:
		_place_fill.visible = false
	if _place_stroke != null:
		_place_stroke.visible = false
	if _place_shadow != null:
		_place_shadow.visible = false


func _sync_place_preview() -> void:
	if _place_ghost == null:
		return
	if not _can_place_preview():
		_hide_place_preview()
		return
	var cell := _cell_at(_place_preview_world_pos())
	if not _cell_is_buildable(cell):
		_hide_place_preview()
		return
	var spec := _place_preview_spec()
	var tex := load(String(spec["path"])) as Texture2D if String(spec["path"]) != "" else null
	_place_ghost.texture = tex
	if tex == null:
		_hide_place_preview()
		return
	var hover_rect := _cell_rect(cell)
	var corners: PackedVector2Array = PackedVector2Array([
		hover_rect.position,
		Vector2(hover_rect.end.x, hover_rect.position.y),
		hover_rect.end,
		Vector2(hover_rect.position.x, hover_rect.end.y),
	])
	var holding := _hero != null and _hero.turret_hand and _hero.turret_stash_count() > 0
	_place_fill.polygon = corners
	_place_fill.color = Color(0.98, 0.82, 0.32, 0.28) if holding else Color(0.83, 0.69, 0.42, 0.16)
	_place_fill.visible = true
	_place_stroke.points = corners
	_place_stroke.default_color = Color(0.98, 0.82, 0.32, 0.95) if holding else Color(0.83, 0.69, 0.42, 0.70)
	_place_stroke.width = 2.0 if holding else 1.0
	_place_stroke.visible = true
	var center := _cell_center(cell)
	var shadow_pts: PackedVector2Array = PackedVector2Array()
	for index: int in range(20):
		var angle := TAU * float(index) / 20.0
		shadow_pts.append(center + Vector2(cos(angle) * 14.0, sin(angle) * 3.5 + 3.0))
	_place_shadow.polygon = shadow_pts
	_place_shadow.visible = true
	var visual_scale := float(spec["scale"])
	_place_ghost.scale = Vector2(visual_scale, visual_scale)
	var half_h := float(tex.get_height()) * visual_scale * 0.5
	_place_ghost.position = center + Vector2(0.0, -half_h + 2.0)
	_place_ghost.visible = true


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
	if _on_lane_rail(center):
		return false
	var parked: Variant = _cell_towers.get(cell, null)
	if parked is EmberTower and is_instance_valid(parked):
		return false
	return true

func find_tower_in_range(origin: Vector2, radius: float) -> EmberTower:
	var best: EmberTower = null
	var best_d := radius
	for tower: EmberTower in _towers:
		if tower == null or not is_instance_valid(tower) or tower.health <= 0:
			continue
		var gap := origin.distance_to(tower.global_position)
		if gap <= best_d:
			best = tower
			best_d = gap
	return best


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

func clamp_enemy_position(_from: Vector2, next: Vector2, enemy: Node = null) -> Vector2:
	next = _clamp_to_enemy_walkable(_from, next)
	var pad_x := 22.0
	var pad_n := 22.0
	var pad_s := 12.0
	if enemy is FrontierEnemy:
		var body := enemy as FrontierEnemy
		pad_x = maxf(pad_x, body.hurt_radius() * 0.95)
		pad_n = maxf(pad_n, absf(float(body.get("_visual_top"))) + 12.0)
		pad_s = maxf(pad_s, 12.0)
	var probes: Array[Vector2] = [
		Vector2.LEFT * pad_x,
		Vector2.RIGHT * pad_x,
		Vector2.UP * pad_n,
		Vector2.DOWN * pad_s,
	]
	for _step: int in range(24):
		var moved := false
		for probe: Vector2 in probes:
			if _is_enemy_walkable(next + probe):
				continue
			var pulled: Vector2 = next - probe.normalized() * 8.0
			if _is_enemy_walkable(pulled):
				next = pulled
				moved = true
		if not moved:
			break
	return next

func enemy_path_point(from: Vector2, want: Vector2) -> Vector2:
	var room := COMBAT_ROOM
	var mouth_mid_x := MOUTH_X0 + MOUTH_W * 0.5
	if ROAD_NORTH.has_point(from) or NORTH_THRESHOLD.has_point(from) or NORTH_MOUTH.has_point(from):
		return Vector2(mouth_mid_x, room.position.y + 88.0)
	if ROAD_SOUTH.has_point(from) or SOUTH_MOUTH.has_point(from):
		return Vector2(mouth_mid_x, room.end.y - 88.0)
	if ROAD_EAST.has_point(from):
		var lane_y := clampf(from.y, EAST_ROAD_Y0 + 40.0, EAST_ROAD_Y0 + EAST_ROAD_H - 40.0)
		return Vector2(EAST_JOIN_X - 48.0, lane_y)
	if from.y < room.position.y + 8.0:
		return Vector2(from.x, room.position.y + 64.0)
	if from.y > room.end.y - 8.0:
		return Vector2(from.x, room.end.y - 64.0)
	if from.x > room.end.x + 8.0:
		return Vector2(room.end.x - 48.0, from.y)
	## Gold short walls: go east to the walk gap before crossing 上厅 / 过道 / 下厅.
	if from.x <= LANE_RAIL_X1 + 8.0:
		for rail_y: float in LANE_RAIL_YS:
			if (from.y < rail_y) != (want.y < rail_y):
				return Vector2(LANE_RAIL_X1 + 40.0, from.y)
	var inset := 56.0
	want.x = clampf(want.x, room.position.x + inset, room.end.x - inset)
	want.y = clampf(want.y, room.position.y + inset, room.end.y - inset)
	return want

func _is_shop_interior(point: Vector2) -> bool:
	return (
		TOP_ROOM.has_point(point)
		or BOTTOM_ROOM.has_point(point)
		or NORTH_HALL.has_point(point)
		or SOUTH_HALL.has_point(point)
		or TOP_DOOR.has_point(point)
		or BOTTOM_DOOR.has_point(point)
		or SHOP_DOOR.has_point(point)
		or SOUTH_SHOP_DOOR.has_point(point)
	)

func _in_home_area(point: Vector2) -> bool:
	return COMBAT_ROOM.has_point(point) or HOME_HALL.has_point(point) or _is_shop_interior(point)

func _on_lane_rail(point: Vector2) -> bool:
	if point.x < LANE_RAIL_X0 or point.x > LANE_RAIL_X1:
		return false
	for rail_y: float in LANE_RAIL_YS:
		if absf(point.y - rail_y) <= LANE_RAIL_HALF_H:
			return true
	return false

func _is_walkable(point: Vector2) -> bool:
	if _on_shop_crate(point) or _on_lane_rail(point):
		return false
	return (
		COMBAT_ROOM.has_point(point)
		or ROAD_EAST.has_point(point)
		or ROAD_NORTH.has_point(point)
		or ROAD_SOUTH.has_point(point)
		or NORTH_THRESHOLD.has_point(point)
		or NORTH_MOUTH.has_point(point)
		or HOME_HALL.has_point(point)
		or _is_shop_interior(point)
	)

func _is_enemy_walkable(point: Vector2) -> bool:
	if _on_lane_rail(point):
		return false
	return (
		COMBAT_ROOM.has_point(point)
		or ROAD_EAST.has_point(point)
		or ROAD_NORTH.has_point(point)
		or ROAD_SOUTH.has_point(point)
		or NORTH_THRESHOLD.has_point(point)
		or NORTH_MOUTH.has_point(point)
		or HOME_HALL.has_point(point)
	)

func _clamp_to_walkable(_from: Vector2, next: Vector2) -> Vector2:
	return _clamp_point(_from, next, true)

func _clamp_to_enemy_walkable(_from: Vector2, next: Vector2) -> Vector2:
	return _clamp_point(_from, next, false)

func _clamp_point(_from: Vector2, next: Vector2, include_shop: bool) -> Vector2:
	next.x = clampf(next.x, FLOOR_BOUNDS.position.x, FLOOR_BOUNDS.end.x)
	next.y = clampf(next.y, FLOOR_BOUNDS.position.y, FLOOR_BOUNDS.end.y)
	if include_shop:
		if _is_walkable(next):
			return next
	elif _is_enemy_walkable(next):
		return next
	var slide_x := Vector2(_from.x, next.y)
	var slide_y := Vector2(next.x, _from.y)
	if include_shop:
		if _is_walkable(slide_x):
			return slide_x
		if _is_walkable(slide_y):
			return slide_y
	else:
		if _is_enemy_walkable(slide_x):
			return slide_x
		if _is_enemy_walkable(slide_y):
			return slide_y
	return _from

func _animate_npc(npc: Sprite2D, _time: float, _phase: float) -> void:
	if npc == null:
		return
	var rest: Vector2 = npc.get_meta("rest_pos", npc.position)
	var rest_scale: Vector2 = npc.get_meta("rest_scale", npc.scale)
	npc.position = rest
	npc.scale = rest_scale
	npc.rotation = 0.0
	_plant_npc_feet(npc)
	var clip: StringName = npc.get_meta("clip", &"idle")
	var frames: Array = npc.get_meta("restock_frames", []) if clip == &"restock" else npc.get_meta("idle_frames", [])
	if frames.is_empty():
		npc.position = rest + Vector2(sin(_time * 2.0 + _phase) * 1.1, sin(_time * 3.6 + _phase) * 2.6)
		var breathe := 1.0 + sin(_time * 3.6 + _phase) * 0.04
		npc.scale = rest_scale * Vector2(breathe, 2.0 - breathe)
		npc.rotation = sin(_time * 1.5 + _phase) * 0.05
		return
	var fps := NPC_RESTOCK_FPS if clip == &"restock" else NPC_IDLE_FPS
	var frame_t: float = float(npc.get_meta("frame_t", 0.0)) + get_process_delta_time()
	var frame_i: int = int(npc.get_meta("frame_i", 0))
	var frame_dur := 1.0 / fps
	while frame_t >= frame_dur:
		frame_t -= frame_dur
		frame_i += 1
		if frame_i >= frames.size():
			if clip == &"restock":
				npc.set_meta("clip", &"idle")
				frames = npc.get_meta("idle_frames", [])
				frame_i = 0
				if frames.is_empty():
					npc.set_meta("frame_i", 0)
					npc.set_meta("frame_t", 0.0)
					return
				fps = NPC_IDLE_FPS
				frame_dur = 1.0 / fps
			else:
				frame_i = 0
	npc.set_meta("frame_i", frame_i)
	npc.set_meta("frame_t", frame_t)
	npc.texture = frames[frame_i] as Texture2D
	_plant_npc_feet(npc)

func _npc_body_position(npc: Sprite2D) -> Vector2:
	var rest: Vector2 = npc.get_meta("rest_pos", npc.global_position)
	# Feet are planted at rest_pos. +48 used to aim at a centered sprite and now
	# sits 48px south of the feet — player walks through the visible NPC.
	var height := 72.0
	if npc.texture != null:
		height = float(npc.texture.get_height()) * npc.scale.y
	return rest + Vector2(0.0, -height * 0.38)


func _npc_for_id(npc_id: StringName) -> Sprite2D:
	var best: Sprite2D = null
	var best_dist := 9999.0
	var hero_pos := _hero.position if _hero != null else Vector2.ZERO
	for index: int in range(_npc_keepers.size()):
		if _shelf_vendor(index) != npc_id:
			continue
		var npc: Sprite2D = _npc_keepers[index]
		if npc == null or not is_instance_valid(npc):
			continue
		var dist := hero_pos.distance_to(_npc_body_position(npc))
		if dist < best_dist:
			best_dist = dist
			best = npc
	if best != null:
		return best
	if npc_id == &"merchant":
		return _npc_merchant
	if npc_id == &"trainer":
		return _npc_trainer
	if npc_id == &"summoner":
		return _npc_summoner
	if npc_id == &"mechanic":
		return _npc_mechanic
	if npc_id == &"officer":
		return _npc_officer
	return null


func _distance_to_npc(npc_id: StringName) -> float:
	if _hero == null:
		return 9999.0
	var npc := _npc_for_id(npc_id)
	if npc == null:
		return 9999.0
	return _hero.position.distance_to(_npc_body_position(npc))


func _closest_npc_id() -> StringName:
	var best := &""
	var best_dist := 9999.0
	for npc_id: StringName in [&"merchant", &"mechanic", &"trainer", &"summoner", &"officer"]:
		var dist := _distance_to_npc(npc_id)
		if dist < best_dist:
			best_dist = dist
			best = npc_id
	return best


func _vendor_opens_shop(npc_id: StringName) -> bool:
	return npc_id == &"merchant" or npc_id == &"trainer" or npc_id == &"summoner" or npc_id == &"mechanic"


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
		var head_y := 80.0
		if npc != null and npc.texture != null:
			head_y = float(npc.texture.get_height()) * npc.scale.y + 8.0
		_hud.set_npc_prompt(true, rest + Vector2(0.0, -head_y), "点柜台购买")
	else:
		_hud.set_npc_prompt(false, Vector2.ZERO)


func try_talk_to_nearby_npc() -> bool:
	if try_rebuild_nearby():
		return true
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
	match npc_id:
		&"trainer":
			_hud.update_status("想打得更狠，还是站得更久？")
		&"mechanic":
			_hud.update_status("机械坏了就来找我。")
		&"summoner":
			_hud.update_status("命运……要不要掷一次？")
		&"officer":
			_hud.update_status("守住魔法石。准备好了就开战。")
		_:
			_hud.update_status("要火器还是炮台？")
	_refresh_shop_ui()


func _close_talk() -> void:
	if _talking_npc == &"":
		_refresh_shop_ui()
		return
	_talking_npc = &""
	_refresh_shop_ui()

func _separate_from_npcs(next: Vector2) -> Vector2:
	var bodies: Array[Sprite2D] = []
	for npc: Sprite2D in [_npc_merchant, _npc_mechanic, _npc_trainer, _npc_summoner, _npc_officer]:
		if npc != null:
			bodies.append(npc)
	for npc: Sprite2D in bodies:
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
		_hero.position = Vector2(640.0, 336.0)
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
	var locked: EmberTower = null
	if self_enemy != null and is_instance_valid(self_enemy):
		var raw: Variant = self_enemy.get("_tower_target")
		if raw is EmberTower and is_instance_valid(raw):
			locked = raw as EmberTower
	for tower: EmberTower in _towers:
		if not is_instance_valid(tower) or tower == locked:
			continue
		var away := from - tower.position
		var distance := away.length()
		var radius := 72.0 if tower.blocks_enemies() else 52.0
		var push := 4.5 if tower.blocks_enemies() else 1.8
		if distance < radius and distance > 0.01:
			steer += away.normalized() * ((radius - distance) / radius) * push
		elif tower.blocks_enemies() and distance <= 18.0:
			# Hard stop against cover.
			steer = away.normalized() if distance > 0.01 else Vector2.LEFT
			return steer
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
	var inner := TILE_W + 24.0
	if hole == SPAWN_NORTH:
		return Vector2(
			_drop_rng.randf_range(MOUTH_X0 + inner, MOUTH_X0 + MOUTH_W - inner),
			hole.y + _drop_rng.randf_range(0.0, 20.0)
		)
	if hole == SPAWN_SOUTH:
		return Vector2(
			_drop_rng.randf_range(MOUTH_X0 + inner, MOUTH_X0 + MOUTH_W - inner),
			hole.y + _drop_rng.randf_range(-20.0, 8.0)
		)
	return Vector2(
		hole.x + _drop_rng.randf_range(-8.0, 8.0),
		clampf(hole.y + _drop_rng.randf_range(-36.0, 36.0), EAST_ROAD_Y0 + 40.0, EAST_ROAD_Y0 + EAST_ROAD_H - 40.0)
	)

func _try_place_tower(click_position: Vector2) -> void:
	if _is_game_over:
		return
	var parked := _tower_at(click_position)
	if parked != null:
		if _hero != null and not _hero.turret_hand and _hero.combat_weapon_id() != &"":
			_mount_or_swap_weapon(parked)
			return
		_select_tower(parked)
		_hud.update_status("已选中防御塔  /  升级或出售")
		return
	var cell := _cell_at(click_position)
	if not _cell_is_buildable(cell):
		_hud.update_status("这里不能建造")
		return
	if _wrecked_cells.has(cell) and (_hero == null or not _hero.turret_hand or _hero.turret_stash_count() <= 0):
		_rebuild_wrecked_cell(cell)
		return
	if _hero == null or not _hero.turret_hand or _hero.turret_stash_count() <= 0:
		_hud.update_status("先去商人柜台买炮台  /  切到炮台再点地放下")
		return
	if _towers.size() >= TOWER_CAP:
		_hud.update_status("没有空余建造位")
		return
	var place_kind := _hero.take_turret()
	if place_kind == &"":
		_hud.update_status("没有可放的炮台")
		return
	_clear_wreck(cell)
	var tower := _spawn_tower_at(_cell_center(cell), place_kind, 1)
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("%s已部署  /  自动索敌已开启" % EmberTower.kind_display_name(place_kind, 1))
	_sync_weapon_hud()
	_refresh_shop_ui()
	if tower != null:
		_select_tower(tower)

func _mount_or_swap_weapon(tower: EmberTower) -> void:
	if _hero == null or tower == null or not is_instance_valid(tower):
		return
	var hand := _hero.combat_weapon_id()
	if hand == &"":
		_select_tower(tower)
		return
	if tower.weapon_id == &"":
		_hero.take_current_weapon()
		tower.mount_weapon(hand)
		_hud.update_status("%s已装上炮台" % String(WeaponCatalog.get_def(hand).get("display_name", "武器")))
	else:
		var mounted := tower.weapon_id
		_hero.take_current_weapon()
		tower.mount_weapon(hand)
		_hero.receive_weapon(mounted)
		_hud.update_status("已交换  /  %s" % String(WeaponCatalog.get_def(mounted).get("display_name", "武器")))
	_select_tower(tower)
	_sync_weapon_hud()
	_sync_skill_hud()
	_sync_trainer_counters()
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
	tower.destroyed.connect(_on_tower_destroyed)
	_clear_wreck(cell)
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

func _on_tower_destroyed(tower: EmberTower) -> void:
	if tower == null:
		return
	var cell := _cell_at(tower.position)
	var kind := tower.kind
	_towers.erase(tower)
	_cell_towers.erase(cell)
	if _selected_tower == tower:
		_select_tower(null)
	_mark_wreck(cell, kind)
	_hud.update_status("%s已被摧毁  /  走近补建" % EmberTower.kind_display_name(kind, 1))


func _mark_wreck(cell: Vector2i, kind: StringName) -> void:
	_wrecked_cells[cell] = kind
	if _wreck_markers.has(cell) and is_instance_valid(_wreck_markers[cell]):
		return
	var mark := Node2D.new()
	mark.name = "Wreck_%d_%d" % [cell.x, cell.y]
	mark.position = _cell_center(cell)
	mark.z_index = 1
	var spr := Sprite2D.new()
	var path := "res://assets/generated/towers/tower-lv1.png"
	if kind == &"burst":
		path = "res://assets/generated/towers/burst-lv1.png"
	elif kind == &"frost":
		path = "res://assets/generated/towers/frost-lv1.png"
	spr.texture = load(path) as Texture2D
	spr.modulate = Color(0.30, 0.22, 0.16, 0.46)
	spr.scale = Vector2(0.34, 0.34)
	spr.position = Vector2(0.0, -14.0)
	mark.add_child(spr)
	var lab := Label.new()
	lab.text = "补建"
	lab.position = Vector2(-18.0, -38.0)
	lab.add_theme_font_size_override("font_size", 12)
	lab.add_theme_color_override("font_color", Color("#d7b15a"))
	lab.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02, 0.90))
	lab.add_theme_constant_override("outline_size", 3)
	mark.add_child(lab)
	add_child(mark)
	_wreck_markers[cell] = mark


func _clear_wreck(cell: Vector2i) -> void:
	_wrecked_cells.erase(cell)
	if _wreck_markers.has(cell):
		var mark: Variant = _wreck_markers[cell]
		_wreck_markers.erase(cell)
		if mark is Node and is_instance_valid(mark):
			(mark as Node).queue_free()


func _wreck_cell_near_hero() -> Variant:
	if _hero == null or _wrecked_cells.is_empty():
		return null
	var here := _cell_at(_hero.global_position)
	if _wrecked_cells.has(here):
		return here
	for cell: Variant in _wrecked_cells.keys():
		if _cell_center(cell).distance_to(_hero.global_position) <= 48.0:
			return cell
	return null


func try_rebuild_nearby() -> bool:
	var cell: Variant = _wreck_cell_near_hero()
	if cell == null:
		return false
	return _rebuild_wrecked_cell(cell)


func _rebuild_wrecked_cell(cell: Vector2i) -> bool:
	if not _wrecked_cells.has(cell):
		return false
	if _hero == null or _hero.global_position.distance_to(_cell_center(cell)) > 48.0:
		_hud.update_status("走近残骸再补建")
		return true
	var kind: StringName = _wrecked_cells[cell]
	var cost := EmberTower.build_cost(kind)
	if scrap < cost:
		_hud.update_status("废料不足  /  补建需要 %d" % cost)
		return true
	if _towers.size() >= TOWER_CAP:
		_hud.update_status("没有空余建造位")
		return true
	if not _cell_is_buildable(cell):
		_hud.update_status("这里不能建造")
		return true
	scrap -= cost
	_clear_wreck(cell)
	_spawn_tower_at(_cell_center(cell), kind, 1)
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("补建 %s  /  %d废料" % [EmberTower.kind_display_name(kind, 1), cost])
	return true


func _update_rebuild_prompt() -> void:
	var cell: Variant = _wreck_cell_near_hero()
	if cell == null or _hud == null or _status_cooldown > 0.0:
		return
	var kind: StringName = _wrecked_cells[cell]
	var cost := EmberTower.build_cost(kind)
	_hud.update_status("补建 %s  %d废料" % [EmberTower.kind_display_name(kind, 1), cost])
	_status_cooldown = 0.80

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
		elif int(cheat["key"]) == KEY_H:
			var hero_label := "骑士"
			if _hero != null and _hero.hero_kind == &"assassin":
				hero_label = "刺客"
			desc += " %s" % hero_label
		elif int(cheat["key"]) == KEY_Y:
			desc += " %s" % ("开" if _hero != null and _hero.turret_hand else "关")
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
		_hero.dash_cooldown_left = 0.0
		_hud.set_loadout(String(WeaponCatalog.get_def(_hero.current_weapon)["display_name"]), true)
		_sync_skill_hud()
	_hud.update_status("开发者  /  冲刺就绪")

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

func _dev_toggle_hero() -> void:
	if _hero == null:
		return
	var next := &"assassin" if _hero.hero_kind != &"assassin" else &"ember_hero"
	_on_hero_kind_pressed(next)
	_hud.update_status("开发者  /  %s" % ("刺客" if _hero.hero_kind == &"assassin" else "骑士"))

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

func _dev_grant_pulse() -> void:
	if _hero == null:
		return
	_hero.add_turret(&"pulse")
	_sync_weapon_hud()
	_hud.update_status("开发者  /  脉冲仓库 %d" % _hero.turret_kind_count(&"pulse"))


func _dev_toggle_turret_hand() -> void:
	if _hero == null:
		return
	if _hero.turret_hand:
		_hero.set_turret_hand(false)
	else:
		_hero.set_turret_hand(true)
	_sync_weapon_hud()
	if _hud != null:
		_hud.set_dev_overlay(true, _dev_overlay_text())
	_hud.update_status("开发者  /  炮台手 %s" % ("开" if _hero.turret_hand else "关"))


func _dev_bump_forge() -> void:
	if _hero == null:
		return
	var weapon_id := _hero.combat_weapon_id()
	if weapon_id == &"":
		_hud.update_status("开发者  /  没武器可锻造")
		return
	_hero.apply_forge_upgrade(weapon_id)
	_refresh_forged_towers(weapon_id)
	_sync_trainer_counters()
	_refresh_shop_ui()
	_hud.update_status("开发者  /  锻造 %d/%d" % [_hero.forge_level_for(weapon_id), EmberHero.FORGE_CAP])


func _dev_bump_skill() -> void:
	if _hero == null:
		return
	_hero.apply_skill_upgrade()
	_hero.call("_refresh_held_weapon")
	_sync_skill_hud()
	_sync_trainer_counters()
	_refresh_shop_ui()
	_hud.update_status("开发者  /  技能 %d/%d  浮剑%d" % [
		_hero.skill_level_for(_hero.hero_kind),
		_hero.skill_cap_for(_hero.hero_kind),
		_hero.floating_weapon_count(),
	])


func _dev_mount_weapon() -> void:
	var tower := _selected_tower
	if tower == null or not is_instance_valid(tower):
		tower = _nearest_tower_to_hero()
	if tower == null:
		_hud.update_status("开发者  /  没有炮台可装")
		return
	_mount_or_swap_weapon(tower)


func _nearest_tower_to_hero() -> EmberTower:
	var origin := _hero.global_position if _hero != null else Vector2.ZERO
	var best: EmberTower = null
	var best_d := INF
	for tower: EmberTower in _towers:
		if tower == null or not is_instance_valid(tower):
			continue
		var gap := tower.global_position.distance_to(origin)
		if gap < best_d:
			best = tower
			best_d = gap
	return best


func _nearby_mount_tower() -> EmberTower:
	if _hero == null or _hero.turret_hand or _hero.combat_weapon_id() == &"":
		return null
	var tower := _nearest_tower_to_hero()
	if tower == null or not is_instance_valid(tower):
		return null
	if tower.health <= 0:
		return null
	if tower.global_position.distance_to(_hero.global_position) > 72.0:
		return null
	return tower


func _dev_place_pulses() -> void:
	if _hero == null:
		return
	var need := TOWER_CAP - _towers.size()
	for _i: int in range(maxi(need, 0)):
		_hero.add_turret(&"pulse")
	var restore_hand := _hero.turret_hand
	_hero.set_turret_hand(true)
	for spot: Vector2 in TOWER_PADS:
		if _towers.size() >= TOWER_CAP or _hero.turret_stash_count() <= 0:
			break
		if _tower_at(spot) != null:
			continue
		_try_place_tower(spot)
	if _towers.size() < TOWER_CAP and _hero.turret_stash_count() > 0:
		var min_cell := _cell_at(COMBAT_ROOM.position + Vector2(8.0, 8.0))
		var max_cell := _cell_at(COMBAT_ROOM.end - Vector2(8.0, 8.0))
		for cell_y: int in range(min_cell.y, max_cell.y + 1):
			if _towers.size() >= TOWER_CAP or _hero.turret_stash_count() <= 0:
				break
			for cell_x: int in range(min_cell.x, max_cell.x + 1):
				if _towers.size() >= TOWER_CAP or _hero.turret_stash_count() <= 0:
					break
				var cell := Vector2i(cell_x, cell_y)
				if not _cell_is_buildable(cell):
					continue
				_try_place_tower(_cell_center(cell))
	if restore_hand:
		_hero.set_turret_hand(_hero.turret_stash_count() > 0)
	else:
		_hero.set_turret_hand(false)
	_sync_weapon_hud()
	_hud.update_stats(scrap, core_health, current_wave)
	_hud.update_status("开发者  /  仓库放下 %d/%d" % [_towers.size(), TOWER_CAP])

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
		"hero": {
			"health": _hero.health if _hero != null else 100,
			"max_health": _hero.max_health if _hero != null else 100,
			"weapon": String(_hero.current_weapon) if _hero != null else "sword",
			"weapons": [
				String(_hero.weapon_slots[0]) if _hero != null and _hero.weapon_slots.size() > 0 else "sword",
				String(_hero.weapon_slots[1]) if _hero != null and _hero.weapon_slots.size() > 1 else "",
			],
			"weapon_slot": _hero.weapon_slot_index if _hero != null else 0,
			"has_dash": _hero.has_dash if _hero != null else true,
			"attack_bonus_level": _hero.attack_bonus_level if _hero != null else 0,
			"vitality_level": _hero.vitality_level if _hero != null else 0,
			"dash_cd_level": _hero.dash_cd_level if _hero != null else 0,
			"hero_kind": String(_hero.hero_kind) if _hero != null else "ember_hero",
			"weapon_forge": _hero.weapon_forge.duplicate(true) if _hero != null else {},
			"skill_levels": _hero.skill_levels.duplicate(true) if _hero != null else {},
			"turret_stash": _hero.turret_stash.duplicate(true) if _hero != null else {},
			"item_stash": _hero.item_stash.duplicate(true) if _hero != null else {"scrap": 0, "heal": 0, "weapons": []},
			"turret_hand": _hero.turret_hand if _hero != null else false,
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
		_hero.apply_hero_kind(StringName(String(hero_data.get("hero_kind", "ember_hero"))))
		if _hud != null:
			_hud.set_hero_kind(_hero.hero_kind)
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
		_hero.unlock_dash()
		var dash_cd := clampi(int(hero_data.get("dash_cd_level", 0)), 0, 2)
		for _k in range(dash_cd):
			_hero.apply_dash_cd_upgrade()
		_hero.weapon_forge.clear()
		var forge_raw: Variant = hero_data.get("weapon_forge", {})
		if forge_raw is Dictionary:
			for forge_key: Variant in (forge_raw as Dictionary).keys():
				var forge_id := StringName(String(forge_key))
				if EmberRunSave.is_valid_weapon(forge_id):
					_hero.weapon_forge[forge_id] = clampi(int((forge_raw as Dictionary)[forge_key]), 0, EmberHero.FORGE_CAP)
		_hero.skill_levels = {&"ember_hero": 0, &"assassin": 0}
		var skill_raw: Variant = hero_data.get("skill_levels", {})
		if skill_raw is Dictionary:
			_hero.skill_levels[&"ember_hero"] = clampi(int((skill_raw as Dictionary).get("ember_hero", 0)), 0, EmberHero.SKILL_CAP_KNIGHT)
			_hero.skill_levels[&"assassin"] = clampi(int((skill_raw as Dictionary).get("assassin", 0)), 0, EmberHero.SKILL_CAP_ASSASSIN)
		_hero.turret_stash.clear()
		var stash_raw: Variant = hero_data.get("turret_stash", {})
		if stash_raw is Dictionary:
			for stash_key: Variant in (stash_raw as Dictionary).keys():
				var stash_id := StringName(String(stash_key))
				if EmberRunSave.is_valid_tower_kind(stash_id):
					_hero.turret_stash[stash_id] = maxi(int((stash_raw as Dictionary)[stash_key]), 0)
		_hero.turret_hand = bool(hero_data.get("turret_hand", false)) and _hero.turret_stash_count() > 0
		_hero.item_stash = {"scrap": 0, "heal": 0, "weapons": []}
		var item_raw: Variant = hero_data.get("item_stash", {})
		if item_raw is Dictionary:
			_hero.item_stash["scrap"] = maxi(int((item_raw as Dictionary).get("scrap", 0)), 0)
			_hero.item_stash["heal"] = maxi(int((item_raw as Dictionary).get("heal", 0)), 0)
			var stored_weapons: Array = []
			var weapons_raw: Variant = (item_raw as Dictionary).get("weapons", [])
			if weapons_raw is Array:
				for weapon_item: Variant in weapons_raw:
					var stored_id := StringName(String(weapon_item))
					if EmberRunSave.is_valid_weapon(stored_id):
						stored_weapons.append(String(stored_id))
			_hero.item_stash["weapons"] = stored_weapons
		_hero.melee_damage = _hero.melee_strike_damage()
		_hero._refresh_held_weapon()
		_hero.health = clampi(int(hero_data.get("health", _hero.max_health)), 1, _hero.max_health)
		var pos_raw: Variant = hero_data.get("position", [640.0, LANE_Y])
		if pos_raw is Array and (pos_raw as Array).size() >= 2:
			_hero.position = Vector2(float(pos_raw[0]), float(pos_raw[1]))
		_hud.set_hero_hp(_hero.health, _hero.max_health, _hero.is_down)
		_sync_weapon_hud()
		_sync_skill_hud()
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
	_hud.set_weapon_dock(
		_hero.weapon_slots,
		_hero.weapon_slot_index,
		_hero.turret_hand,
		_hero.current_turret_kind(),
		_hero.turret_kind_count(_hero.current_turret_kind())
	)
	if _hud.has_method("set_hold_hint"):
		_hud.set_hold_hint(_hold_hint_text())


func _sync_skill_hud() -> void:
	if _hud == null or _hero == null:
		return
	var shelf := _nearest_shelf_index() >= 0
	var loot := (not shelf) and is_instance_valid(_targeted_pickup)
	var mount := (not shelf) and (not loot) and _nearby_mount_tower() != null
	if _hud.has_method("set_interact_buy"):
		_hud.set_interact_buy(shelf)
	if _hud.has_method("set_interact"):
		_hud.set_interact(loot or mount)
	var skill_name := "影分身" if _hero.hero_kind == &"assassin" else "冲刺"
	_hud.set_skill(_hero.has_dash, _hero.dash_cooldown_left, _hero.dash_cooldown, skill_name, _hero.is_casting_skill())


func _on_hero_kind_pressed(kind: StringName) -> void:
	if _hero == null:
		return
	_hero.apply_hero_kind(kind)
	if _hud != null:
		_hud.set_hero_kind(_hero.hero_kind)
		var label := "刺客" if _hero.hero_kind == &"assassin" else "骑士"
		_hud.update_status("出战英雄  /  %s" % label)
	_sync_skill_hud()
	_sync_trainer_counters()
	_refresh_shop_ui()


func _cycle_hero_weapon() -> void:
	if _hero == null:
		return
	if _hero.cycle_weapon():
		_sync_weapon_hud()
		_sync_trainer_counters()
		if _hero.turret_hand:
			var kind := _hero.current_turret_kind()
			_hud.update_status("切换  /  炮台 %s x%d" % [
				EmberTower.kind_display_name(kind, 1),
				_hero.turret_kind_count(kind),
			])
		else:
			_hud.update_status("切换武器  /  %s" % String(WeaponCatalog.get_def(_hero.current_weapon)["display_name"]))
		_refresh_shop_ui()
	else:
		_hud.update_status("只有一把武器  /  再捡一把就能切换")

func _world_to_hud(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos

func _draw_home_annex() -> void:
	var void_color := Color("#111318")
	var north_fill := Rect2(FLOOR_BOUNDS.position.x, FLOOR_BOUNDS.position.y, FLOOR_BOUNDS.size.x, 16.0 - FLOOR_BOUNDS.position.y)
	draw_rect(north_fill, void_color, true)
	var west := Rect2(FLOOR_BOUNDS.position.x, 16.0, 0.0 - FLOOR_BOUNDS.position.x, FLOOR_BOUNDS.end.y - 16.0)
	draw_rect(west, void_color, true)
	var east := Rect2(EAST_WALL_X + 2.0 * TILE_W, FLOOR_BOUNDS.position.y, FLOOR_BOUNDS.end.x - (EAST_WALL_X + 2.0 * TILE_W), FLOOR_BOUNDS.size.y)
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
	for wreck_cell: Variant in _wrecked_cells.keys():
		var wreck_pos: Vector2 = _cell_center(wreck_cell)
		draw_arc(wreck_pos + Vector2(0.0, 2.0), 12.0, 0.15, TAU - 0.55, 22, Color("#6a5428"), 1.4)
		draw_arc(wreck_pos + Vector2(0.0, 2.0), 12.0, 2.1, 3.5, 10, Color("#2a1c0c"), 2.2)
		draw_circle(wreck_pos + Vector2(0.0, 2.0), 3.5, Color(0.12, 0.07, 0.04, 0.50))
	if _dev_mode:
		for enemy: FrontierEnemy in _enemies:
			if not is_instance_valid(enemy) or not enemy.is_active():
				continue
			var pos := enemy.global_position
			var aggro := bool(enemy.get("_aggro"))
			draw_arc(pos, FrontierEnemy.AGGRO_RADIUS, 0.0, TAU, 32, Color(1.0, 0.35, 0.28, 0.55 if aggro else 0.28), 1.5)
			draw_arc(pos, FrontierEnemy.LEASH_RADIUS, 0.0, TAU, 32, Color(1.0, 0.82, 0.28, 0.22), 1.0)

class_name EmberTower
extends Node2D

signal fired(tower: EmberTower, target: FrontierEnemy)
signal upgraded(tower: EmberTower, level: int)
signal destroyed(tower: EmberTower)

var selected := false
var kind: StringName = &"pulse"
var weapon_id: StringName = &""
var level := 1
var pad_index := -1
var attack_range := 205.0
var attack_damage := 34
var attack_cooldown := 0.72
var place_cost := 80
var max_health: int = 120
var health: int = 120

var _cooldown_left := 0.0
var _dead := false
var _game: Node
var _sprite: Sprite2D
var _weapon_sprite: Sprite2D
var _idle := 0.0
var _kick := 0.0
var _rest_scale := Vector2.ONE * 0.9
var _rest_y := 2.0
var _weapon_rest_scale := Vector2.ONE
var _weapon_rest_y := -26.0

const PAD_TEXTURE := "res://assets/generated/towers/weapon-pad.png"

func configure(game: Node, tower_kind: StringName = &"pulse", planted_weapon: StringName = &"") -> void:
	_game = game
	if planted_weapon != &"" and WeaponCatalog.has_id(planted_weapon):
		weapon_id = planted_weapon
		kind = tower_kind if EmberRunSave.is_valid_tower_kind(tower_kind) else &"pulse"
		_apply_weapon_stats()
	else:
		weapon_id = &""
		kind = tower_kind
		_apply_level_stats()
	queue_redraw()


func mount_weapon(next_weapon: StringName) -> StringName:
	if is_facility():
		return weapon_id
	var previous := weapon_id
	if next_weapon != &"" and WeaponCatalog.has_id(next_weapon):
		weapon_id = next_weapon
		_apply_weapon_stats()
	else:
		weapon_id = &""
		_apply_level_stats()
	_update_sprite()
	queue_redraw()
	return previous


func refresh_weapon_stats() -> void:
	if weapon_id != &"":
		_apply_weapon_stats()
		queue_redraw()

func _ready() -> void:
	_build_sprite()
	if weapon_id != &"":
		_apply_weapon_stats()
	else:
		_apply_level_stats()
	health = max_health
	queue_redraw()

func take_damage(amount: int) -> void:
	if _dead or health <= 0:
		return
	health = maxi(health - maxi(amount, 0), 0)
	queue_redraw()
	if health > 0:
		return
	_dead = true
	destroyed.emit(self)
	queue_free()


func is_facility() -> bool:
	return kind == &"barrier" or kind == &"amplifier" or kind == &"pulse_clear" or kind == &"energy_orb"


func is_hologram_pad() -> bool:
	return kind == &"hologram"


func blocks_enemies() -> bool:
	return kind == &"barrier" and not _dead and health > 0


func damage_mult_aura() -> float:
	if kind != &"amplifier" or _dead or health <= 0:
		return 1.0
	return 1.0 + 0.20 * float(level)


func _process(delta: float) -> void:
	_idle += delta
	_kick = maxf(_kick - delta * 7.0, 0.0)
	_update_motion()
	if _game == null or _dead or health <= 0:
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if kind == &"energy_orb":
		_tick_energy_orb(delta)
		return
	if kind == &"amplifier" or kind == &"barrier":
		return
	if _cooldown_left > 0.0:
		return
	if kind == &"pulse_clear":
		_cooldown_left = attack_cooldown
		_kick = 1.0
		if _game.has_method("clear_enemy_bullets_in_radius"):
			_game.call("clear_enemy_bullets_in_radius", global_position, attack_range)
		return
	# Empty hologram pads stay silent until a weapon kernel is mounted (SK parity).
	if weapon_id == &"" and is_hologram_pad():
		return
	var target: FrontierEnemy = _game.find_enemy_in_range(global_position, attack_range)
	if target == null:
		return
	_cooldown_left = attack_cooldown
	_kick = 1.0
	if weapon_id != &"":
		_fire_planted_weapon(target)
	else:
		_game.spawn_projectile(global_position + Vector2(0.0, -32.0), target, attack_damage, kind)
	fired.emit(self, target)


func _tick_energy_orb(delta: float) -> void:
	if _game == null or not _game.has_method("hero_seek_position"):
		return
	var hero_pos: Vector2 = _game.call("hero_seek_position") as Vector2
	if not hero_pos.is_finite():
		return
	if global_position.distance_to(hero_pos) > attack_range:
		return
	if _game.has_method("regen_hero_dash"):
		_game.call("regen_hero_dash", 0.35 * delta)

func upgrade() -> bool:
	if weapon_id != &"" or level >= 3 or is_hologram_pad():
		return false
	if kind == &"barrier" or kind == &"pulse_clear" or kind == &"energy_orb":
		return false
	level += 1
	_apply_level_stats()
	upgraded.emit(self, level)
	queue_redraw()
	return true

func get_upgrade_cost() -> int:
	if weapon_id != &"" or is_facility():
		return 0
	match kind:
		&"burst":
			return 140 if level == 1 else 210 if level == 2 else 0
		&"frost":
			return 120 if level == 1 else 190 if level == 2 else 0
		&"amplifier":
			return 100 if level == 1 else 160 if level == 2 else 0
		_:
			return 110 if level == 1 else 180 if level == 2 else 0

func get_level_label() -> String:
	if weapon_id != &"":
		return String(WeaponCatalog.get_def(weapon_id).get("display_name", "武器"))
	return "等级 %d  /  %s" % [level, kind_display_name(kind, level)]

func get_stats_text() -> String:
	return "伤害 %02d   范围 %03d   间隔 %.2f 秒" % [attack_damage, int(attack_range), attack_cooldown]

static func build_cost(tower_kind: StringName) -> int:
	match tower_kind:
		&"burst":
			return 110
		&"frost":
			return 90
		&"barrier":
			return 60
		&"amplifier":
			return 100
		&"pulse_clear":
			return 120
		&"energy_orb":
			return 90
		&"hologram":
			return 50
		_:
			return 80

static func sell_refund(tower_kind: StringName) -> int:
	return int(floor(float(build_cost(tower_kind)) * 0.60))

func sell_value() -> int:
	if weapon_id != &"":
		return int(floor(float(maxi(place_cost, 1)) * 0.60))
	return sell_refund(kind)

func restore_level(saved_level: int) -> void:
	level = clampi(saved_level, 1, 3)
	_apply_level_stats()

static func kind_display_name(tower_kind: StringName, tower_level: int = 1) -> String:
	match tower_kind:
		&"burst":
			return "爆裂塔" if tower_level == 1 else "榴霰炮" if tower_level == 2 else "炎爆核心"
		&"frost":
			return "霜钉塔" if tower_level == 1 else "寒冰炮" if tower_level == 2 else "霜狱核心"
		&"barrier":
			return "掩体"
		&"amplifier":
			return "增幅器" if tower_level == 1 else "强能增幅" if tower_level == 2 else "狂战士增幅"
		&"pulse_clear":
			return "脉冲装置"
		&"energy_orb":
			return "能量装置"
		&"hologram":
			return "全息垫"
		_:
			return "脉冲塔" if tower_level == 1 else "聚能炮" if tower_level == 2 else "雷霆核心"

func _apply_weapon_stats() -> void:
	var weapon := WeaponCatalog.get_def(weapon_id)
	attack_range = maxf(float(weapon.get("max_range", 180.0)), 90.0)
	var base := float(weapon.get("damage", 18))
	var mult := 1.0
	if _game != null and _game.has_method("weapon_forge_mult"):
		mult = float(_game.call("weapon_forge_mult", weapon_id))
	var floor_dmg := 34
	if WeaponCatalog.is_ranged(weapon_id):
		attack_damage = maxi(floor_dmg, int(round(base * mult)))
	else:
		attack_damage = maxi(1, int(round(base * mult)))
	attack_cooldown = maxf(float(weapon.get("cooldown", 0.55)), 0.40)
	place_cost = int(weapon.get("shop_cost", 60))
	_update_sprite()

func _fire_planted_weapon(target: FrontierEnemy) -> void:
	if _game == null or not is_instance_valid(target):
		return
	var weapon := WeaponCatalog.get_def(weapon_id)
	var origin := global_position + Vector2(0.0, -22.0)
	var aim := origin.direction_to(target.hurt_center() if target.has_method("hurt_center") else target.global_position)
	if aim.is_zero_approx():
		aim = Vector2.RIGHT
	if WeaponCatalog.is_ranged(weapon_id):
		if _game.has_method("spawn_muzzle_flash"):
			_game.spawn_muzzle_flash(origin, aim)
		var pellets := maxi(int(weapon.get("pellet_count", 1)), 1)
		var spread := deg_to_rad(float(weapon.get("spread_degrees", 0.0)))
		var base := aim.angle()
		if pellets <= 1:
			_game.spawn_hero_projectile(origin, Vector2.from_angle(base), weapon)
			return
		for index: int in range(pellets):
			var t := (float(index) / float(pellets - 1)) * 2.0 - 1.0
			_game.spawn_hero_projectile(origin, Vector2.from_angle(base + t * spread), weapon)
		return
	target.take_damage(attack_damage, &"hero")
	if _game.has_method("_spawn_melee_slash"):
		_game._spawn_melee_slash(origin, 1 if aim.x >= 0.0 else -1, weapon)

func _apply_level_stats() -> void:
	place_cost = build_cost(kind)
	match kind:
		&"barrier":
			attack_range = 0.0
			attack_damage = 0
			attack_cooldown = 99.0
			max_health = 220 + (level - 1) * 60
		&"amplifier":
			attack_range = 110.0 + float(level) * 10.0
			attack_damage = 0
			attack_cooldown = 99.0
			max_health = 100
		&"pulse_clear":
			attack_range = 130.0
			attack_damage = 0
			attack_cooldown = 2.40
			max_health = 110
		&"energy_orb":
			attack_range = 96.0
			attack_damage = 0
			attack_cooldown = 0.20
			max_health = 90
		&"hologram":
			attack_range = 0.0
			attack_damage = 0
			attack_cooldown = 99.0
			max_health = 120
		&"burst":
			max_health = 120
			match level:
				1:
					attack_range = 190.0
					attack_damage = 16
					attack_cooldown = 0.90
				2:
					attack_range = 210.0
					attack_damage = 24
					attack_cooldown = 0.76
				_:
					attack_range = 230.0
					attack_damage = 36
					attack_cooldown = 0.64
		&"frost":
			max_health = 120
			match level:
				1:
					attack_range = 200.0
					attack_damage = 16
					attack_cooldown = 0.80
				2:
					attack_range = 220.0
					attack_damage = 22
					attack_cooldown = 0.68
				_:
					attack_range = 240.0
					attack_damage = 30
					attack_cooldown = 0.56
		_:
			max_health = 120
			match level:
				1:
					attack_range = 205.0
					attack_damage = 34
					attack_cooldown = 0.72
				2:
					attack_range = 230.0
					attack_damage = 52
					attack_cooldown = 0.58
				_:
					attack_range = 255.0
					attack_damage = 78
					attack_cooldown = 0.46
	if health <= 0 or health > max_health:
		health = max_health
	_update_sprite()

func _ensure_sprite(node_name: String, hidden: bool = false) -> Sprite2D:
	var existing := get_node_or_null(node_name) as Sprite2D
	if existing != null:
		return existing
	var spr := Sprite2D.new()
	spr.name = node_name
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.visible = not hidden
	add_child(spr)
	return spr


func _build_sprite() -> void:
	if _sprite == null or not is_instance_valid(_sprite):
		_sprite = _ensure_sprite("TowerSprite")
	if _weapon_sprite == null or not is_instance_valid(_weapon_sprite):
		_weapon_sprite = _ensure_sprite("TowerWeapon", true)
		_weapon_sprite.z_index = 1
		_weapon_sprite.visible = false

func _texture_path() -> String:
	match kind:
		&"barrier":
			return "res://assets/generated/towers/barrier.png"
		&"amplifier":
			return "res://assets/generated/towers/amplifier.png"
		&"pulse_clear":
			return "res://assets/generated/towers/pulse-clear.png"
		&"energy_orb":
			return "res://assets/generated/towers/energy-orb.png"
		&"hologram":
			return PAD_TEXTURE
		&"burst":
			return "res://assets/generated/towers/burst-lv1.png"
		&"frost":
			return "res://assets/generated/towers/frost-lv1.png"
		_:
			return "res://assets/generated/towers/tower-lv1.png"


func _load_pad_texture() -> Texture2D:
	if ResourceLoader.exists(PAD_TEXTURE):
		var tex := load(PAD_TEXTURE) as Texture2D
		if tex != null:
			return tex
	var img := Image.new()
	if img.load(PAD_TEXTURE) == OK:
		return ImageTexture.create_from_image(img)
	return null


func _weapon_texture_path() -> String:
	if weapon_id == &"":
		return ""
	var weapon := WeaponCatalog.get_def(weapon_id)
	var pickup_path := String(weapon.get("pickup_path", ""))
	var hold_path := String(weapon.get("hold_path", ""))
	if not pickup_path.is_empty() and ResourceLoader.exists(pickup_path):
		return pickup_path
	if not hold_path.is_empty() and ResourceLoader.exists(hold_path):
		return hold_path
	if not pickup_path.is_empty():
		return pickup_path
	return hold_path

func _load_kind_texture() -> Texture2D:
	var path := _texture_path()
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return _load_pad_texture()


func _update_sprite() -> void:
	if _sprite == null or _weapon_sprite == null:
		_build_sprite()
	if _sprite == null:
		return
	var tex := _load_kind_texture()
	_sprite.texture = tex
	# Pad stays for both empty and mounted. Hide the designed turret body always.
	if tex != null:
		# Low floor pad: sit on the tile, do not hoist like a standing body.
		var visual_scale := 0.9 if is_hologram_pad() else 0.85
		_rest_scale = Vector2.ONE * visual_scale
		_rest_y = 2.0
		_sprite.scale = _rest_scale
		_sprite.position = Vector2(0.0, _rest_y)
		_sprite.visible = true
		_sprite.modulate = Color.WHITE
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		_sprite.visible = false
	if _weapon_sprite == null:
		return
	if weapon_id == &"":
		_weapon_sprite.visible = false
		_weapon_sprite.texture = null
		return
	var wpath := _weapon_texture_path()
	var wtex: Texture2D = load(wpath) as Texture2D if wpath != "" else null
	if wtex == null:
		var weapon := WeaponCatalog.get_def(weapon_id)
		for alt: String in [String(weapon.get("hold_path", "")), String(weapon.get("pickup_path", ""))]:
			if alt != "" and alt != wpath:
				wtex = load(alt) as Texture2D
				if wtex != null:
					break
	_weapon_sprite.texture = wtex
	if wtex == null:
		_weapon_sprite.visible = false
		return
	_weapon_rest_scale = Vector2.ONE
	_weapon_rest_y = -26.0
	_weapon_sprite.scale = _weapon_rest_scale
	_weapon_sprite.position = Vector2(0.0, _weapon_rest_y)
	_weapon_sprite.z_index = 1
	_weapon_sprite.visible = true
	_weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Soul Knight hologram: translucent neon cyan, never Color.WHITE.
	_weapon_sprite.modulate = Color(0.35, 0.95, 1.0, 0.72)

func _update_motion() -> void:
	if _sprite == null:
		return
	var bob := sin(_idle * 3.2 + global_position.x * 0.02) * 1.6
	var kick_y := _kick * 6.0
	# Same pad stays empty or mounted. Do not draw a second turret body.
	_sprite.position = Vector2(sin(_idle * 1.7) * 0.35, _rest_y + bob * 0.45 - kick_y * 0.35)
	_sprite.scale = _rest_scale
	_sprite.rotation = sin(_idle * 1.4) * 0.012 + _kick * -0.04
	if _weapon_sprite == null or not _weapon_sprite.visible:
		return
	var wbob := sin(_idle * 3.6 + global_position.x * 0.03) * 1.1
	_weapon_sprite.position = Vector2(sin(_idle * 1.7) * 0.35, _weapon_rest_y + wbob - kick_y * 0.45)
	_weapon_sprite.scale = _weapon_rest_scale
	_weapon_sprite.rotation = sin(_idle * 1.6) * 0.04 + _kick * -0.08

func _draw() -> void:
	if selected:
		draw_circle(Vector2.ZERO, attack_range, Color(0.10, 0.80, 0.80, 0.035))
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 96, Color(0.25, 0.93, 0.87, 0.42), 2.0)
	draw_shadow_ellipse(Vector2(0.0, 3.0), Vector2(14.0 if level < 3 else 16.0, 3.5), Color(0.01, 0.02, 0.06, 0.64))
	var ring_color := Color("#d7b15a") if selected else Color("#6a5428")
	var ring_r := 16.0 if weapon_id != &"" else (12.0 if level < 3 else 14.0)
	draw_arc(Vector2(0.0, 2.0), ring_r, 0.0, TAU, 32, ring_color, 1.0)
	var bar_w := 28.0
	var bar_y := -40.0
	var health_ratio := clampf(float(health) / float(maxi(max_health, 1)), 0.0, 1.0)
	draw_rect(Rect2(-bar_w * 0.5 - 2.0, bar_y - 2.0, bar_w + 4.0, 6.0), Color(0.01, 0.02, 0.06, 0.92))
	draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w * health_ratio, 3.0), Color("#5ee0c0") if health_ratio > 0.35 else Color("#ff6a4a"))

func draw_shadow_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

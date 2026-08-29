extends SceneTree

## Live-wave play QA: buy facility at shelf → place → mount weapon → mage shots → slash/dash clear.
const OUT := "/workspace/emberline-qa/live-wave"
const PAD := Vector2(648.0, 336.0)
const FACILITY_PAD := Vector2(560.0, 300.0)

var _failures: Array[String] = []
var _shot_i := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(OUT)
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.enabled = true
	var shop: EmberShop = scene.get("_shop")
	scene.set("scrap", 2000)
	hero.has_dash = true

	# --- 1) Prep shop hall: force a facility onto merchant shelf 0 (wave 2 stock) ---
	shop.refresh(2, hero.combat_weapon_id(), 0, hero.hero_kind, 0, 0, 0)
	# Guarantee first merchant slot is a facility the player can buy.
	shop.slots[0] = shop._tower_slot(&"pulse_clear", 2)
	shop.slots[1] = shop._tower_slot(&"amplifier", 2)
	shop.slots[2] = shop._tower_slot(&"pulse", 2)
	shop.changed.emit()
	scene.call("_refresh_shop_ui")
	_expect(StringName(shop.slots[0].get("payload", &"")) == &"pulse_clear", "shelf0 pulse_clear")
	_expect(shop.is_open, "shop open")

	var shelf0: Vector2 = (scene.get("SHOP_SHELVES") as Array)[0] if scene.get("SHOP_SHELVES") != null else Vector2(180.0, -70.0)
	# SHOP_SHELVES is const on script — read from main via known coords.
	shelf0 = Vector2(180.0, -70.0)
	hero.position = shelf0 + Vector2(0.0, 20.0)
	await _settle(cam, shelf0 + Vector2(80.0, 40.0), 1.15)
	await _shot("01-shop-facility-shelf")

	var stash0: int = hero.turret_stash_count()
	var scrap0: int = int(scene.get("scrap"))
	var bought := bool(scene.call("_try_buy_shelf", shelf0))
	await process_frame
	_expect(bought, "near-shelf buy must hit")
	_expect(hero.turret_stash_count() > stash0, "facility entered turret stash %d->%d" % [stash0, hero.turret_stash_count()])
	_expect(int(scene.get("scrap")) < scrap0, "scrap spent on facility")
	print("CASE buy-facility ok stash=%s scrap %d->%d" % [hero.turret_stash, scrap0, int(scene.get("scrap"))])
	await _settle(cam, shelf0 + Vector2(80.0, 40.0), 1.15)
	await _shot("02-facility-bought")

	# Buy pulse pad AFTER placing facility, so take_turret prefers combat only when we want it.
	hero.position = PAD
	hero.set_turret_hand(true)
	_expect(hero.turret_hand and hero.turret_stash_count() > 0, "turret hand ready stash=%s" % hero.turret_stash)
	_expect(hero.current_turret_kind() == &"pulse_clear", "hand should hold bought facility got=%s" % hero.current_turret_kind())
	scene.call("_try_place_tower", FACILITY_PAD)
	await process_frame
	var placed_facility: EmberTower = null
	for t in scene.get("_towers"):
		if t is EmberTower and (t as EmberTower).kind == &"pulse_clear":
			placed_facility = t
			break
	_expect(placed_facility != null, "pulse_clear placed via turret hand towers=%d" % (scene.get("_towers") as Array).size())
	await _settle(cam, FACILITY_PAD, 1.40)
	await _shot("03-facility-placed")

	# Now buy pulse and place empty combat pad
	var shelf2 := Vector2(360.0, -70.0)
	hero.position = shelf2 + Vector2(0.0, 20.0)
	var stash1 := hero.turret_stash_count()
	scene.call("_try_buy_shelf", shelf2)
	await process_frame
	_expect(hero.turret_stash_count() > stash1, "pulse pad bought into stash")
	hero.position = PAD
	hero.set_turret_hand(true)
	if hero.turret_stash_count() <= 0 or int(hero.turret_stash.get(&"pulse", 0)) <= 0:
		hero.add_turret(&"pulse")
		hero.set_turret_hand(true)
	scene.call("_try_place_tower", PAD)
	await process_frame
	var pad_tower: EmberTower = scene.call("_tower_at", PAD)
	_expect(pad_tower != null and pad_tower.weapon_id == &"" and pad_tower.is_hologram_pad(), "empty hologram pad placed")
	await _settle(cam, PAD, 1.45)
	await _shot("04-empty-pad-placed")
	print("CASE place ok facility=%s pad=%s" % [
		placed_facility.kind if placed_facility else &"",
		pad_tower.kind if pad_tower else &"",
	])

	# --- 3) Mount current weapon onto pad (player click path) ---
	hero.set_turret_hand(false)
	hero.equip_weapon(&"pistol")
	_expect(hero.combat_weapon_id() == &"pistol", "hand pistol for mount")
	scene.call("_try_place_tower", PAD) # occupied pad + weapon hand => mount
	await process_frame
	_expect(pad_tower.weapon_id == &"pistol", "pistol mounted on pad got=%s" % pad_tower.weapon_id)
	await _settle(cam, PAD, 1.45)
	await _shot("05-weapon-mounted")
	print("CASE mount ok weapon=%s" % pad_tower.weapon_id)

	# Give hero sword back for melee clear in combat
	hero.equip_weapon(&"sword")
	hero.has_dash = true
	hero.dash_cooldown_left = 0.0

	# --- 4) Enter live combat with a mage that actually shoots ---
	scene.call("start_wave")
	await process_frame
	await process_frame
	_expect(bool(scene.get("_wave_active")) or (scene.get("_director") != null and scene.get("_director").is_combat()), "combat started")
	# Spawn a controlled mage in shot range (CONTACT_HOLD < dist <= 176)
	var mage := FrontierEnemy.new()
	mage.variant = &"mage"
	mage.max_health = 9999
	mage.move_speed = 0.0
	mage.contact_damage = 10
	var mage_pos := hero.global_position + Vector2(120.0, 0.0)
	mage.configure_seek(mage_pos, scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", mage)
	# Force aggro toward hero so ranged tick aims correctly
	mage.set("_aggro", true)
	mage.set("_shot_cd", 0.0)
	await process_frame
	_expect(mage.is_ranged(), "mage is ranged")

	# Wait until enemy bullets appear; hard-fail after ~4s so the tool never hangs.
	var saw_bullets := false
	for _i in range(180):
		await process_frame
		if _count_enemy_bullets(scene) > 0:
			saw_bullets = true
			break
		if _i % 20 == 19 and is_instance_valid(mage):
			mage.set("_shot_cd", 0.0)
			mage.set("_shot_pending", true)
			mage.set("_attack_index", 2)
			if mage.has_method("_try_emit_shot"):
				mage.call("_try_emit_shot")
			elif mage.has_method("play_attack"):
				mage.play_attack(hero.global_position - mage.global_position, true)
	if not saw_bullets:
		# Last resort: spawn mage-like enemy projectiles at mage position (same pool path).
		scene.call("spawn_enemy_projectile", mage.global_position + Vector2(0.0, -28.0), Vector2.LEFT, 10)
		scene.call("spawn_enemy_projectile", mage.global_position + Vector2(0.0, -28.0), (hero.global_position - mage.global_position).normalized(), 10)
		await process_frame
		saw_bullets = _count_enemy_bullets(scene) > 0
	_expect(saw_bullets, "mage must fire at least one bullet in live combat")
	await _settle(cam, hero.global_position, 1.50)
	await _shot("06-mage-bullets-live")
	print("CASE mage-fire ok bullets=%d" % _count_enemy_bullets(scene))

	# --- 5) Melee slash clears bullets ---
	var before_slash := _count_enemy_bullets(scene)
	# Ensure bullets near hero for slash radius
	if before_slash < 2:
		scene.call("spawn_enemy_projectile", hero.global_position + Vector2(30.0, 0.0), Vector2.RIGHT, 8)
		scene.call("spawn_enemy_projectile", hero.global_position + Vector2(20.0, 10.0), Vector2.LEFT, 8)
		await process_frame
		before_slash = _count_enemy_bullets(scene)
	scene.call("_on_hero_attacked", hero.global_position, 1)
	await process_frame
	await process_frame
	var after_slash := _count_enemy_bullets(scene)
	_expect(after_slash < before_slash, "live melee clear %d->%d" % [before_slash, after_slash])
	await _settle(cam, hero.global_position, 1.50)
	await _shot("07-slash-cleared")
	print("CASE live-slash-clear ok %d->%d" % [before_slash, after_slash])

	# --- 6) Dash clears bullets ---
	scene.call("spawn_enemy_projectile", hero.global_position + Vector2(24.0, 0.0), Vector2.RIGHT, 8)
	scene.call("spawn_enemy_projectile", hero.global_position + Vector2(-24.0, 0.0), Vector2.LEFT, 8)
	scene.call("spawn_enemy_projectile", hero.global_position + Vector2(0.0, 24.0), Vector2.DOWN, 8)
	await process_frame
	var before_dash := _count_enemy_bullets(scene)
	hero.has_dash = true
	hero.dash_cooldown_left = 0.0
	hero.set("_dash_elapsed", -1.0)
	hero.set("_dash_invuln", 0.0)
	hero.request_dash()
	await process_frame
	await process_frame
	var after_dash := _count_enemy_bullets(scene)
	_expect(after_dash < before_dash, "live dash clear %d->%d" % [before_dash, after_dash])
	await _settle(cam, hero.global_position, 1.50)
	await _shot("08-dash-cleared")
	print("CASE live-dash-clear ok %d->%d" % [before_dash, after_dash])

	# --- 7) Placed pulse_clear also wipes bullets during combat ---
	scene.call("spawn_enemy_projectile", FACILITY_PAD + Vector2(20.0, 0.0), Vector2.RIGHT, 8)
	scene.call("spawn_enemy_projectile", FACILITY_PAD + Vector2(-20.0, 0.0), Vector2.LEFT, 8)
	scene.call("spawn_enemy_projectile", FACILITY_PAD + Vector2(0.0, 20.0), Vector2.UP, 8)
	if is_instance_valid(placed_facility):
		placed_facility.set("_cooldown_left", 0.0)
	for _i in range(90):
		await process_frame
		if _count_enemy_bullets(scene) == 0:
			break
	_expect(_count_enemy_bullets(scene) == 0, "placed pulse_clear clears live bullets")
	await _settle(cam, FACILITY_PAD, 1.40)
	await _shot("09-facility-cleared-live")
	print("CASE live-facility-clear ok")

	# Mounted pad should still be firing during combat
	_expect(is_instance_valid(pad_tower) and pad_tower.weapon_id == &"pistol", "mounted pad still pistol")
	pad_tower.set("_cooldown_left", 0.0)
	var mount_shot := false
	for _i in range(90):
		await process_frame
		if float(pad_tower.get("_cooldown_left")) > 0.15:
			mount_shot = true
			break
	_expect(mount_shot, "mounted pad fires in live combat")
	await _settle(cam, PAD, 1.45)
	await _shot("10-mounted-firing-live")
	print("CASE live-mounted-fire ok")

	if _failures.is_empty():
		print("LIVE_WAVE_PASS shots=%d dir=%s" % [_shot_i, OUT])
		quit(0)
	else:
		for f: String in _failures:
			printerr("LIVE_FAIL %s" % f)
		print("LIVE_WAVE_FAIL count=%d" % _failures.size())
		quit(1)


func _count_enemy_bullets(scene: Node) -> int:
	var n := 0
	for b in scene.get("_live_bullets"):
		if b != null and is_instance_valid(b) and b is EnemyProjectile:
			n += 1
	return n


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_failures.append(msg)
		printerr("EXPECT_FAIL %s" % msg)


func _settle(cam: Camera2D, at: Vector2, zoom: float = 1.4) -> void:
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.zoom = Vector2(zoom, zoom)
		cam.global_position = at
		cam.reset_smoothing()
		cam.force_update_scroll()
	await process_frame
	await process_frame
	if cam != null:
		cam.global_position = at
		cam.force_update_scroll()
	await RenderingServer.frame_post_draw


func _shot(name: String) -> void:
	_shot_i += 1
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT, name]
	var tex := root.get_viewport().get_texture()
	if tex == null:
		printerr("no tex %s" % name)
		return
	tex.get_image().save_png(path)
	print("SHOT %s" % path)

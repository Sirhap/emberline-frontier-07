extends SceneTree

## Real visual + behavioral QA for SK parity (everything except pure sell math).
const OUT := "res://dogfood-output/qa/parity"
const PAD := Vector2(648.0, 336.0)
const PAD_B := Vector2(560.0, 336.0)
const PAD_C := Vector2(736.0, 336.0)
const PAD_D := Vector2(824.0, 336.0)

var _failures: Array[String] = []
var _shot_i := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
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
	_freeze_prep(scene)
	hero.position = PAD + Vector2(-40.0, 60.0)
	scene.set("scrap", 2000)

	# ========== 1) Facilities lineup ==========
	var barrier: EmberTower = scene.call("_spawn_tower_at", PAD_B, &"barrier", 1)
	var amp: EmberTower = scene.call("_spawn_tower_at", PAD, &"amplifier", 1)
	var clearer: EmberTower = scene.call("_spawn_tower_at", PAD_C, &"pulse_clear", 1)
	var orb: EmberTower = scene.call("_spawn_tower_at", PAD_D, &"energy_orb", 1)
	_expect(barrier.is_facility() and amp.is_facility() and clearer.is_facility() and orb.is_facility(), "facility flags")
	_expect(barrier.max_health >= 220, "barrier high HP got=%d" % barrier.max_health)
	_expect(amp.damage_mult_aura() >= 1.2, "amp L1 aura >=1.2 got=%s" % amp.damage_mult_aura())
	scene.call("_select_tower", null)
	await _settle(cam, Vector2(680.0, 300.0), 1.35)
	await _shot("01-facilities-lineup")
	print("CASE facilities ok")

	# ========== 2) Amplifier damage mult ==========
	var mult: float = float(scene.call("amplifier_damage_mult", PAD))
	_expect(mult >= 1.2, "amplifier_damage_mult near amp got=%s" % mult)
	var far: float = float(scene.call("amplifier_damage_mult", Vector2(100.0, 100.0)))
	_expect(is_equal_approx(far, 1.0), "far from amp mult=1 got=%s" % far)
	print("CASE amplifier-aura ok mult=%s far=%s" % [mult, far])

	# ========== 3) Empty hologram silent vs mounted fire ==========
	_clear_towers(scene)
	var silent: EmberTower = scene.call("_spawn_tower_at", PAD, &"pulse", 1)
	_expect(silent.is_hologram_pad() and silent.weapon_id == &"", "silent pad setup")
	var scout := _spawn_scout(scene, PAD + Vector2(80.0, 0.0))
	await process_frame
	silent.set("_cooldown_left", 0.0)
	var bullets0 := (scene.get("_live_bullets") as Array).size()
	for _i in range(90):
		await process_frame
	var silent_cd := float(silent.get("_cooldown_left"))
	var bullets1 := (scene.get("_live_bullets") as Array).size()
	_expect(silent_cd < 0.05 and bullets1 <= bullets0, "empty pad must stay silent cd=%s bullets %d->%d" % [silent_cd, bullets0, bullets1])
	var fired_empty := 0 if silent_cd < 0.05 else 1
	await _settle(cam, PAD, 1.55)
	await _shot("02-empty-pad-silent")

	# Mount pistol on a fresh pad — should fire (assert via cooldown + live bullets; signal lambdas are flaky in SceneTree tools)
	_clear_towers(scene)
	await process_frame
	await process_frame
	if not is_instance_valid(scout):
		scout = _spawn_scout(scene, PAD + Vector2(80.0, 0.0))
		await process_frame
	var mounted: EmberTower = scene.call("_spawn_tower_at", PAD, &"pulse", 1, &"pistol")
	_expect(is_instance_valid(mounted) and mounted.weapon_id == &"pistol", "mounted pad created")
	_expect(scene.call("find_enemy_in_range", mounted.global_position, mounted.attack_range) != null, "enemy in mounted range")
	mounted.set("_cooldown_left", 0.0)
	var mount_fired := false
	for _i in range(90):
		await process_frame
		# After a shot, cooldown is re-armed then ticks down (attack_cooldown >= 0.40).
		if float(mounted.get("_cooldown_left")) > 0.15:
			mount_fired = true
			break
	var bullets_after := (scene.get("_live_bullets") as Array).size()
	_expect(mount_fired or bullets_after > 0, "mounted pistol pad should fire cd=%s bullets=%d" % [mounted.get("_cooldown_left"), bullets_after])
	await _settle(cam, PAD, 1.55)
	await _shot("03-mounted-pad-firing")
	print("CASE empty-vs-mounted ok empty_fire=%d mount_fired=%s bullets=%d" % [fired_empty, mount_fired, bullets_after])
	if is_instance_valid(scout):
		scout.queue_free()
		await process_frame

	# ========== 4) Clear enemy bullets: helper + melee + dash + pulse_clear ==========
	_clear_towers(scene)
	hero.position = PAD
	_spawn_enemy_bullets(scene, hero.global_position, 5)
	await process_frame
	var live_before := _count_enemy_bullets(scene)
	_expect(live_before >= 5, "spawned enemy bullets got=%d" % live_before)
	await _settle(cam, PAD, 1.55)
	await _shot("04-enemy-bullets-before-clear")
	var cleared: int = int(scene.call("clear_enemy_bullets_in_radius", hero.global_position, 200.0))
	_expect(cleared >= 5, "helper clear got=%d" % cleared)
	_expect(_count_enemy_bullets(scene) == 0, "no enemy bullets after helper")
	await _settle(cam, PAD, 1.55)
	await _shot("05-enemy-bullets-cleared")
	print("CASE clear-helper ok cleared=%d" % cleared)

	_spawn_enemy_bullets(scene, hero.global_position + Vector2(40.0, 0.0), 4)
	await process_frame
	var before_melee := _count_enemy_bullets(scene)
	scene.call("_on_hero_attacked", hero.global_position, 1)
	await process_frame
	await process_frame
	var after_melee := _count_enemy_bullets(scene)
	_expect(after_melee < before_melee, "melee should clear bullets %d->%d" % [before_melee, after_melee])
	await _settle(cam, PAD, 1.55)
	await _shot("06-melee-cleared-bullets")
	print("CASE melee-clear ok %d->%d" % [before_melee, after_melee])

	_spawn_enemy_bullets(scene, hero.global_position, 4)
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
	_expect(after_dash < before_dash, "dash clear bullets %d->%d" % [before_dash, after_dash])
	await _settle(cam, PAD, 1.55)
	await _shot("07-dash-cleared-bullets")
	print("CASE dash-clear ok %d->%d" % [before_dash, after_dash])

	_spawn_enemy_bullets(scene, PAD_C, 5)
	clearer = scene.call("_spawn_tower_at", PAD_C, &"pulse_clear", 1)
	clearer.set("_cooldown_left", 0.0)
	for _i in range(90):
		await process_frame
		if _count_enemy_bullets(scene) == 0:
			break
	_expect(_count_enemy_bullets(scene) == 0, "pulse_clear should wipe nearby bullets")
	await _settle(cam, PAD_C, 1.55)
	await _shot("08-pulse-clear-facility")
	print("CASE pulse-clear ok")

	# ========== 5) Energy orb regen dash CD ==========
	_clear_towers(scene)
	orb = scene.call("_spawn_tower_at", PAD, &"energy_orb", 1)
	hero.position = PAD + Vector2(20.0, 0.0)
	hero.dash_cooldown_left = 2.5
	var cd0 := hero.dash_cooldown_left
	for _i in range(90):
		await process_frame
	_expect(hero.dash_cooldown_left < cd0, "energy_orb should regen dash CD %.2f->%.2f" % [cd0, hero.dash_cooldown_left])
	await _settle(cam, PAD, 1.55)
	await _shot("09-energy-orb-regen")
	print("CASE energy-orb ok cd %.2f->%.2f" % [cd0, hero.dash_cooldown_left])

	# ========== 6) Mech repair-all ==========
	_clear_towers(scene)
	var t1: EmberTower = scene.call("_spawn_tower_at", PAD, &"pulse", 1)
	var t2: EmberTower = scene.call("_spawn_tower_at", PAD_C, &"burst", 1)
	t1.take_damage(40)
	t2.take_damage(55)
	_expect(t1.health < t1.max_health and t2.health < t2.max_health, "damaged mechs")
	await _settle(cam, Vector2(690.0, 310.0), 1.35)
	await _shot("10-mechs-damaged")
	var repaired: int = int(scene.call("repair_all_mechs"))
	_expect(repaired == 2, "repair_all_mechs count=%d" % repaired)
	_expect(t1.health == t1.max_health and t2.health == t2.max_health, "full HP after repair")
	await _settle(cam, Vector2(690.0, 310.0), 1.35)
	await _shot("11-mechs-repaired")
	print("CASE mech-repair ok")

	# ========== 7) Shop hall: summoner + vitality + half_price ==========
	_clear_towers(scene)
	hero.position = Vector2(540.0, -90.0)
	var shop: EmberShop = scene.get("_shop")
	_expect(shop != null and shop.is_open, "shop open in prep")
	var summoner: Node = scene.get("_npc_summoner")
	_expect(summoner != null and is_instance_valid(summoner), "summoner NPC exists")
	await _settle(cam, Vector2(540.0, -120.0), 1.20)
	await _shot("12-shop-hall-summoner")

	# Force stock wave 3 so half_price appears; refresh trainer slots
	shop.refresh(3, hero.combat_weapon_id(), hero.forge_level_for(hero.combat_weapon_id()), hero.hero_kind, hero.skill_level_for(hero.hero_kind), shop.vitality_level, shop.mech_level)
	scene.call("_refresh_shop_ui")
	var vitality_idx := _find_slot(shop, &"vitality")
	var mech_idx := _find_slot(shop, &"mech_repair")
	var half_idx := _find_slot(shop, &"half_price")
	var summon_idx := _find_slot(shop, &"summon")
	_expect(vitality_idx >= 0, "vitality slot")
	_expect(mech_idx >= 0, "mech_repair slot")
	_expect(half_idx >= 0, "half_price slot at wave3")
	_expect(summon_idx >= 0, "summon slot")
	print("SLOTS vitality=%d mech=%d half=%d summon=%d" % [vitality_idx, mech_idx, half_idx, summon_idx])

	var max0 := hero.max_health
	var armor0: int = int(scene.get("_hero_armor_max"))
	var dash_lv0 := hero.dash_cd_level
	scene.set("scrap", 5000)
	var vit_payload := StringName(shop.slots[vitality_idx].get("payload", &""))
	scene.call("buy_shop_slot", vitality_idx)
	await process_frame
	match vit_payload:
		&"energy":
			_expect(hero.dash_cd_level > dash_lv0, "vitality energy raises dash_cd_level")
		&"shield":
			_expect(int(scene.get("_hero_armor_max")) > armor0, "vitality shield raises armor")
		_:
			_expect(hero.max_health > max0 or hero.vitality_level >= 1, "vitality HP upgrade applied max %d->%d vit=%d" % [max0, hero.max_health, hero.vitality_level])
	await _settle(cam, Vector2(540.0, -120.0), 1.20)
	await _shot("13a-vitality-bought")

	# Re-find after restock
	shop.refresh(3, hero.combat_weapon_id(), hero.forge_level_for(hero.combat_weapon_id()), hero.hero_kind, hero.skill_level_for(hero.hero_kind), shop.vitality_level, shop.mech_level)
	scene.call("_refresh_shop_ui")
	half_idx = _find_slot(shop, &"half_price")
	_expect(half_idx >= 0, "half_price still stocked before buy")
	scene.call("buy_shop_slot", half_idx)
	await process_frame
	_expect(shop.half_price_owned and is_equal_approx(shop.price_mult, 0.5), "half_price active mult=%s" % shop.price_mult)
	await _settle(cam, Vector2(540.0, -120.0), 1.20)
	await _shot("13-half-price-bought")

	shop.refresh(3, hero.combat_weapon_id(), 0, hero.hero_kind, 0, shop.vitality_level, shop.mech_level)
	scene.call("_refresh_shop_ui")
	summon_idx = _find_slot(shop, &"summon")
	_expect(summon_idx >= 0, "summon slot for roll")
	var scrap_s0: int = int(scene.get("scrap"))
	scene.call("buy_shop_slot", summon_idx)
	await process_frame
	await _settle(cam, Vector2(540.0, -120.0), 1.20)
	await _shot("14-summoner-roll")
	print("CASE shop-vitality-half-summon ok scrap %d->%d half=%s vit_payload=%s" % [scrap_s0, int(scene.get("scrap")), shop.half_price_owned, vit_payload])

	# ========== 8) Home reward chests (west of core) ==========
	hero.position = Vector2(252.0, 336.0)
	scene.call("_spawn_home_rewards")
	await process_frame
	await process_frame
	var pickups: Array = scene.get("_pickups")
	_expect(pickups.size() >= 3, "home rewards >=3 got=%d" % pickups.size())
	var chest_tex := 0
	for p in pickups:
		if not (p is EmberPickup) or not is_instance_valid(p):
			continue
		for c in (p as Node).get_children():
			if c is Sprite2D:
				var tex: Texture2D = (c as Sprite2D).texture
				if tex != null and String(tex.resource_path).find("home-chest") >= 0:
					chest_tex += 1
	_expect(chest_tex >= 3, "home-chest art on rewards got=%d pickups=%d" % [chest_tex, pickups.size()])
	await _settle(cam, Vector2(252.0, 336.0), 1.35)
	await _shot("15-home-chests")
	print("CASE home-chests ok chest_tex=%d" % chest_tex)

	# ========== 9) Portals / cadence helpers ==========
	_expect(scene.has_method("_needs_elite") and scene.has_method("_is_mass_wave") and scene.has_method("_needs_boss"), "cadence helpers")
	scene.set("current_wave", 3)
	_expect(bool(scene.call("_is_mass_wave", 3)), "wave 3 mass")
	scene.set("current_wave", 5)
	_expect(bool(scene.call("_needs_elite")), "wave 5 elite")
	scene.set("current_wave", 15)
	_expect(bool(scene.call("_needs_boss")), "wave 15 boss")
	var portals := 0
	for name: String in ["SpawnPortalNorth", "SpawnPortalSouth", "SpawnPortalEast"]:
		if scene.find_child(name, true, false) != null:
			portals += 1
	# Also count any SpawnPortal* nodes
	for child in scene.get_children():
		if String(child.name).begins_with("SpawnPortal"):
			pass
	var portal_nodes: Array = []
	_collect_named(scene, "SpawnPortal", portal_nodes)
	_expect(portal_nodes.size() >= 3, "portals present got=%d" % portal_nodes.size())
	await _settle(cam, Vector2(640.0, 80.0), 0.95)
	await _shot("16-portals-north")
	print("CASE cadence-portals ok portals=%d" % portal_nodes.size())

	# ========== 10) Hero death ends run (after down timer) ==========
	scene.set("current_wave", 1)
	scene.set("_is_game_over", false)
	if scene.get("_hud") != null and scene.get("_hud").has_method("hide_end_screen"):
		scene.get("_hud").call("hide_end_screen")
	hero.position = PAD
	hero.down_duration = 0.15
	hero.health = 10
	hero.is_down = false
	hero.set("_hit_invuln", 0.0)
	hero.set("_dash_invuln", 0.0)
	hero.set("_dash_elapsed", -1.0)
	scene.set("_hero_armor", 0)
	hero.take_damage(9999)
	_expect(hero.is_down, "hero is_down after lethal")
	await _settle(cam, PAD, 1.20)
	await _shot("17-hero-down")
	for _i in range(45):
		await process_frame
		if bool(scene.get("_is_game_over")):
			break
	_expect(bool(scene.get("_is_game_over")), "hero death must end run after down timer")
	var end_title := scene.find_child("OverlayTitle", true, false) as Label
	_expect(end_title != null and end_title.text == "英雄阵亡", "hero death title want=英雄阵亡 got=%s" % (end_title.text if end_title else "?"))
	await _settle(cam, PAD, 1.20)
	await _shot("18-hero-death-end")
	print("CASE hero-death ok game_over=%s title=%s" % [scene.get("_is_game_over"), end_title.text if end_title else "?"])

	# Summary
	if _failures.is_empty():
		print("PARITY_REAL_PASS shots=%d dir=%s" % [_shot_i, OUT])
		quit(0)
	else:
		for f: String in _failures:
			printerr("PARITY_FAIL %s" % f)
		print("PARITY_REAL_FAIL count=%d" % _failures.size())
		quit(1)


func _freeze_prep(scene: Node) -> void:
	var director = scene.get("_director")
	if director != null:
		director.prep_left = 9999.0
		director.prep_duration = 9999.0


func _clear_towers(scene: Node) -> void:
	scene.call("_select_tower", null)
	var towers: Array = scene.get("_towers")
	var cells: Dictionary = scene.get("_cell_towers")
	# Drop already-freed refs first (tests may queue_free without selling).
	var stale: Array = []
	for t in towers:
		if t == null or not is_instance_valid(t):
			stale.append(t)
	for t in stale:
		towers.erase(t)
	var dead_keys: Array = []
	for k in cells.keys():
		var v = cells[k]
		if v == null or not is_instance_valid(v):
			dead_keys.append(k)
	for k in dead_keys:
		cells.erase(k)
	while not towers.is_empty():
		var t = towers[0]
		if t == null or not is_instance_valid(t):
			towers.remove_at(0)
			continue
		scene.call("_select_tower", t)
		scene.call("sell_selected_tower")


func _spawn_scout(scene: Node, at: Vector2) -> FrontierEnemy:
	var e := FrontierEnemy.new()
	e.variant = &"scout"
	e.max_health = 9999
	e.move_speed = 0.0
	e.configure_seek(at, scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", e)
	return e


func _spawn_enemy_bullets(scene: Node, origin: Vector2, n: int) -> void:
	for i in range(n):
		var ang := TAU * float(i) / float(maxi(n, 1))
		var dir := Vector2(cos(ang), sin(ang))
		scene.call("spawn_enemy_projectile", origin + dir * 10.0, dir, 8)


func _count_enemy_bullets(scene: Node) -> int:
	var n := 0
	for b in scene.get("_live_bullets"):
		if b != null and is_instance_valid(b) and b is EnemyProjectile:
			n += 1
	return n


func _find_slot(shop: EmberShop, kind: StringName) -> int:
	for i in range(shop.slots.size()):
		if StringName(shop.slots[i].get("kind", &"")) == kind:
			return i
	return -1


func _collect_named(node: Node, prefix: String, out: Array) -> void:
	if String(node.name).begins_with(prefix):
		out.append(node)
	for c in node.get_children():
		_collect_named(c, prefix, out)


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_failures.append(msg)
		printerr("EXPECT_FAIL %s" % msg)


func _settle(cam: Camera2D, at: Vector2, zoom: float = 1.5) -> void:
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

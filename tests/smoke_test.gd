extends SceneTree

## Headless smoke test for assets, route connectivity, hero timing, building, and wave flow.
func _init() -> void:
	call_deferred("_run_smoke_test")

func _run_smoke_test() -> void:
	EmberRunSave.delete_run()
	EmberRunSave.delete_records("user://records_smoke.json")
	EmberRunSave.delete_run("user://run_smoke.json")
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	assert(scene.get("scrap") == 300, "Initial scrap should be 300")
	assert(load("res://assets/generated/grid-battlefield-v6.png") != null, "Generated two-route battlefield must load")
	assert(load("res://assets/generated/base/core.png") != null, "Generated core must load")
	assert(load("res://assets/generated/towers/tower-lv1.png") != null, "Tower level 1 asset must load")
	assert(load("res://assets/generated/enemies/scout.png") != null, "Scout asset must load")
	assert(load("res://assets/generated/enemies/brute.png") != null, "Brute asset must load")
	assert(load("res://assets/generated/towers/burst-lv1.png") != null, "Burst tower asset must load")
	assert(load("res://assets/generated/towers/frost-lv1.png") != null, "Frost tower asset must load")
	assert(load("res://assets/generated/enemies/boss.png") != null, "Boss asset must load")
	assert(load("res://assets/generated/enemies/scout-walk-0.png") != null, "Scout walk frames must load")
	assert(load("res://assets/generated/enemies/brute-walk-5.png") != null, "Brute walk frames must load")
	assert(load("res://assets/generated/enemies/boss-walk-3.png") != null, "Boss walk frames must load")
	assert(load("res://assets/generated/enemies/runner.png") != null, "Runner asset must load")
	assert(load("res://assets/generated/enemies/mage-walk-2.png") != null, "Mage walk frames must load")
	assert(load("res://assets/generated/enemies/scout-attack-2.png") != null, "Scout attack frames must load")
	assert(load("res://assets/generated/enemies/brute-attack-2.png") != null, "Brute attack frames must load")
	assert(load("res://assets/generated/enemies/mage-attack-2.png") != null, "Mage attack frames must load")
	assert(load("res://assets/generated/enemies/runner-attack-2.png") != null, "Runner attack frames must load")
	assert(load("res://assets/generated/enemies/boss-attack-2.png") != null, "Boss attack frames must load")
	assert(load("res://assets/generated/fx/core-explode.png") != null, "Core explode asset must load")
	assert(load("res://assets/generated/hero/unarmed-idle.png") != null, "Unarmed hero asset must load")
	assert(load("res://assets/generated/pickups/hold-sword.png") != null, "Held sword asset must load")
	assert(load("res://assets/generated/fx/hero-bullet.png") != null, "Hero bullet asset must load")
	assert(load("res://assets/generated/fx/muzzle.png") != null, "Muzzle flash asset must load")
	assert(load("res://assets/generated/pickups/pistol.png") != null, "Pistol pickup asset must load")
	assert(load("res://assets/generated/pickups/hold-pistol.png") != null, "Held pistol asset must load")
	assert(load("res://assets/generated/pickups/hold-shotgun.png") != null, "Held shotgun asset must load")
	assert(scene.get("MAX_WAVES") == null, "Endless mode must not keep a five-wave win cap")
	assert(scene.get("current_wave") == 0, "A run should start in prep before wave 1")
	assert(not scene.get("_wave_active"), "Prep should not spawn enemies yet")
	var opening_director: WaveDirector = scene.get("_director")
	opening_director.prep_duration = 120.0
	opening_director.prep_left = 120.0
	var shop_panel := scene.find_child("ShopPanel", true, false) as Control
	assert(shop_panel != null and not shop_panel.visible, "Shop should stay closed until the hero talks")
	var attack_probe := FrontierEnemy.new()
	attack_probe.variant = &"scout"
	attack_probe.max_health = 9999
	attack_probe.move_speed = 0.0
	attack_probe.configure_seek(Vector2(400.0, 336.0), Vector2(154.0, 336.0), scene)
	scene.add_child(attack_probe)
	await process_frame
	var attack_frames: Array = attack_probe.get("_attack_frames")
	assert(attack_frames.size() == 6, "Scout should load 6 attack frames")
	var walk_tex: Texture2D = (attack_probe.get("_sprite") as Sprite2D).texture
	attack_probe.play_attack(Vector2.LEFT)
	assert(bool(attack_probe.get("_attacking")), "play_attack should start the clip")
	assert((attack_probe.get("_sprite") as Sprite2D).texture != walk_tex, "Attack should swap off the walk frame")
	attack_probe.queue_free()

	var cheats: Array = scene.get("DEV_CHEATS")
	assert(cheats.size() >= 13, "DEV_CHEATS must list live overlay keys")
	assert(not bool(scene.get("_dev_mode")), "Developer mode starts off")
	scene.call("_toggle_dev_mode")
	assert(bool(scene.get("_dev_mode")), "Toggle helper should enable developer mode")
	var overlay_text := String(scene.call("_dev_overlay_text"))
	var agents_md := FileAccess.get_file_as_string("res://AGENTS.md")
	var claude_md := FileAccess.get_file_as_string("res://CLAUDE.md")
	assert(not agents_md.is_empty(), "AGENTS.md is required project memory")
	assert(agents_md == claude_md, "AGENTS.md and CLAUDE.md must stay identical for every developer model")
	for cheat: Variant in cheats:
		var row: Dictionary = cheat
		var desc := String(row["desc"])
		assert(overlay_text.contains(String(row["label"])), "Overlay missing cheat label %s" % String(row["label"]))
		assert(overlay_text.contains(desc), "Overlay missing cheat desc %s" % desc)
		assert(agents_md.contains(desc), "Project memory missing cheat %s" % desc)
	scene.call("_toggle_dev_mode")
	assert(not bool(scene.get("_dev_mode")), "Toggle helper should close developer mode")
	assert(not bool(scene.get("_dev_god")), "Closing developer mode must clear god mode")

	var route: Dictionary = scene.call("get_route_contract")
	assert(route["is_open"], "Open arena must keep a right-to-core approach")
	assert(route["layout"] == &"open_arena", "Battlefield should be an open Soul Knight-style room")
	assert(route["route_count"] == 0, "Open arena must not use carrot-fantasy lane routes")
	assert(route["spawn_x"] > route["base_entry_x"], "Mirrored spawn must begin beyond the right canvas edge")
	assert(route["base_entry_x"] > route["enemy_goal_x"], "Enemy goal must be inside the mirrored core approach")
	assert(route["enemy_goal_x"] > route["base_x"], "Mirrored core marker must be beyond the enemy goal")

	var hero := scene.get_node("HeroSlot/HeroController") as EmberHero
	scene.call("_spawn_home_rewards")
	var home_loot: Array = scene.get("_pickups")
	assert(home_loot.size() == 3, "Wave-clear home rewards should drop three pickups")
	for loot: Variant in home_loot:
		var pickup: EmberPickup = loot
		assert(pickup.global_position.x < 360.0, "Home rewards must spawn on the core side")
		assert(pickup.global_position.x > 180.0, "Home rewards should sit in the home alcove column")
	hero.global_position = Vector2(252.0, 336.0)
	await process_frame
	scene.call("_process_pickups")
	assert((scene.get("_pickups") as Array).size() < 3, "Walking onto a home reward should collect it")
	for leftover: Variant in (scene.get("_pickups") as Array).duplicate():
		if leftover is EmberPickup and is_instance_valid(leftover):
			(leftover as EmberPickup).queue_free()
	scene.set("_pickups", [])
	scene.set("scrap", 300)
	hero.global_position = Vector2(640.0, 336.0)
	var visible_shelves := 0
	for shelf_index: int in range(6):
		var shelf := scene.find_child("ShopShelf%d" % shelf_index, true, false) as Sprite2D
		if shelf != null and shelf.visible and shelf.texture != null:
			visible_shelves += 1
	assert(visible_shelves >= 3, "NPC shop shelves should display current stock")
	var hero_bounds := hero.get_movement_bounds()
	assert(hero_bounds.size.x >= 900.0 and hero_bounds.size.y >= 400.0, "Hero should have a broad open movement area")
	var hero_start := hero.position
	hero.move_in_direction(Vector2.LEFT, 0.25)
	assert(hero.position.x < hero_start.x, "Hero should move horizontally through the mirrored defense room")
	var hero_after_horizontal := hero.position
	hero.move_in_direction(Vector2.DOWN, 0.25)
	assert(hero.position.y > hero_after_horizontal.y, "Hero should move vertically across the open room")

	assert(scene.has_node("HeroSlot/HeroController/XSXBHeroActor"), "Gameplay hero must instantiate the XSXB runtime actor")
	var xsxb_actor := scene.get_node("HeroSlot/HeroController/XSXBHeroActor")
	if xsxb_actor.has_method("animation_frame_count"):
		var run_frame_count := int(xsxb_actor.call("animation_frame_count", "run"))
		assert(run_frame_count >= 30 and run_frame_count <= 31, "Run animation should stay near the trimmed loop length")
		assert(int(xsxb_actor.call("animation_frame_count", "jump")) == 7, "XSXB jump must use the first hop only")
		assert(int(xsxb_actor.call("animation_frame_count", "attack")) == 20, "XSXB attack must use the trimmed two-hit unarmed frames")
	assert(float(xsxb_actor.call("animation_duration", "jump")) <= 1.05, "XSXB jump must stay short and continuous")
	assert(float(xsxb_actor.call("animation_duration", "attack")) <= 2.2, "Full two-slash clip should stay under 2.2 seconds")

	scene.call("_set_hero_state", &"run")
	assert(scene.get("_hero_state") == &"run", "Hero should switch to run state")
	scene.call("_set_hero_state", &"jump")
	assert(scene.get("_hero_state") == &"jump", "Hero should switch to jump state")
	await create_timer(1.15).timeout
	assert(scene.get("_hero_state") == &"idle", "Jump should return to idle within 1.15 seconds")

	var jump_event := InputEventKey.new()
	jump_event.keycode = KEY_K
	jump_event.pressed = true
	scene.call("_input", jump_event)
	assert(scene.get("_hero_state") == &"jump", "K should trigger the short jump")
	await create_timer(1.0).timeout

	var attack_event := InputEventKey.new()
	attack_event.keycode = KEY_J
	attack_event.pressed = true
	scene.call("_input", attack_event)
	assert(scene.get("_hero_state") == &"attack", "J should trigger hero attack")
	await create_timer(1.2).timeout
	assert(hero.total_attack_hits_emitted == 1, "A single J press should play only the first slash")
	assert(scene.get("_hero_state") == &"idle", "A single slash should return to idle quickly")
	hero.request_attack()
	await create_timer(0.35).timeout
	hero.request_attack()
	await create_timer(1.8).timeout
	assert(hero.total_attack_hits_emitted == 2, "A second J in the combo window should play the follow-up slash")
	assert(scene.get("_hero_state") == &"idle", "Follow-up slash should return to idle")

	var attack_button := scene.find_child("AttackButton", true, false) as Button
	var jump_button := scene.find_child("JumpButton", true, false) as Button
	var upgrade_button := scene.find_child("UpgradeButton", true, false) as Button
	assert(attack_button != null, "HUD should expose an attack button")
	assert(jump_button != null, "HUD should expose a dedicated jump button")
	assert(scene.find_child("MoveStick", true, false) != null, "Mobile virtual stick should be present")
	assert(scene.find_child("TalkButton", true, false) != null, "Talk virtual button should be present")
	assert(upgrade_button != null, "HUD should expose an upgrade button")
	assert(attack_button.text.begins_with("攻击"), "Attack button should be shown in Simplified Chinese")
	assert(jump_button.text.begins_with("跳跃"), "Jump button should be shown in Simplified Chinese")
	assert(upgrade_button.text.begins_with("升级"), "Upgrade button should be shown in Simplified Chinese")
	attack_button.emit_signal("pressed")
	assert(scene.get("_hero_state") == &"attack", "Attack button should trigger hero attack")
	await create_timer(1.2).timeout
	assert(hero.total_attack_hits_emitted == 1, "Chinese attack button should play a single slash")
	assert(scene.get("_hero_state") == &"idle", "Attack button slash should finish before jump")
	jump_button.emit_signal("pressed")
	assert(scene.get("_hero_state") == &"jump", "Chinese jump button should trigger hero jump")
	await create_timer(1.0).timeout

	scene.call("_try_place_tower", Vector2(990.0, 205.0))
	assert(scene.get("_towers").size() == 1, "A tower should be placed on the first pad")
	assert(scene.get("scrap") == 220, "Tower placement should cost 80 scrap")
	scene.call("_try_place_tower", Vector2(990.0, 205.0))
	var selected_tower: EmberTower = scene.get("_selected_tower")
	assert(selected_tower != null, "Clicking an occupied pad should select the tower")
	scene.call("upgrade_selected_tower")
	assert(selected_tower.level == 2, "Selected tower should upgrade to level 2")
	assert(selected_tower.attack_damage == 38, "Level 2 tower should deal more damage")
	assert(scene.get("scrap") == 110, "Level 2 upgrade should cost 110 scrap")

	scene.set("scrap", 500)
	scene.set("default_tower_kind", &"burst")
	scene.call("_try_place_tower", Vector2(820.0, 205.0))
	scene.set("default_tower_kind", &"frost")
	scene.call("_try_place_tower", Vector2(650.0, 205.0))
	var towers: Array = scene.get("_towers")
	assert(towers.size() == 3, "Pulse, burst, and frost towers should all place")
	assert(towers[1].kind == &"burst", "Second pad should hold a burst tower")
	assert(towers[2].kind == &"frost", "Third pad should hold a frost tower")
	scene.set("scrap", 800)
	scene.call("_try_place_tower", Vector2(456.0, 216.0))
	scene.call("_try_place_tower", Vector2(456.0, 456.0))
	scene.call("_try_place_tower", Vector2(648.0, 456.0))
	scene.call("_try_place_tower", Vector2(840.0, 456.0))
	scene.call("_try_place_tower", Vector2(888.0, 360.0))
	assert((scene.get("_towers") as Array).size() == 8, "Eight pads should all accept a tower")
	var before_ninth: int = (scene.get("_towers") as Array).size()
	var scrap_before_ninth: int = int(scene.get("scrap"))
	scene.call("_try_place_tower", Vector2(720.0, 336.0))
	assert((scene.get("_towers") as Array).size() == before_ninth, "A ninth tower must fail")
	assert(int(scene.get("scrap")) == scrap_before_ninth, "Failed ninth placement must not spend scrap")
	scene.call("_try_place_tower", Vector2(990.0, 205.0))
	scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).size() == 7, "Selling should free a pad")
	assert(int(scene.get("scrap")) == scrap_before_ninth + 48, "Pulse sell refund is 60% of build cost")
	scene.call("_try_place_tower", Vector2(990.0, 205.0))
	assert((scene.get("_towers") as Array).size() == 8, "Freed pad should accept a new tower")
	scene.call("_try_place_tower", Vector2(888.0, 360.0))
	scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).size() == 7, "Pad 7 should be empty for the combat placement probe")

	var melee_hits := hero.total_attack_hits_emitted
	var held := hero.find_child("HeldWeapon", true, false) as Sprite2D
	assert(held != null and held.texture != null and held.visible, "Starter hero should hold the greatsword overlay")
	assert(String(WeaponCatalog.get_def(&"sword")["display_name"]) == "大宝剑", "Starter weapon display name is 大宝剑")
	assert(load(String(WeaponCatalog.get_def(&"sword")["fx_path"])) != null, "Starter sword must have a slash FX")
	scene.call("_play_attack")
	var saw_slash := false
	for _i: int in range(24):
		await create_timer(0.03).timeout
		if scene.find_child("MeleeSlash", true, false) != null:
			saw_slash = true
			break
	assert(saw_slash, "Greatsword J should spawn a melee slash")
	await create_timer(0.55).timeout
	melee_hits = hero.total_attack_hits_emitted
	hero.equip_weapon(&"pistol")
	assert(held.texture != null, "Equipped pistol should show a held-weapon sprite")
	assert(hero.weapon_slots[0] == &"sword" and hero.weapon_slots[1] == &"pistol", "Pistol should fill the second Soul Knight slot")
	assert(hero.current_weapon == &"pistol", "Newly equipped gun becomes active")
	assert(hero.cycle_weapon() and hero.current_weapon == &"sword", "Q-cycle should return to the sword")
	assert(hero.cycle_weapon() and hero.current_weapon == &"pistol", "Second cycle should restore the pistol")
	var dock0 := scene.find_child("WeaponSlot0", true, false) as Button
	assert(dock0 != null, "HUD should show a persistent weapon dock")
	scene.call("_play_attack")
	assert(hero.ranged_shots_emitted == 1, "Pistol J should fire a hero bullet")
	assert(hero.total_attack_hits_emitted == melee_hits, "Pistol fire must not play the two-slash melee")
	assert(scene.find_child("MuzzleFlash", true, false) != null, "Ranged fire should spawn a muzzle flash")
	assert(load("res://assets/generated/weapons/pistol.png") != null, "New pistol hold art must load")
	assert(load("res://assets/generated/weapon-fx/pistol.png") != null, "Pistol attack FX must load")
	assert(WeaponCatalog.all_ids().size() >= 57, "Weapon catalog should include the imported sheet")
	assert(WeaponCatalog.has_id(&"azure-blade"), "Catalog should include azure-blade")
	assert(not WeaponCatalog.has_id(&"pulse-pistol"), "FX-only pulse-pistol has no weapon sprite")
	var pistol_def := WeaponCatalog.get_def(&"pistol")
	var ion_def := WeaponCatalog.get_def(&"ion-pistol")
	assert(float(pistol_def["hold_scale"]) <= 0.50, "Pistol hold should stay smaller than the hero")
	assert(float(ion_def["hold_scale"]) <= 0.36, "Large gun art must be scaled down to the same hand size")
	assert(float(pistol_def["fx_scale"]) <= 0.28, "Pistol bullets should stay small tracers")
	assert(float(ion_def["fx_scale"]) <= 0.24, "Ion bolts should not dwarf the hero")
	var gatling_def := WeaponCatalog.get_def(&"gatling")
	assert(float(gatling_def["hold_scale"]) * 114.0 >= 34.0, "Long guns like gatling should read larger than a pocket pistol")
	hero.equip_weapon(&"azure-blade")
	assert(held.texture != null and held.visible, "New melee weapons should show a held overlay")
	scene.call("_play_attack")
	await create_timer(1.2).timeout
	assert(hero.total_attack_hits_emitted == 1, "New melee should still play the slash combo")
	hero.equip_weapon(&"pistol")

	hero.down_duration = 0.25
	hero.take_damage(999)
	assert(hero.is_down, "Fatal damage should down the hero")
	assert(hero.current_state == &"down", "Down should play the death clip")
	await create_timer(0.45).timeout
	assert(not hero.is_down, "Hero should revive after the injected down duration")
	assert(hero.health == 40, "Revive should restore 40 health")
	hero.unlock_dash()
	hero.request_dash()
	assert(hero.has_dash and hero.current_state == &"dash", "Unlocked dash should play the skill clip")

	var route_probes: Array[FrontierEnemy] = []
	for route_points: PackedVector2Array in route["routes"]:
		var probe := FrontierEnemy.new()
		probe.variant = &"scout"
		probe.max_health = 9999
		probe.move_speed = 1800.0
		probe.configure_route(route_points)
		route_probes.append(probe)
		scene.add_child(probe)
	await create_timer(1.0).timeout
	for probe: FrontierEnemy in route_probes:
		assert(not is_instance_valid(probe), "Enemies crossing the open floor should reach the core")

	hero.is_down = false
	hero.global_position = Vector2(700.0, 336.0)
	assert(scene.call("enemy_target_position", Vector2(700.0, 500.0)) == Vector2(154.0, 336.0), "Queries without an enemy must return the core")
	var far_probe := FrontierEnemy.new()
	far_probe.variant = &"scout"
	far_probe.max_health = 9999
	far_probe.move_speed = 220.0
	far_probe.configure_seek(Vector2(700.0, 500.0), Vector2(154.0, 336.0), scene)
	scene.add_child(far_probe)
	await create_timer(0.05).timeout
	assert(not bool(far_probe.get("_aggro")), "An enemy 164px from the hero must walk to the core")
	assert(far_probe.global_position.y > 430.0, "Core-seeking enemy must not chase from (700,500)")
	far_probe.queue_free()
	var near_probe := FrontierEnemy.new()
	near_probe.variant = &"scout"
	near_probe.max_health = 9999
	near_probe.move_speed = 220.0
	near_probe.configure_seek(Vector2(700.0, 416.0), Vector2(154.0, 336.0), scene)
	scene.add_child(near_probe)
	await create_timer(0.05).timeout
	assert(bool(near_probe.get("_aggro")), "An enemy 80px from the hero should aggro")
	hero.global_position = Vector2(700.0, 160.0)
	await create_timer(0.45).timeout
	assert(not bool(near_probe.get("_aggro")), "Teleporting the hero outside 144px for 0.40s should drop aggro")
	near_probe.queue_free()
	hero.global_position = Vector2(154.0, 336.0)
	var tank_probe := FrontierEnemy.new()
	tank_probe.variant = &"scout"
	tank_probe.max_health = 9999
	tank_probe.move_speed = 1.0
	tank_probe.configure_seek(Vector2(174.0, 336.0), Vector2(154.0, 336.0), scene)
	scene.add_child(tank_probe)
	var core_before := int(scene.get("core_health"))
	await create_timer(0.12).timeout
	assert(int(scene.get("core_health")) == core_before, "Aggroed enemy on the crystal must not leak")
	tank_probe.queue_free()
	hero.global_position = Vector2(700.0, 336.0)
	var leak_probe := FrontierEnemy.new()
	leak_probe.variant = &"scout"
	leak_probe.max_health = 9999
	leak_probe.core_damage = 1
	leak_probe.move_speed = 80.0
	leak_probe.configure_seek(Vector2(180.0, 336.0), Vector2(154.0, 336.0), scene)
	scene.call("_register_enemy", leak_probe)
	await create_timer(0.12).timeout
	assert(int(scene.get("core_health")) == core_before - 1, "Unaggroed enemy at 22px must leak")
	if is_instance_valid(leak_probe):
		leak_probe.queue_free()

	var pile_a := FrontierEnemy.new()
	var pile_b := FrontierEnemy.new()
	pile_a.max_health = 9999
	pile_b.max_health = 9999
	pile_a.move_speed = 90.0
	pile_b.move_speed = 90.0
	pile_a.configure_seek(Vector2(520.0, 336.0), Vector2(154.0, 336.0), scene)
	pile_b.configure_seek(Vector2(520.0, 338.0), Vector2(154.0, 336.0), scene)
	scene.add_child(pile_a)
	scene.add_child(pile_b)
	await create_timer(0.55).timeout
	assert(pile_a.global_position.distance_to(pile_b.global_position) >= 18.0, "Stacked enemies should push apart instead of occupying the same tile")
	pile_a.queue_free()
	pile_b.queue_free()

	hero.position = Vector2(40.0, 336.0)
	hero.move_in_direction(Vector2.LEFT, 0.40)
	assert(hero.position.x < 76.0, "Hero should walk west of the core")
	hero.position = Vector2(320.0, 140.0)
	hero.move_in_direction(Vector2.UP, 0.90)
	assert(hero.position.y < 112.0, "Hero should walk north through the merchant door")
	var trainer := scene.find_child("NpcTrainer", true, false) as Sprite2D
	assert(trainer != null, "Trainer should stand in the north trainer room")
	hero.position = Vector2(800.0, -80.0)
	hero.move_in_direction(Vector2.UP, 0.35)
	var trainer_body: Vector2 = trainer.get_meta("rest_pos", trainer.global_position) + Vector2(0.0, 24.0)
	assert(hero.position.distance_to(trainer_body) >= 34.0, "Hero should collide with the trainer instead of walking through")
	assert(scene.find_child("NpcMerchant", true, false) != null, "Merchant should stand in the north merchant room")
	assert(scene.find_child("ShopPen", true, false) != null, "Home shop rooms should still expose ShopPen")
	assert(scene.find_child("MiniMap", true, false) != null, "HUD should show a mini-map")

	hero.position = Vector2(320.0, -110.0)
	assert(bool(scene.call("try_talk_to_nearby_npc")), "Standing next to the merchant should allow talking")
	assert(shop_panel.visible, "Talking to the merchant should open their stall")
	hero.position = Vector2(800.0, -110.0)
	assert(bool(scene.call("try_talk_to_nearby_npc")), "Standing next to the trainer should switch stalls")
	assert(shop_panel.visible, "Talking to the trainer should keep a stall open")

	scene.call("start_wave")
	assert(not shop_panel.visible, "Combat should close the stall panel")
	assert(hero.position.y < 0.0, "Combat should not eject the hero from north shop rooms")
	assert(not bool(scene.call("is_shop_gate_open")), "Combat should close the shop gate")
	assert(scene.get("current_wave") == 1, "First wave should start at wave 1")
	assert(scene.get("_wave_active"), "Wave should be active after launch")
	var combat_towers: int = (scene.get("_towers") as Array).size()
	scene.call("_try_place_tower", Vector2(900.0, 380.0))
	assert((scene.get("_towers") as Array).size() == combat_towers + 1, "Combat should allow placing towers on an empty pad")
	await create_timer(1.35).timeout
	assert(scene.get("_enemies").size() > 0, "Wave should spawn enemies")
	await create_timer(6.0).timeout
	assert(scene.get("defeated_count") > 0, "Tower projectile loop should defeat at least one enemy")

	scene.set("core_health", 0)
	scene.call("_explode_core")
	var burst := scene.find_child("CoreBurst", true, false) as Sprite2D
	assert(burst != null and burst.visible, "Core loss should play a crystal explosion")
	await create_timer(1.15).timeout
	var overlay_title := scene.find_child("OverlayTitle", true, false) as Label
	var overlay_body := scene.find_child("OverlayBody", true, false) as Label
	assert(overlay_title != null, "End overlay should expose a title")
	assert(overlay_title.text == "核心失守", "Endless failure text should not be a five-wave victory")
	assert(overlay_body != null and overlay_body.text.contains("存活时间"), "End screen should report survival time")

	var auto_scene: Node = load("res://main.tscn").instantiate()
	root.add_child(auto_scene)
	await process_frame
	var director: WaveDirector = auto_scene.get("_director")
	director.prep_duration = 0.2
	director.prep_left = 0.2
	await create_timer(0.55).timeout
	assert(auto_scene.get("current_wave") == 1, "Injected prep should auto-start wave 1")
	assert(auto_scene.get("_wave_active"), "Combat should begin after the short prep timer")
	var auto_shop := auto_scene.find_child("ShopPanel", true, false) as Control
	assert(auto_shop != null and not auto_shop.visible, "Shop should close when prep auto-starts combat")
	auto_scene.queue_free()
	EmberRunSave.write_run({
		"version": 1,
		"cleared_wave": 2,
		"scrap": 400,
		"core_health": 8,
		"run_time": 30.0,
		"defeated_count": 12,
		"default_tower_kind": "pulse",
		"hero": {
			"health": 80, "max_health": 100, "weapon": "sword",
			"has_dash": false, "attack_bonus_level": 0,
			"vitality_level": 0, "dash_cd_level": 0,
			"position": [640.0, 336.0],
		},
		"towers": [],
		"drop_rng_state": 1,
		"shop_rng_state": 1,
		"slots": [{"kind": "tower", "payload": "pulse", "cost": 86, "sold": false, "vendor": "merchant", "title": "脉冲塔"}],
	}, "user://run_smoke.json")
	var loaded_run := EmberRunSave.load_run("user://run_smoke.json")
	assert(not loaded_run.is_empty() and int(loaded_run.get("cleared_wave", 0)) == 2, "Smoke save path should round-trip")
	EmberRunSave.update_records(2, 12, 30.0, "user://records_smoke.json")
	var records := EmberRunSave.load_records("user://records_smoke.json")
	assert(int(records.get("highest_wave", 0)) == 2, "Records smoke path should store high-water wave")
	EmberRunSave.delete_run("user://run_smoke.json")
	EmberRunSave.delete_records("user://records_smoke.json")
	print("SMOKE TEST PASS: endless prep/shop, three towers, pistol fire, hero revive, routes, and core-loss ending")
	quit()

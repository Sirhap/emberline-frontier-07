extends SceneTree

const EXPECTED_CORE_GOAL := Vector2(154.0, 336.0)

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
	assert(FileAccess.file_exists("res://assets/fonts/cjk-ui.ttf"), "Web HUD needs a bundled CJK font")
	assert(FileAccess.file_exists("res://assets/generated/ui/skill-interact.png"), "Skill slot needs the pixel interact icon")
	assert(FileAccess.file_exists("res://export/web/emberline.html"), "Web export needs the mobile fullscreen HTML shell")
	var shell_file := FileAccess.open("res://export/web/emberline.html", FileAccess.READ)
	assert(shell_file != null, "Custom HTML shell should be readable")
	var shell := shell_file.get_as_text()
	shell_file.close()
	assert(not shell.contains("rel=\"preload\""), "Custom HTML shell must not add wasm/pck preload tags")
	assert(not shell.contains("index.wasm"), "Custom HTML shell must not mention index.wasm")
	assert(not shell.contains("index.pck"), "Custom HTML shell must not mention index.pck")
	assert(shell.contains("$GODOT_URL"), "Custom HTML shell must keep the Godot JS placeholder")
	assert(shell.contains("emberlineFullscreen"), "Custom HTML shell should ship the mobile fullscreen helper")
	assert(shell.contains("viewport-fit=cover"), "iOS fallback needs viewport-fit=cover")
	assert(shell.contains("apple-mobile-web-app-capable"), "iOS standalone meta should be present")
	assert(shell.contains("100dvh"), "Canvas should use dynamic viewport height")
	var presets_file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	assert(presets_file != null, "export_presets.cfg should be readable")
	var presets := presets_file.get_as_text()
	presets_file.close()
	assert(presets.contains("html/head_include=\"\""), "head_include must stay empty of preload tags")
	assert(presets.contains("html/custom_html_shell=\"res://export/web/emberline.html\""), "Web export should use the mobile fullscreen shell")
	assert(not presets.contains("index.wasm"), "export_presets must not add wasm preload")
	assert(not presets.contains("index.pck"), "export_presets must not add pck preload")
	assert(FileAccess.file_exists("res://xsxb_frame_tuner/workspace/projects/emberline_enemies/assets/ember_assassin/down/frame_0001.png"), "Assassin down frames must exist")
	assert(load("res://assets/generated/enemies/scout-attack-2.png") != null, "Scout attack frames must load")
	assert(load("res://assets/generated/enemies/brute-attack-2.png") != null, "Brute attack frames must load")
	assert(load("res://assets/generated/enemies/mage-attack-2.png") != null, "Mage attack frames must load")
	assert(load("res://assets/generated/enemies/runner-attack-2.png") != null, "Runner attack frames must load")
	assert(load("res://assets/generated/enemies/boss-attack-2.png") != null, "Boss attack frames must load")
	assert(load("res://assets/generated/hero/assassin.png") != null, "Assassin hero portrait must load")
	assert(load("res://assets/generated/hero/assassin-skill-4.png") != null, "Assassin skill-cast frames must load")
	assert(load("res://assets/generated/hero/assassin-bubble-4.png") != null, "Assassin bubble frames must load")
	assert(load("res://assets/generated/enemies/boss-walk-7.png") != null, "Boss 8-frame walk must load")
	assert(load("res://assets/generated/fx/core-explode.png") != null, "Core explode asset must load")
	assert(FileAccess.file_exists("res://assets/generated/fx/portal/frame_0.png"), "Portal frame 0 must exist")
	assert(FileAccess.file_exists("res://assets/generated/fx/portal/frame_7.png"), "Portal frame 7 must exist")
	assert(FileAccess.file_exists("res://assets/generated/fx/portal/arch.png"), "Portal wall arch must exist")
	assert(FileAccess.file_exists("res://assets/generated/fx/portal/sealed.png"), "Sealed portal plug must exist")
	assert(FileAccess.file_exists("res://assets/generated/fx/door-frame.png"), "Shop/mouth door frame must exist")
	assert(FileAccess.file_exists("res://assets/generated/fx/mouth-frame.png"), "North/south mouth frame must exist")
	assert(FileAccess.file_exists("res://assets/generated/fx/wall-h.png"), "Grid-aligned wall-h stamp must exist")
	assert(FileAccess.file_exists("res://assets/generated/fx/wall-v.png"), "Grid-aligned wall-v stamp must exist")
	assert(FileAccess.file_exists("res://assets/generated/fx/door-jamb-l.png"), "Door jamb left must exist")
	assert(FileAccess.file_exists("res://assets/generated/fx/door-jamb-r.png"), "Door jamb right must exist")
	assert(FileAccess.file_exists("res://assets/generated/ui/dash.png"), "Dash HUD icon must exist")
	assert(FileAccess.file_exists("res://assets/generated/ui/attack.png"), "Attack HUD icon must exist")
	assert(load("res://assets/generated/ui/portrait-knight.png") != null, "Knight HUD portrait must load")
	assert(load("res://assets/generated/ui/portrait-assassin.png") != null, "Assassin HUD portrait must load")
	assert(load("res://assets/generated/ui/skill-clone.png") != null, "Assassin clone skill icon must load")
	assert(load("res://assets/generated/ui/attack-daggers.png") != null, "Assassin dagger attack icon must load")
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
	assert(is_equal_approx(opening_director.prep_duration, 50.0), "Prep duration must be 50s")
	var prep_hud := scene.find_child("PrepCountdown", true, false) as Label
	assert(prep_hud != null and prep_hud.text.contains("50"), "HUD countdown should start at 50")
	assert(scene.find_child("ScrapChip", true, false) != null, "Top-row scrap chip should be present")
	assert(scene.find_child("WarehouseButton", true, false) != null, "Warehouse HUD button should be present")
	opening_director.prep_duration = 120.0
	opening_director.prep_left = 120.0
	var shop_panel := scene.find_child("ShopPanel", true, false) as Control
	assert(shop_panel != null and not shop_panel.visible, "Shop should stay closed until the hero talks")
	var attack_probe := FrontierEnemy.new()
	attack_probe.variant = &"scout"
	attack_probe.max_health = 9999
	attack_probe.move_speed = 0.0
	attack_probe.configure_seek(Vector2(400.0, 336.0), scene.call("core_goal") as Vector2, scene)
	scene.add_child(attack_probe)
	await process_frame
	var attack_frames: Array = attack_probe.get("_attack_frames")
	assert(attack_frames.size() == 6, "Scout should load 6 attack frames")
	var walk_tex: Texture2D = (attack_probe.get("_sprite") as Sprite2D).texture
	attack_probe.play_attack(Vector2.LEFT)
	assert(bool(attack_probe.get("_attacking")), "play_attack should start the clip")
	assert((attack_probe.get("_sprite") as Sprite2D).texture != walk_tex, "Attack should swap off the walk frame")
	assert(not bool(attack_probe.call("consume_contact_hit")), "Windup frames must not deal contact damage")
	attack_probe.set("_attack_index", 2)
	assert(bool(attack_probe.call("consume_contact_hit")), "Visible hit frame should release contact damage")
	assert(not bool(attack_probe.call("consume_contact_hit")), "Contact hit should fire once per attack")
	attack_probe.max_health = 1
	attack_probe.health = 1
	attack_probe.take_damage(99, &"hero")
	assert(not attack_probe.is_active(), "Lethal damage should mark the enemy inactive")
	assert(is_instance_valid(attack_probe), "Defeat should keep a readable corpse before removal")
	assert(bool(attack_probe.get("_dying")), "Defeat should play a short death settle")
	attack_probe.queue_free()
	var mage_probe := FrontierEnemy.new()
	mage_probe.variant = &"mage"
	mage_probe.max_health = 9999
	mage_probe.move_speed = 0.0
	mage_probe.contact_damage = 10
	mage_probe.configure_seek(Vector2(480.0, 336.0), scene.call("core_goal") as Vector2, scene)
	scene.add_child(mage_probe)
	await process_frame
	assert(bool(mage_probe.call("is_ranged")), "Mage should be the ranged enemy")
	var mage_shots: Array = []
	mage_probe.shot_fired.connect(func(_enemy, _dir, dmg): mage_shots.append(dmg))
	mage_probe.play_attack(Vector2.LEFT, true)
	assert(bool(mage_probe.get("_shot_pending")), "Ranged mage attack should arm a shot")
	mage_probe.call("_advance_attack", 0.25)
	assert(mage_shots.size() == 1, "Mage hit frame should fire a shot")
	assert(int(mage_shots[0]) == 10, "Mage shot should use contact_damage")
	scene.call("spawn_enemy_projectile", mage_probe.global_position, Vector2.LEFT, 8)
	var live_bullets: Array = scene.get("_live_bullets")
	var has_enemy_bullet := false
	for bullet: Variant in live_bullets:
		if bullet is EnemyProjectile:
			has_enemy_bullet = true
			break
	assert(has_enemy_bullet, "Mage shots should spawn through the shared bullet pool")
	mage_probe.queue_free()
	assert(scene.find_child("HeroSelect_assassin", true, false) != null, "HUD should expose assassin select")
	assert(scene.find_child("HeroSelect_ember_hero", true, false) != null, "HUD should expose knight select")
	assert(scene.find_child("DefaultTowerButton", true, false) == null, "Default-tower HUD button must be gone")

	var cheats: Array = scene.get("DEV_CHEATS")
	assert(cheats.size() >= 20, "DEV_CHEATS must list live overlay keys")
	assert(not bool(scene.get("_dev_mode")), "Developer mode starts off")
	scene.call("_toggle_dev_mode")
	assert(bool(scene.get("_dev_mode")), "Toggle helper should enable developer mode")
	var dev_minimap := scene.find_child("MiniMap", true, false) as Control
	assert(dev_minimap != null and not dev_minimap.visible, "Developer overlay should suppress the secondary mini-map")
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
	var switched := scene.get_node("HeroSlot/HeroController") as EmberHero
	scene.call("_dev_toggle_hero")
	assert(switched.hero_kind == &"assassin", "H should switch the hero to assassin")
	assert(String(scene.call("_dev_overlay_text")).contains("刺客"), "Overlay should show the current assassin label")
	scene.call("_dev_toggle_hero")
	assert(switched.hero_kind == &"ember_hero", "H again should restore the knight")
	assert(not bool(scene.call("_handle_dev_key", KEY_Z)), "Keys outside DEV_CHEATS must not dispatch")
	var scrap_before_cheat: int = int(scene.get("scrap"))
	scene.call("_dev_add_scrap")
	assert(int(scene.get("scrap")) == scrap_before_cheat + 500, "1 should add 500 scrap")
	scene.set("scrap", scrap_before_cheat)
	assert(bool(scene.call("_handle_dev_key", KEY_T)), "T should dispatch from DEV_CHEATS")
	assert(int(switched.turret_stash.get(&"pulse", 0)) == 1, "T should grant one pulse into the turret stash")
	assert(not switched.turret_hand, "Granting a turret must not auto-enter turret-hand")
	assert(bool(scene.call("_handle_dev_key", KEY_Y)), "Y should dispatch from DEV_CHEATS")
	assert(switched.turret_hand, "Y should select turret-hand when the stash is not empty")
	assert(String(scene.call("_dev_overlay_text")).contains("炮台手 开"), "Overlay should show turret-hand on")
	scene.call("_dev_toggle_turret_hand")
	assert(not switched.turret_hand, "Y again should leave turret-hand")
	assert(switched.forge_level_for(&"sword") == 0, "Starter sword starts unforged")
	assert(bool(scene.call("_handle_dev_key", KEY_F)), "F should dispatch from DEV_CHEATS")
	assert(switched.forge_level_for(&"sword") == 1, "F should bump the current weapon forge")
	assert(switched.skill_level_for(&"ember_hero") == 0, "Starter knight skill starts at 0")
	assert(switched.floating_weapon_count() == 1, "Knight skill_level 0 should orbit one copy")
	assert(bool(scene.call("_handle_dev_key", KEY_N)), "N should dispatch from DEV_CHEATS")
	assert(switched.skill_level_for(&"ember_hero") == 1, "N should bump knight skill to 1")
	assert(switched.floating_weapon_count() == 2, "Knight skill_level 1 should orbit two copies")
	scene.call("_dev_bump_skill")
	assert(switched.skill_level_for(&"ember_hero") == 2 and switched.floating_weapon_count() == 3, "Second N should reach three orbiting copies")
	scene.call("_dev_bump_skill")
	assert(switched.skill_level_for(&"ember_hero") == 2, "Knight skill_level caps at 2")
	scene.call("_dev_toggle_hero")
	assert(switched.clone_count() == 3, "Assassin clones start at 3")
	scene.call("_dev_bump_skill")
	assert(switched.skill_level_for(&"assassin") == 1, "N on assassin should bump clone skill")
	assert(switched.clone_count() == 4, "Assassin clones should be 3 + skill_level")
	assert(switched.floating_weapon_count() == 1, "Assassin skill must not add extra floating guns")
	scene.call("_dev_toggle_hero")
	assert(switched.hero_kind == &"ember_hero", "H should restore the knight after skill cheats")
	assert(bool(scene.call("_handle_dev_key", KEY_G)), "G should dispatch from DEV_CHEATS")
	assert(switched.current_weapon == &"pistol", "G should put a pistol in a dual slot")
	assert(switched.weapon_slots.has(&"pistol"), "G should keep the pistol in a weapon slot")
	scene.call("_dev_equip_shotgun")
	assert(switched.current_weapon == &"shotgun", "B should equip a shotgun")
	scene.call("_dev_equip_pistol")
	assert(switched.current_weapon == &"pistol", "G should leave a pistol in the active slot for mount")
	var enemies_before_spawn: int = (scene.get("_enemies") as Array).size()
	scene.call("_dev_spawn_scout")
	assert((scene.get("_enemies") as Array).size() == enemies_before_spawn + 1, "5 should spawn a scout")
	scene.call("_dev_clear_enemies")
	assert((scene.get("_enemies") as Array).is_empty(), "8 should clear spawned enemies")
	assert(bool(scene.call("_handle_dev_key", KEY_P)), "P should dispatch from DEV_CHEATS")
	assert((scene.get("_towers") as Array).size() == 16, "P should place stash pulses up to TOWER_CAP")
	assert(int(switched.turret_stash.get(&"pulse", 0)) == 1, "P should spend granted pulses and leave the extra T in stash")
	var planted_pulse := 0
	for planted_item: Variant in scene.get("_towers"):
		if planted_item is EmberTower and (planted_item as EmberTower).kind == &"pulse":
			planted_pulse += 1
	assert(planted_pulse == 16, "P should place pulse cannons, not scrap-build a default tower")
	assert(bool(scene.call("_handle_dev_key", KEY_M)), "M should dispatch from DEV_CHEATS")
	var mounted: EmberTower = scene.get("_selected_tower")
	assert(mounted != null and mounted.weapon_id == &"pistol", "M should mount the current weapon onto a cannon")
	assert(not switched.weapon_slots.has(&"pistol"), "Mounting should take the pistol out of the dual slots")
	while not (scene.get("_towers") as Array).is_empty():
		scene.call("_select_tower", (scene.get("_towers") as Array)[0])
		scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).is_empty(), "Cheat cleanup must sell every placed cannon")
	scene.set("scrap", 300)
	switched.equip_weapon(&"sword")
	switched.weapon_slots[1] = &""
	switched.weapon_slot_index = 0
	switched.current_weapon = &"sword"
	switched.weapon_forge.clear()
	switched.skill_levels[&"ember_hero"] = 0
	switched.skill_levels[&"assassin"] = 0
	switched.turret_stash.clear()
	switched.set_turret_hand(false)
	switched.melee_damage = switched.melee_strike_damage()
	scene.call("_sync_weapon_hud")
	scene.call("_toggle_dev_mode")
	assert(not bool(scene.get("_dev_mode")), "Toggle helper should close developer mode")
	assert(not bool(scene.get("_dev_god")), "Closing developer mode must clear god mode")
	assert(dev_minimap.visible, "Closing the developer overlay should restore the mini-map")

	var route: Dictionary = scene.call("get_route_contract")
	assert(scene.call("core_goal") == EXPECTED_CORE_GOAL, "Enemy core goal must stay fixed at (154, 336)")
	assert(route["is_open"], "Open arena must keep a right-to-core approach")
	assert(route["layout"] == &"open_arena", "Battlefield should be an open Soul Knight-style room")
	assert(route["route_count"] == 0, "Open arena must not use carrot-fantasy lane routes")
	assert(route["spawn_x"] > route["base_entry_x"], "Mirrored spawn must begin beyond the right canvas edge")
	assert(route["base_entry_x"] > route["enemy_goal_x"], "Enemy goal must be inside the mirrored core approach")
	assert(route["enemy_goal_x"] > route["base_x"], "Mirrored core marker must be beyond the enemy goal")
	var north_camera_point := Vector2(1413.0, -200.0)
	var north_camera_zoom: Vector2 = scene.call("camera_zoom_for", north_camera_point)
	var north_camera_target: Vector2 = scene.call("camera_target_for", north_camera_point)
	assert(north_camera_zoom.x > 1.0, "Narrow spawn roads should use a light contextual zoom")
	assert(absf(north_camera_target.x - north_camera_point.x) < 80.0, "North-road framing should stay on the corridor")
	var shop_camera_zoom: Vector2 = scene.call("camera_zoom_for", Vector2(320.0, -110.0))
	assert(shop_camera_zoom.x > north_camera_zoom.x, "The narrower shop room should receive the tighter contextual framing")

	var hero := scene.get_node("HeroSlot/HeroController") as EmberHero
	scene.call("_spawn_home_rewards")
	var home_loot: Array = scene.get("_pickups")
	assert(home_loot.size() == 3, "Wave-clear home rewards should drop three pickups")
	var home_kinds: Array[StringName] = []
	for loot: Variant in home_loot:
		var pickup: EmberPickup = loot
		home_kinds.append(pickup.pickup_kind)
		assert(pickup.global_position.x < 360.0, "Home rewards must spawn on the core side")
		assert(pickup.global_position.x > 180.0, "Home rewards should sit in the home alcove column")
		var loot_sprite := pickup.get_node_or_null("PickupSprite") as Sprite2D
		if loot_sprite != null and loot_sprite.texture != null:
			var shown := maxf(float(loot_sprite.texture.get_width()), float(loot_sprite.texture.get_height())) * loot_sprite.scale.x
			if pickup.pickup_kind == &"scrap":
				assert(shown >= 48.0 and shown <= 72.0, "Scrap pickups should be a loud readable icon")
				assert(pickup.get_node_or_null("PickupCaption") != null, "Scrap pickups should show a 废料 label")
			else:
				assert(shown <= 42.0, "Home rewards must stay pickup-sized in the shop view")
	assert(home_kinds.has(&"scrap"), "Three home rewards must include scrap")
	hero.global_position = Vector2(252.0, 336.0)
	await process_frame
	scene.call("_process_pickups")
	assert((scene.get("_pickups") as Array).size() == 3, "Walking onto a home reward must not collect it")
	assert(scene.get("_targeted_pickup") != null, "Standing next to a drop should target exactly one")
	scene.call("_collect_targeted_pickup")
	await process_frame
	assert((scene.get("_pickups") as Array).size() == 2, "拾取 should collect exactly one drop")
	var click_target: EmberPickup = (scene.get("_pickups") as Array)[0]
	scene.call("_try_click_pickup", click_target.global_position)
	await process_frame
	assert((scene.get("_pickups") as Array).size() == 1, "Clicking a drop should collect exactly that one")
	var last_drop: EmberPickup = (scene.get("_pickups") as Array)[0]
	var scrap_before_timeout: int = int(scene.get("scrap"))
	last_drop.set("_life_left", 0.0)
	await process_frame
	await process_frame
	assert((scene.get("_pickups") as Array).is_empty(), "Timed-out drops should leave the ground")
	assert(int(scene.get("scrap")) == scrap_before_timeout, "Timeout must stash, not auto-apply scrap")
	var stashed_scrap := int(hero.item_stash.get("scrap", 0))
	var stashed_heal := int(hero.item_stash.get("heal", 0))
	var stashed_weapons: Array = hero.item_stash.get("weapons", [])
	assert(stashed_scrap > 0 or stashed_heal > 0 or stashed_weapons.size() > 0, "Timeout should send the drop into the warehouse")
	hero.item_stash = {"scrap": 0, "heal": 0, "weapons": []}
	for leftover: Variant in (scene.get("_pickups") as Array).duplicate():
		if leftover is EmberPickup and is_instance_valid(leftover):
			(leftover as EmberPickup).queue_free()
	scene.set("_pickups", [])
	scene.set("scrap", 300)
	var economy_shop: EmberShop = EmberShop.new()
	economy_shop.refresh(1, &"sword", 0, &"ember_hero", 0)
	var wave1_kinds: Array = []
	var wave1_payloads: Array = []
	var wave1_has_dash := false
	for slot: Dictionary in economy_shop.slots:
		wave1_kinds.append(slot.get("kind", &""))
		wave1_payloads.append(slot.get("payload", &""))
		if slot.get("kind", &"") == &"skill" and slot.get("payload", &"") == &"dash":
			wave1_has_dash = true
	assert(not wave1_kinds.has(&"weapon"), "Merchant sells towers only")
	assert(wave1_payloads.has(&"pulse"), "Wave 1 merchant must stock a pulse turret")
	assert(wave1_payloads.has(&"burst"), "Wave 1 merchant must stock a burst turret")
	assert(wave1_payloads.has(&"frost"), "Wave 1 merchant must stock a frost turret")
	assert(not wave1_has_dash, "Wave 1 trainer must not sell the starter skill")
	assert(not wave1_kinds.has(&"heal"), "Trainer no longer sells field dressing")
	assert(wave1_kinds.has(&"forge"), "Trainer should offer weapon forge")
	assert(wave1_kinds.has(&"skill"), "Trainer should offer the hero skill")
	economy_shop.refresh(2, &"sword", 0, &"ember_hero", 0)
	assert(economy_shop.slots.size() == 8, "Shop is 3 merchant + forge/skill/vitality/mech + summoner")
	assert(economy_shop.slots[3].get("kind", &"") == &"forge", "Trainer first counter is forge")
	assert(economy_shop.slots[4].get("kind", &"") == &"skill", "Trainer second counter is skill")
	assert(economy_shop.slots[5].get("kind", &"") == &"vitality", "Mentor vitality counter")
	assert(economy_shop.slots[6].get("kind", &"") == &"mech_repair", "Mechanic repair counter")
	assert(economy_shop.slots[6].get("vendor", &"") == &"mechanic", "mech_repair sold by mechanic NPC")
	assert(economy_shop.slots[7].get("kind", &"") == &"summon", "Summoner counter")
	hero.global_position = Vector2(640.0, 336.0)
	var visible_shelves := 0
	for shelf_index: int in range(5):
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
	jump_event.echo = false
	scene.call("_input", jump_event)
	assert(scene.get("_hero_state") == &"jump", "K should trigger the short jump")
	var jump_wait := 0
	while String(scene.get("_hero_state")) == "jump" and jump_wait < 40:
		await create_timer(0.05).timeout
		jump_wait += 1
	assert(scene.get("_hero_state") != &"jump", "K jump should finish before the next attack")

	var attack_event := InputEventKey.new()
	attack_event.keycode = KEY_J
	attack_event.pressed = true
	attack_event.echo = false
	scene.call("_input", attack_event)
	assert(scene.get("_hero_state") == &"attack", "J should trigger hero attack")
	await create_timer(0.25).timeout
	assert(scene.get("_hero_state") == &"attack", "J attack clip must still be playing at 0.25s")
	var j_actor: Node = hero.find_child("XSXBHeroActor", true, false)
	assert(j_actor != null and str(j_actor.get("_current_animation")) == "attack", "Body must stay on the attack clip through the readable window")
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
	var skill_button := scene.find_child("SkillButton", true, false) as Button
	var upgrade_button := scene.find_child("UpgradeButton", true, false) as Button
	assert(attack_button != null, "HUD should expose an attack button")
	assert(jump_button != null, "HUD should expose a dedicated jump button")
	assert(skill_button != null, "HUD should expose a skill button")
	assert(not skill_button.disabled, "Starter skill pad should be usable")
	var skill_overlay := skill_button.find_child("SkillPadOverlay", true, false)
	assert(skill_overlay != null, "Skill pad should keep a state overlay")
	assert(skill_overlay.get("mode") == &"ready", "Starter skill pad should be ready")
	assert(scene.find_child("MoveStick", true, false) != null, "Mobile virtual stick should be present")
	var move_stick := scene.find_child("MoveStick", true, false) as Control
	var bl_dock := scene.find_child("BottomLeftDock", true, false) as Control
	var br_dock := scene.find_child("BottomRightDock", true, false) as Control
	var tr_dock := scene.find_child("TopRightDock", true, false) as Control
	var tl_dock := scene.find_child("TopLeftDock", true, false) as Control
	var safe_area := scene.find_child("SafeArea", true, false) as MarginContainer
	assert(safe_area != null, "HUD should wrap chrome in a SafeArea margin")
	assert(bl_dock != null and is_equal_approx(bl_dock.anchor_left, 0.0) and is_equal_approx(bl_dock.anchor_top, 1.0), "Bottom-left dock is anchored bottom-left")
	assert(br_dock != null and is_equal_approx(br_dock.anchor_left, 1.0) and is_equal_approx(br_dock.anchor_top, 1.0), "Bottom-right dock is anchored bottom-right")
	assert(tr_dock != null and is_equal_approx(tr_dock.anchor_left, 1.0) and is_equal_approx(tr_dock.anchor_top, 0.0), "Top-right dock is anchored top-right")
	assert(tl_dock != null and is_equal_approx(tl_dock.anchor_left, 0.0) and is_equal_approx(tl_dock.anchor_top, 0.0), "Top-left dock is anchored top-left")
	var mid_dock := scene.find_child("MidLeftDock", true, false) as Control
	var warehouse_panel := scene.find_child("WarehousePanel", true, false) as Control
	var status_label := scene.find_child("StatusLabel", true, false) as Control
	var hold_hint := scene.find_child("ShopHoldHint", true, false) as Control
	var tower_panel := scene.find_child("TowerPanel", true, false) as Control
	var shop_strip := scene.find_child("ShopPanel", true, false) as Control
	var loot_row := scene.find_child("LootRow", true, false) as Control
	var end_overlay := scene.find_child("EndOverlay", true, false) as Control
	var end_center := scene.find_child("EndCenter", true, false) as Control
	assert(tl_dock != null and warehouse_panel != null and tl_dock.is_ancestor_of(warehouse_panel), "Warehouse lives in TopLeftDock")
	assert(status_label != null and tl_dock.is_ancestor_of(status_label), "Status toast lives in TopLeftDock")
	assert(hold_hint != null and tl_dock.is_ancestor_of(hold_hint), "Shop hold hint lives in TopLeftDock")
	assert(mid_dock != null and tower_panel != null and mid_dock.is_ancestor_of(tower_panel), "Tower panel lives in MidLeftDock")
	assert(shop_strip != null and is_equal_approx(shop_strip.anchor_left, 0.0) and is_equal_approx(shop_strip.anchor_right, 1.0), "Shop strip is a top-wide SafeInner band")
	assert(loot_row != null and bl_dock.is_ancestor_of(loot_row), "Pickup/discard sit above the stick in BottomLeftDock")
	assert(end_overlay != null and end_center != null and end_overlay.is_ancestor_of(end_center), "Pause/result overlay is a full-rect centered stack")
	var shop_pen: Node = scene.get("_shop_pen")
	assert(shop_pen != null and not shop_pen.is_processing(), "Shop pen must not redraw every frame")
	var shop_cam_at := Vector2(540.0, -90.0)
	var shop_target: Vector2 = scene.call("camera_target_for", shop_cam_at)
	var shop_zoom_v: Vector2 = scene.call("camera_zoom_for", shop_cam_at)
	var view := Vector2(1280.0, 720.0)
	for spot: Vector2 in (scene.get("SHOP_SHELVES") as Array):
		var screen := (spot - shop_target) * shop_zoom_v.x + view * 0.5
		var price_screen := (spot + Vector2(0.0, -22.0) - shop_target) * shop_zoom_v.x + view * 0.5
		assert(screen.x > 40.0 and screen.x < 1240.0, "Shop camera must keep every counter on screen")
		assert(price_screen.y > 88.0 and price_screen.y < 520.0, "Shop prices must sit below the top chrome")
	assert(move_stick != null and bl_dock.is_ancestor_of(move_stick), "Move stick lives in the bottom-left dock")
	assert(move_stick.global_position.x < 80.0, "Move stick stays bottom-left")
	assert(br_dock.is_ancestor_of(attack_button), "Attack lives in the bottom-right dock")
	assert(attack_button.global_position.x > 900.0, "Attack button stays on the right")
	assert(jump_button.global_position.y < attack_button.global_position.y - 20.0, "Jump sits above the attack button")
	assert(absf(jump_button.global_position.x + jump_button.size.x * 0.5 - (attack_button.global_position.x + attack_button.size.x * 0.5)) < 20.0, "Jump is centered above attack")
	assert(skill_button.global_position.x < attack_button.global_position.x - 20.0 and skill_button.global_position.y < attack_button.global_position.y - 20.0, "Skill sits on the upper-left diagonal of attack")
	var weapon_switch := scene.find_child("WeaponSwitch", true, false) as Button
	assert(weapon_switch != null and weapon_switch.global_position.x < attack_button.global_position.x - 20.0, "Weapon switch sits left of attack")
	assert(absf(weapon_switch.global_position.y + weapon_switch.size.y * 0.5 - (attack_button.global_position.y + attack_button.size.y * 0.5)) < 24.0, "Weapon switch is vertically centered on attack")
	var knight_sel := scene.find_child("HeroSelect_ember_hero", true, false) as Control
	var mini_hud := scene.find_child("MiniMap", true, false) as Control
	assert(knight_sel != null and mini_hud != null and tr_dock.is_ancestor_of(knight_sel) and tr_dock.is_ancestor_of(mini_hud), "Portraits and minimap share the top-right dock")
	assert(knight_sel.global_position.y > mini_hud.global_position.y + 40.0, "Hero portraits sit under the minimap")
	assert(move_stick.size.x >= 200.0 and attack_button.size.x >= 120.0, "Stick and attack pad should be enlarged")
	var fs_button := scene.find_child("FullscreenButton", true, false) as Button
	assert(fs_button != null, "HUD should expose a fullscreen button")
	assert(fs_button.text == "全屏", "Fullscreen button should be labeled 全屏")
	var top_row := scene.find_child("TopRow", true, false) as Control
	assert(top_row != null and top_row.is_ancestor_of(fs_button), "Fullscreen control belongs on the top bar, not the action cluster")
	assert(fs_button.global_position.y < 80.0, "Fullscreen button must stay on the top bar")
	fs_button.emit_signal("pressed")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	assert(scene.find_child("TalkButton", true, false) != null, "Talk virtual button should be present")
	assert(upgrade_button != null, "HUD should expose an upgrade button")
	assert(attack_button.tooltip_text.begins_with("攻击"), "Attack button should keep a Simplified Chinese tooltip")
	assert(jump_button.tooltip_text.begins_with("跳跃"), "Jump button should keep a Simplified Chinese tooltip")
	assert(upgrade_button.text.begins_with("升级"), "Upgrade button should be shown in Simplified Chinese")
	attack_button.emit_signal("pressed")
	assert(scene.get("_hero_state") == &"attack", "Attack button should trigger hero attack")
	await create_timer(1.2).timeout
	assert(hero.total_attack_hits_emitted == 1, "Chinese attack button should play a single slash")
	assert(scene.get("_hero_state") == &"idle", "Attack button slash should finish before jump")
	jump_button.emit_signal("pressed")
	assert(scene.get("_hero_state") == &"jump", "Chinese jump button should trigger hero jump")
	await create_timer(1.0).timeout

	var prep_towers: int = (scene.get("_towers") as Array).size()
	scene.call("_try_place_tower", Vector2(990.0, 205.0))
	assert((scene.get("_towers") as Array).size() == prep_towers, "Prep must not place a tower before buying from the merchant")
	assert(scene.get("scrap") == 300, "Prep click-to-build must not spend scrap")
	scene.call("_spawn_tower_at", Vector2(990.0, 205.0), &"pulse", 1)
	assert(scene.get("_towers").size() == 1, "A tower should be placed on the first pad")
	scene.set("scrap", 220)
	var first_tower: EmberTower = (scene.get("_towers") as Array)[0]
	scene.call("_select_tower", first_tower)
	var selected_tower: EmberTower = scene.get("_selected_tower")
	assert(selected_tower != null, "Selecting an occupied pad should highlight the tower")
	scene.call("upgrade_selected_tower")
	assert(selected_tower.level == 2, "Selected tower should upgrade to level 2")
	assert(selected_tower.attack_damage == 38, "Level 2 tower should deal more damage")
	assert(scene.get("scrap") == 110, "Level 2 upgrade should cost 110 scrap")

	scene.set("scrap", 500)
	scene.call("_spawn_tower_at", Vector2(820.0, 205.0), &"burst", 1)
	scene.call("_spawn_tower_at", Vector2(650.0, 205.0), &"frost", 1)
	var towers: Array = scene.get("_towers")
	assert(towers.size() == 3, "Pulse, burst, and frost towers should all place")
	assert(towers[1].kind == &"burst", "Second pad should hold a burst tower")
	assert(towers[2].kind == &"frost", "Third pad should hold a frost tower")
	scene.set("scrap", 800)
	scene.call("_spawn_tower_at", Vector2(456.0, 216.0), &"pulse", 1)
	scene.call("_spawn_tower_at", Vector2(456.0, 456.0), &"pulse", 1)
	scene.call("_spawn_tower_at", Vector2(648.0, 456.0), &"pulse", 1)
	scene.call("_spawn_tower_at", Vector2(840.0, 456.0), &"pulse", 1)
	scene.call("_spawn_tower_at", Vector2(888.0, 360.0), &"pulse", 1)
	assert((scene.get("_towers") as Array).size() == 8, "Eight combat tiles should all accept a tower")
	# Cap is 16; keep placing until full then one more must fail.
	scene.set("scrap", 2000)
	hero.turret_hand = true
	for _i: int in range(8):
		hero.add_turret(&"pulse")
	var placed := 8
	var try_spots: Array[Vector2] = [
		Vector2(520.0, 300.0), Vector2(580.0, 300.0), Vector2(640.0, 300.0), Vector2(700.0, 300.0),
		Vector2(520.0, 360.0), Vector2(580.0, 360.0), Vector2(640.0, 360.0), Vector2(700.0, 360.0),
	]
	for spot: Vector2 in try_spots:
		if (scene.get("_towers") as Array).size() >= 16:
			break
		scene.call("_try_place_tower", spot)
	assert((scene.get("_towers") as Array).size() == 16, "TOWER_CAP 16 should fill")
	var before_overflow: int = (scene.get("_towers") as Array).size()
	var scrap_before_overflow: int = int(scene.get("scrap"))
	hero.add_turret(&"pulse")
	scene.call("_try_place_tower", Vector2(760.0, 360.0))
	assert((scene.get("_towers") as Array).size() == before_overflow, "A 17th tower must fail")
	assert(int(scene.get("scrap")) == scrap_before_overflow, "Failed overflow placement must not spend scrap")
	scene.call("_select_tower", (scene.get("_towers") as Array)[0])
	scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).size() == 15, "Selling should free a pad")
	assert(int(scene.get("scrap")) == scrap_before_overflow + 48, "Pulse sell refund is 60% of build cost")
	scene.call("_spawn_tower_at", Vector2(990.0, 205.0), &"pulse", 1)
	assert((scene.get("_towers") as Array).size() == 16, "Freed pad should accept a new tower")
	var pad7: EmberTower
	for tower_item: Variant in scene.get("_towers"):
		if tower_item is EmberTower and (tower_item as EmberTower).position.distance_to(Vector2(888.0, 360.0)) < 40.0:
			pad7 = tower_item
			break
	scene.call("_select_tower", pad7)
	scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).size() == 15, "Pad 7 should be empty for the combat placement probe")
	hero.turret_hand = false
	hero.set_turret_hand(false)
	hero.turret_stash.clear()
	# Clear the cap-fill towers so later path / separation probes stay clean.
	while not (scene.get("_towers") as Array).is_empty():
		scene.call("_select_tower", (scene.get("_towers") as Array)[0])
		scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).is_empty(), "Tower-cap probe cleanup must clear the field")

	var melee_hits := hero.total_attack_hits_emitted
	var held := hero.find_child("HeldWeapon", true, false) as Sprite2D
	assert(held != null and held.texture != null and held.visible, "Starter hero should float the greatsword overlay")
	assert(absf(held.position.x) >= 22.0, "Sword should float beside the body, not in the fist")
	assert(held.position.y <= -8.0, "Floating sword should sit beside the torso")
	assert(held.position.y >= -70.0, "Floating sword should stay on-screen near the body")
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
	var slash_origin := hero.global_position + Vector2(28.0, -18.0)
	var body_probe := FrontierEnemy.new()
	body_probe.variant = &"boss"
	body_probe.max_health = 9999
	body_probe.move_speed = 0.0
	body_probe.configure_seek(slash_origin + Vector2(130.0, 0.0), scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", body_probe)
	await process_frame
	var sword_reach := 118.0
	assert(slash_origin.distance_to(body_probe.global_position) > sword_reach, "Boss origin should sit past the sword's point range")
	assert(body_probe.hurt_gap(slash_origin) <= sword_reach, "Boss opaque body must extend into the slash")
	var body_hp := int(body_probe.health)
	scene.call("_on_hero_attacked", slash_origin, 1)
	assert(int(body_probe.health) < body_hp, "Melee should hit the enemy body, not only its origin point")
	body_probe.queue_free()
	await create_timer(0.55).timeout
	melee_hits = hero.total_attack_hits_emitted
	hero.equip_weapon(&"pistol")
	assert(held.texture != null, "Equipped pistol should show a held-weapon sprite")
	assert(hero.weapon_slots[0] == &"sword" and hero.weapon_slots[1] == &"pistol", "Pistol should fill the second Soul Knight slot")
	assert(hero.current_weapon == &"pistol", "Newly equipped gun becomes active")
	assert(hero.cycle_weapon() and hero.current_weapon == &"sword", "Q-cycle should return to the sword")
	assert(hero.cycle_weapon() and hero.current_weapon == &"pistol", "Second cycle should restore the pistol")
	var dock := scene.find_child("WeaponSwitch", true, false) as Button
	assert(dock != null, "HUD should show a weapon switch")
	assert(scene.find_child("WeaponSlot0", true, false) == null, "Weapon HUD is one switch, not two slot buttons")
	assert(scene.find_child("WeaponSlot1", true, false) == null, "Weapon HUD is one switch, not two slot buttons")
	dock.emit_signal("pressed")
	assert(hero.current_weapon == &"sword", "Weapon switch should cycle to the other slot")
	dock.emit_signal("pressed")
	assert(hero.current_weapon == &"pistol", "Second switch press should restore the pistol")
	var fire_pos := hero.position
	scene.call("_play_attack")
	assert(hero.ranged_shots_emitted == 1, "Pistol J should fire a hero bullet")
	assert(hero.position == fire_pos, "Ranged fire must not knock the hero backward")
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
	assert(float(pistol_def["fx_scale"]) >= 0.70 and float(pistol_def["fx_scale"]) <= 1.20, "Pistol bullets should read clearly larger than the held gun")
	assert(float(ion_def["fx_scale"]) >= 0.60 and float(ion_def["fx_scale"]) <= 1.20, "Ion bolts should stay large without eating the hero")
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
	assert(bool(scene.get("_is_game_over")), "Hero death must end the run (SK parity)")
	var death_title := scene.find_child("OverlayTitle", true, false) as Label
	assert(death_title != null and death_title.text == "英雄阵亡", "Hero death end screen title should be 英雄阵亡")
	# Restart scene state for remaining smoke checks that need a living hero.
	scene.set("_is_game_over", false)
	if scene.get("_hud") != null and scene.get("_hud").has_method("hide_end_screen"):
		scene.get("_hud").call("hide_end_screen")
	hero.is_down = false
	hero.health = 40
	hero.position = hero.revive_position
	hero.call("_set_state", &"idle")
	assert(hero.has_dash, "Starter dash should already be unlocked")
	scene.call("_sync_skill_hud")
	assert(not skill_button.disabled, "A ready skill pad should accept input")
	hero.request_dash()
	scene.call("_sync_skill_hud")
	assert(hero.has_dash and hero.current_state == &"dash", "Unlocked dash should play the skill clip")
	assert(hero.dash_cooldown_left > 0.0, "The HUD skill action must use dash cooldown")
	assert(skill_button.disabled, "Casting skill pad should ignore extra taps")
	assert(skill_overlay.get("mode") == &"casting", "Casting skill pad should draw the release overlay")
	await create_timer(0.30).timeout
	scene.call("_sync_skill_hud")
	assert(skill_button.disabled, "Cooldown skill pad should stay blocked")
	assert(skill_overlay.get("mode") == &"cooldown", "Cooldown skill pad should draw the clock wipe")
	hero.dash_cooldown_left = 0.0
	hero.apply_hero_kind(&"assassin")
	await process_frame
	assert(hero.hero_kind == &"assassin", "Hero kind should switch to assassin")
	var assassin_actor: Node = hero.find_child("XSXBHeroActor", true, false)
	assert(assassin_actor != null, "Assassin should keep an XSXB actor")
	var assassin_anims: Dictionary = assassin_actor.get("_animations")
	var skill_cast: Dictionary = assassin_anims.get("skill_cast", {})
	var skill_bubble: Dictionary = assassin_anims.get("skill_bubble", {})
	var assassin_walk: Dictionary = assassin_anims.get("walk", {})
	assert((skill_cast.get("frames", []) as Array).size() == 8, "Assassin skill_cast must be 8 frames")
	assert((skill_bubble.get("frames", []) as Array).size() == 8, "Assassin skill_bubble must be 8 frames")
	assert((assassin_walk.get("frames", []) as Array).size() == 6, "Assassin walk should drop hold duplicates")
	var assassin_idle: Dictionary = assassin_anims.get("idle", {})
	var assassin_down: Dictionary = assassin_anims.get("down", {})
	assert((assassin_idle.get("frames", []) as Array).size() == 6, "Assassin idle is a 6-frame breathe loop")
	assert((assassin_down.get("frames", []) as Array).size() >= 3, "Assassin down must exist as a terminal clip")
	assert(float(assassin_actor.call("animation_duration", "skill_cast")) >= 0.70, "Assassin skill_cast should last through the spin")
	hero.health = hero.max_health
	hero.down_duration = 0.25
	hero.take_damage(999)
	assert(hero.is_down and hero.current_state == &"down", "Assassin fatal damage should play down, not idle")
	await create_timer(0.45).timeout
	assert(bool(scene.get("_is_game_over")), "Assassin death must end the run")
	scene.set("_is_game_over", false)
	if scene.get("_hud") != null and scene.get("_hud").has_method("hide_end_screen"):
		scene.get("_hud").call("hide_end_screen")
	hero.is_down = false
	hero.health = hero.max_health
	hero.call("_set_state", &"idle")
	assert(hero.select_weapon_slot(0) and hero.current_weapon == &"sword", "Assassin melee probe uses the starter sword")
	assert(held.visible and held.texture != null, "Assassin melee should float the current weapon")
	assert(absf(held.position.x) >= 22.0, "Assassin sword should hover beside the body")
	assert(hero.select_weapon_slot(1) and WeaponCatalog.is_ranged(hero.current_weapon), "Assassin gun probe needs a ranged slot")
	assert(held.visible and held.texture != null, "Assassin gun should float the selected weapon art")
	hero.dash_cooldown_left = 0.0
	hero.request_dash()
	assert(hero.current_state == &"dash", "Assassin skill should reuse the dash slot")
	assert((hero.get("_clone_nodes") as Array).size() == 3, "Assassin skill should spawn three bubble clones")
	assert(absf(EmberHero.CLONE_DURATION - 5.0) < 0.01, "Shadow clones should last five seconds")
	await create_timer(1.0).timeout
	assert((hero.get("_clone_nodes") as Array).size() == 3, "Shadow clones must outlive the bubble intro")
	var dummy := FrontierEnemy.new()
	dummy.variant = &"scout"
	dummy.max_health = 9999
	dummy.move_speed = 0.0
	dummy.configure_seek(hero.global_position + Vector2(70.0, 0.0), scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", dummy)
	await create_timer(1.20).timeout
	assert(is_instance_valid(dummy) and dummy.health < dummy.max_health, "Shadow clones should auto-lock and melee a nearby enemy")
	for clone_node: Variant in hero.get("_clone_nodes"):
		if clone_node is Node:
			(clone_node as Node).set_meta("life", 0.01)
	await create_timer(0.20).timeout
	assert((hero.get("_clone_nodes") as Array).is_empty(), "Expired clones should despawn")
	if is_instance_valid(dummy):
		(scene.get("_enemies") as Array).erase(dummy)
		dummy.queue_free()
	hero.apply_hero_kind(&"ember_hero")
	await process_frame
	assert(hero.hero_kind == &"ember_hero", "Smoke must restore the knight after assassin checks")
	var knight_actor: Node = hero.find_child("XSXBHeroActor", true, false)
	assert(knight_actor != null, "Knight should keep an XSXB actor")
	var knight_idle: Dictionary = (knight_actor.get("_animations") as Dictionary).get("idle", {})
	assert((knight_idle.get("frames", []) as Array).size() == 6, "Knight idle is a 6-frame breathe loop")

	var route_probes: Array[FrontierEnemy] = []
	for route_points: PackedVector2Array in route["routes"]:
		var probe := FrontierEnemy.new()
		probe.variant = &"scout"
		probe.max_health = 9999
		probe.move_speed = 1800.0
		probe.configure_route(route_points)
		route_probes.append(probe)
		scene.add_child(probe)
	await create_timer(2.0).timeout
	for probe: FrontierEnemy in route_probes:
		assert(not is_instance_valid(probe), "Enemies crossing the open floor should reach the core")

	hero.is_down = false
	hero.global_position = Vector2(700.0, 336.0)
	var core: Vector2 = EXPECTED_CORE_GOAL
	assert(scene.call("enemy_target_position", Vector2(700.0, 500.0)) == core, "Queries without an enemy must return the core")
	var far_probe := FrontierEnemy.new()
	far_probe.variant = &"scout"
	far_probe.max_health = 9999
	far_probe.move_speed = 220.0
	far_probe.configure_seek(Vector2(700.0, 500.0), core, scene)
	scene.add_child(far_probe)
	await create_timer(0.05).timeout
	assert(not bool(far_probe.get("_aggro")), "An enemy 164px from the hero must walk to the core")
	assert(far_probe.global_position.y > 430.0, "Core-seeking enemy must not chase from (700,500)")
	far_probe.queue_free()
	var near_probe := FrontierEnemy.new()
	near_probe.variant = &"scout"
	near_probe.max_health = 9999
	near_probe.move_speed = 220.0
	near_probe.configure_seek(Vector2(700.0, 416.0), core, scene)
	scene.add_child(near_probe)
	await create_timer(0.05).timeout
	assert(bool(near_probe.get("_aggro")), "An enemy 80px from the hero should aggro")
	hero.global_position = Vector2(700.0, 160.0)
	await create_timer(0.45).timeout
	assert(not bool(near_probe.get("_aggro")), "Teleporting the hero outside 144px for 0.40s should drop aggro")
	near_probe.queue_free()
	hero.global_position = core
	var tank_probe := FrontierEnemy.new()
	tank_probe.variant = &"scout"
	tank_probe.max_health = 9999
	tank_probe.move_speed = 1.0
	tank_probe.configure_seek(core + Vector2(20.0, 0.0), core, scene)
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
	leak_probe.configure_seek(core + Vector2(26.0, 0.0), core, scene)
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
	pile_a.configure_seek(Vector2(520.0, 336.0), core, scene)
	pile_b.configure_seek(Vector2(520.0, 338.0), core, scene)
	scene.add_child(pile_a)
	scene.add_child(pile_b)
	await create_timer(0.55).timeout
	assert(pile_a.global_position.distance_to(pile_b.global_position) >= 18.0, "Stacked enemies should push apart instead of occupying the same tile")
	pile_a.queue_free()
	pile_b.queue_free()

	hero.position = Vector2(40.0, 336.0)
	hero.move_in_direction(Vector2.LEFT, 0.40)
	assert(hero.position.x < 76.0, "Hero should walk west of the core")
	hero.position = Vector2(1180.0, 336.0)
	hero.move_in_direction(Vector2.RIGHT, 0.50)
	assert(hero.position.x > 1192.0, "Hero should walk onto the east combat expansion")
	hero.position = Vector2(1520.0, 40.0)
	hero.move_in_direction(Vector2.UP, 0.50)
	assert(hero.position.y < 16.0, "Hero should walk out the north road")
	hero.position = Vector2(1800.0, 336.0)
	hero.move_in_direction(Vector2.RIGHT, 0.50)
	assert(hero.position.x > 1760.0, "Hero should walk out the east road")
	hero.position = Vector2(2000.0, 336.0)
	hero.move_in_direction(Vector2.UP, 0.80)
	var tile_w := 1280.0 / 1536.0 * 64.0
	var tile_h := 720.0 / 1024.0 * 64.0
	var floor_ox := 1280.0 / 1536.0 * 4.0
	var floor_oy := -8.0 + 720.0 / 1024.0 * 42.0
	var east_road_y0 := floor_oy + 4.0 * tile_h
	assert(hero.position.y >= east_road_y0 - 2.0, "East corridor north wall should block walking into the void")
	hero.position = Vector2(1500.0, 620.0)
	hero.move_in_direction(Vector2.DOWN, 0.50)
	assert(hero.position.y > 640.0, "Hero should walk out the south-east road")
	hero.position = Vector2(640.0, 620.0)
	hero.move_in_direction(Vector2.DOWN, 0.50)
	assert(hero.position.y <= 640.0, "South wall stays at the original combat edge")
	hero.position = Vector2(568.0, 140.0)
	hero.move_in_direction(Vector2.UP, 0.90)
	assert(hero.position.y < 112.0, "Hero should walk north through the shop door")
	assert(scene.find_child("NpcTrainer", true, false) != null, "Trainer stands at the forge and skill counters")
	assert(scene.find_child("NpcMerchant", true, false) != null, "Merchant stands at the tower counters")
	assert(scene.find_child("NpcMechanic", true, false) != null, "Mechanic stands at the repair counter")
	assert(scene.find_child("NpcOfficer", true, false) != null, "Officer stands in the bottom band")
	var mer_npc: Sprite2D = scene.find_child("NpcMerchant", true, false)
	var trn_npc: Sprite2D = scene.find_child("NpcTrainer", true, false)
	var mech_npc: Sprite2D = scene.find_child("NpcMechanic", true, false)
	assert(mer_npc.position.y <= -200.0, "Merchant stands in the top shop band")
	assert(mech_npc.position.y <= -200.0, "Mechanic stands in the top shop band")
	assert(trn_npc.position.y <= -90.0 and trn_npc.position.y >= -140.0, "Mentor stands in the bottom shop band")
	var crate_block: Vector2 = hero.position
	hero.position = Vector2(420.0, -205.0)
	var blocked: Vector2 = scene.call("_clamp_to_walkable", Vector2(420.0, -120.0), Vector2(420.0, -205.0))
	assert(blocked.y > -185.0, "Hero should not walk onto a shop pedestal")
	hero.position = crate_block
	for keeper_i: int in range(9):
		assert(scene.find_child("NpcKeeper%d" % keeper_i, true, false) == null, "No keeper sprites on crates")
	assert(scene.find_child("NpcSummoner", true, false) != null, "Summoner stands at the summoner counters")
	var sum_npc: Sprite2D = scene.find_child("NpcSummoner", true, false)
	assert(String(sum_npc.get_meta("npc_folder", "")) == "summoner", "Summoner must load summoner anim folder, not trainer")
	assert(String(trn_npc.get_meta("npc_folder", "")) == "mentor", "Trainer code ID uses mentor art folder")
	assert(String(mech_npc.get_meta("npc_folder", "")) == "mechanic", "Mechanic loads mechanic anim folder")
	var sum_idle: Array = sum_npc.get_meta("idle_frames", [])
	var trn_idle: Array = trn_npc.get_meta("idle_frames", [])
	assert(sum_idle.size() >= 4, "Summoner needs generated idle frames")
	assert(trn_idle.size() >= 4 and sum_idle[0] != trn_idle[0], "Summoner must not reuse mentor idle frames")
	assert(FileAccess.file_exists("res://assets/generated/npc/summoner/idle/frame_00.png"), "Summoner idle frame_00 must exist")
	assert(FileAccess.file_exists("res://assets/generated/npc/summoner/restock/frame_00.png"), "Summoner restock frames must exist")
	assert(FileAccess.file_exists("res://assets/generated/npc/mentor/idle/frame_00.png"), "Mentor idle frames must exist")
	assert(FileAccess.file_exists("res://assets/generated/npc/mechanic/idle/frame_00.png"), "Mechanic idle frames must exist")
	assert(FileAccess.file_exists("res://assets/generated/npc/officer/idle/frame_00.png"), "Officer idle frames must exist")
	assert(FileAccess.file_exists("res://assets/generated/ui/shop-pedestal.png"), "Gold pedestal art")
	assert(FileAccess.file_exists("res://assets/generated/ui/home-conveyor.png"), "Home conveyor art")
	assert(FileAccess.file_exists("res://assets/generated/fx/gold-rail.png"), "Gold rail art")
	assert(scene.find_child("ShopPen", true, false) != null, "Home shop rooms should still expose ShopPen")
	var shelves: Array = scene.get("SHOP_SHELVES") as Array
	assert(shelves.size() == 9, "Nine pedestals in two bands")
	assert((shelves[0] as Vector2).y < -180.0 and (shelves[4] as Vector2).y > -80.0, "Top/bottom shelf bands")
	var vendors: Array = scene.get("SHELF_VENDORS") as Array
	assert(vendors[3] == &"mechanic", "Top-band mechanic shelf")
	assert((scene.get("_home_conveyors") as Array).size() == 3, "Three conveyor pads by the core")
	var north_portal := scene.find_child("SpawnPortalNorth", true, false) as Node2D
	var south_portal := scene.find_child("SpawnPortalSouth", true, false) as Node2D
	var east_portal := scene.find_child("SpawnPortalEast", true, false) as Node2D
	assert(north_portal != null, "North enemy mouth should have a portal")
	assert(south_portal != null, "South enemy mouth should have a portal")
	assert(east_portal != null, "East enemy mouth should have a portal")
	var wall_h := 80.0 * (720.0 / 1024.0)
	var east_wall_x := floor_ox + 41.0 * tile_w
	var east_hole_y0 := floor_oy + 6.0 * tile_h
	var east_hole_y1 := floor_oy + 8.0 * tile_h
	assert(east_portal.position.x > east_wall_x and east_portal.position.x < east_wall_x + 2.0 * tile_w, "East portal must sit in the wall hole, not out in the void")
	assert(east_portal.position.y > east_hole_y0 and east_portal.position.y < east_hole_y1, "East portal must sit in the east wall opening")
	var north_end_y := floor_oy - 12.0 * tile_h - wall_h
	assert(north_portal.position.y > north_end_y and north_portal.position.y < north_end_y + wall_h, "North portal must sit in the end-wall hole")
	var south_end_y := 640.0 + 16.0 * tile_h
	assert(south_portal.position.y > south_end_y and south_portal.position.y < south_end_y + wall_h, "South portal must sit in the end-wall hole")
	var mouth_mid_x := floor_ox + 24.0 * tile_w + 2.5 * tile_w
	var north_steer: Vector2 = scene.call("enemy_path_point", Vector2(1308.0, -200.0), scene.call("core_goal")) as Vector2
	assert(absf(north_steer.x - mouth_mid_x) < 8.0, "North corridor should route down the mouth center, not hug a wall")
	var wall_boss := FrontierEnemy.new()
	wall_boss.variant = &"boss"
	wall_boss.configure_seek(Vector2(800.0, 80.0), scene.call("core_goal") as Vector2, scene)
	scene.add_child(wall_boss)
	await process_frame
	await process_frame
	var inset: Vector2 = scene.call("clamp_enemy_position", Vector2(800.0, 80.0), Vector2(800.0, 80.0), wall_boss) as Vector2
	assert(inset.y >= 130.0, "Boss origin should sit below the north wall instead of clipping into the void")
	wall_boss.queue_free()
	assert((scene.call("_spawn_holes_for_wave", 1) as Array).size() == 1, "Wave 1 should spawn from one hole")
	assert((scene.call("_spawn_holes_for_wave", 4) as Array).size() == 2, "Wave 4 should spawn from two holes together")
	assert((scene.call("_spawn_holes_for_wave", 7) as Array).size() == 3, "Wave 7+ should spawn from all three holes")
	var mini := scene.find_child("MiniMap", true, false) as Control
	assert(mini != null, "HUD should show a mini-map")
	assert(mini.size.y <= 140.0, "Mini-map should stay compact under the top HUD")

	# Interact ! icon needs prep + open shop near a real shelf.
	if scene.get("_director") != null and not bool(scene.get("_director").call("is_prep")):
		scene.get("_director").call("begin_prep")
	scene.get("_shop").is_open = true
	scene.set("_is_game_over", false)
	hero.position = Vector2(520.0, -140.0)
	scene.call("_sync_skill_hud")
	await process_frame
	var skill_near := scene.find_child("SkillButton", true, false) as Button
	var hud: Node = scene.get("_hud")
	var interact_tex: Texture2D = hud.get("_interact_icon") as Texture2D
	var dash_tex: Texture2D = hud.get("_dash_icon") as Texture2D
	assert(interact_tex != null, "HUD should load skill-interact.png")
	assert(dash_tex != null, "HUD should load dash.png")
	assert(skill_near != null and skill_near.text == "", "Near a shelf the skill slot text stays empty")
	assert(skill_near.icon == interact_tex and skill_near.icon != dash_tex, "Near a shelf the skill slot shows the pixel ! icon")
	assert(not skill_near.disabled, "Interact slot should be pressable")
	assert(skill_near.expand_icon, "Interact slot should expand the ! icon")
	assert(not shop_panel.visible, "Buying from the counter must not open the HUD shop panel")
	hero.position = Vector2(640.0, 336.0)
	scene.call("_sync_skill_hud")
	assert(skill_near.text == "" and skill_near.icon != null and skill_near.icon != interact_tex, "Far from shelves the skill slot is the skill again")
	assert(skill_near.icon == dash_tex, "Far from shelves restores the dash lightning")
	scene.call("_spawn_world_pickup", &"scrap", &"scrap", "res://assets/generated/ui/scrap.png", 0.18, Vector2(640.0, 336.0), 10, 20.0)
	scene.call("_process_pickups")
	scene.call("_sync_skill_hud")
	assert(skill_near.text == "", "Near ground loot the skill slot text stays empty")
	assert(skill_near.icon == interact_tex and skill_near.icon != dash_tex, "Near ground loot the skill slot shows the pixel ! icon")
	var scrap_loot: int = int(scene.get("scrap"))
	scene.call("_on_skill_or_interact")
	assert(int(scene.get("scrap")) == scrap_loot + 10, "Pressing ！ should pick up scrap")
	scene.call("_sync_skill_hud")
	assert(skill_near.text == "" and skill_near.icon == dash_tex, "After loot the skill slot is the skill again")
	var place_ghost := scene.find_child("PlaceGhost", true, false) as Sprite2D
	assert(place_ghost != null, "Tile hover should have a placement ghost")
	assert(not place_ghost.visible, "Prep without a held tower must not draw a place ghost")
	var place_fill := scene.find_child("PlaceFill", true, false) as Polygon2D
	assert(place_fill != null, "Tile hover should have a gold cell fill")
	assert(not place_fill.visible, "Prep without a held tower must not draw a gold cell")
	var towers_before_gun: int = (scene.get("_towers") as Array).size()
	scene.call("_try_place_tower", Vector2(188.0, 263.0))
	assert((scene.get("_towers") as Array).size() == towers_before_gun, "The crystal dais must reject towers")
	var shop: EmberShop = scene.get("_shop")
	assert(StringName(shop.slots[1].get("kind", &"")) == &"tower", "Wave 1 middle counter is a turret")
	assert(StringName(shop.slots[1].get("payload", &"")) == &"burst", "Wave 1 middle counter is burst")
	scene.set("_talking_npc", &"")
	scene.set("scrap", 400)
	scene.call("_refresh_shop_ui")
	assert(not shop_panel.visible, "Buying from the counter must not require the HUD shop panel")
	hero.position = Vector2(640.0, 336.0)
	var scrap_far: int = int(scene.get("scrap"))
	var slots_far: Array[StringName] = hero.weapon_slots.duplicate()
	scene.call("_try_buy_shelf", Vector2(270.0, -70.0))
	assert(int(scene.get("scrap")) == scrap_far, "A far click must not buy from the counter")
	assert(hero.weapon_slots == slots_far, "A far click must not change weapon slots")
	# Ensure wave-1 fixed merchant stock (pulse/burst/frost).
	shop.refresh(1, hero.combat_weapon_id(), hero.forge_level_for(hero.combat_weapon_id()), hero.hero_kind, hero.skill_level_for(hero.hero_kind))
	scene.call("_refresh_shop_ui")
	assert(StringName(shop.slots[1].get("payload", &"")) == &"burst", "Wave 1 middle counter is burst")
	hero.position = Vector2(520.0, -140.0)
	scene.call("_sync_skill_hud")
	assert(skill_near.text == "" and skill_near.icon == interact_tex and skill_near.icon != dash_tex, "Standing on the burst counter should show the pixel ! icon")
	scene.call("_try_buy_shelf", Vector2(520.0, -205.0))
	assert(int(hero.turret_stash.get(&"burst", 0)) >= 1, "Clicking the burst counter without talking should stash a turret")
	assert(not bool(shop.slots[1].get("sold", false)), "Merchant slot restocks immediately after a buy")
	assert(StringName(shop.slots[1].get("kind", &"")) == &"tower", "Restocked merchant slot stays a turret")
	assert(StringName(shop.slots[1].get("payload", &"")) == &"burst", "Restocked merchant slot stays the same turret")
	scene.call("_dev_equip_pistol")
	assert(hero.current_weapon == &"pistol", "Dev G still grants a pistol for later mount checks")
	hero.position = Vector2(420.0, -140.0)
	var pulse_cost := int(shop.slots[0].get("cost", 80))
	var scrap_before_pulse: int = int(scene.get("scrap"))
	scene.call("_try_buy_shelf", Vector2(420.0, -205.0))
	assert(int(hero.turret_stash.get(&"pulse", 0)) >= 1, "Buying a turret should go into the hero stash")
	assert(int(scene.get("scrap")) == scrap_before_pulse - pulse_cost, "Turret buy should spend the shelf price")
	assert(hero.cycle_weapon() and hero.turret_hand, "Q should reach turret-hand after a stash buy")
	hero.call("_refresh_held_weapon")
	var turret_float := hero.find_child("HeldWeapon", true, false) as Sprite2D
	assert(turret_float != null and turret_float.visible and turret_float.texture != null, "Turret-hand should float the next cannon")
	assert(String(turret_float.texture.resource_path).ends_with("tower-lv1.png"), "Turret-hand orbit should use pulse tower art, not the last gun")
	var stash_backup: Dictionary = hero.turret_stash.duplicate(true)
	hero.turret_stash.clear()
	hero.call("_refresh_held_weapon")
	assert(not turret_float.visible, "Empty turret stash should hide the orbit")
	hero.turret_stash = stash_backup
	hero.call("_refresh_held_weapon")
	assert(turret_float.visible and String(turret_float.texture.resource_path).ends_with("tower-lv1.png"), "Restored stash should float the cannon again")
	scene.call("_sync_weapon_hud")
	var dock_count := scene.find_child("WeaponCount", true, false) as Label
	assert(dock_count != null and dock_count.visible, "Turret-hand should show a dock count badge")
	assert(dock_count.text == "x1", "Dock should show the stacked turret-hand count")
	scene.set("_place_preview_world", Vector2(720.0, 380.0))
	scene.call("_sync_place_preview")
	assert(place_ghost.visible, "Turret-hand should ghost the hovered floor tile")
	assert(place_ghost.texture != null, "Place ghost should use the turret art")
	assert(place_fill.visible, "Turret-hand should mark the hovered floor tile")
	var hover_rect: Rect2 = scene.call("_cell_rect", scene.call("_cell_at", Vector2(720.0, 380.0)))
	var atlas_x := hover_rect.position.x / (1280.0 / 1536.0)
	var atlas_y := (hover_rect.position.y + 8.0) / (720.0 / 1024.0)
	assert(minf(fposmod(atlas_x - 4.0, 64.0), 64.0 - fposmod(atlas_x - 4.0, 64.0)) < 0.6, "Place preview X must sit on painted grout phase 4")
	assert(minf(fposmod(atlas_y - 42.0, 64.0), 64.0 - fposmod(atlas_y - 42.0, 64.0)) < 0.6, "Place preview Y must sit on painted grout phase 42")
	scene.call("_try_place_tower", Vector2(720.0, 380.0))
	scene.set("_place_preview_world", Vector2(INF, INF))
	scene.call("_sync_place_preview")
	var after_gun: Array = scene.get("_towers")
	assert(after_gun.size() == towers_before_gun + 1, "Turret-hand should place a bought cannon on a floor tile")
	var planted: EmberTower = after_gun[after_gun.size() - 1]
	assert(planted.kind == &"pulse" and planted.weapon_id == &"", "Placed stash turret starts as an empty cannon")
	var planted_cell: Vector2i = scene.call("_cell_at", planted.position)
	var snapped: Vector2 = scene.call("_cell_center", planted_cell)
	assert(planted.position.distance_to(snapped) < 1.0, "Planted turret must sit on a floor-tile center")
	assert(hero.weapon_slots[1] == &"pistol", "Pistol stays in the hero slot until mounted")
	hero.turret_stash.clear()
	hero.turret_hand = false
	assert(hero.select_weapon_slot(1) and hero.current_weapon == &"pistol", "Mount uses the pistol hand, not a leftover turret-hand")
	scene.call("_try_place_tower", planted.position)
	assert(planted.weapon_id == &"pistol", "Clicking an empty cannon with a weapon hand should mount it")
	assert(hero.weapon_slots[1] == &"", "Mounting should empty the current weapon slot")
	scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).size() == towers_before_gun, "Selling the planted turret should free the tile")
	hero.position = Vector2(420.0, -140.0)
	scene.call("_sync_skill_hud")
	await process_frame
	assert(skill_near.text == "" and skill_near.icon == interact_tex and skill_near.icon != dash_tex, "Skill slot should show the pixel ! icon at the pulse counter")
	assert(StringName(shop.slots[0].get("payload", &"")) == &"pulse", "Pulse counter restocks pulse")
	var scrap_skill_buy: int = int(scene.get("scrap"))
	var pulse_skill_cost := int(shop.slots[0].get("cost", 80))
	scene.call("_on_skill_or_interact")
	assert(int(hero.turret_stash.get(&"pulse", 0)) >= 1, "Pressing 购买 should fill stash like a counter click")
	assert(int(scene.get("scrap")) == scrap_skill_buy - pulse_skill_cost, "Pressing 购买 should spend the shelf price")
	hero.position = Vector2(640.0, 336.0)
	scene.call("_sync_skill_hud")
	assert(skill_near.text == "" and skill_near.icon == dash_tex, "Leaving the counter restores the skill slot")
	hero.position = Vector2(420.0, -20.0)
	scene.call("_sync_skill_hud")
	var skill_trainer := scene.find_child("SkillButton", true, false) as Button
	assert(skill_trainer != null and skill_trainer.text == "" and skill_trainer.icon == interact_tex and skill_trainer.icon != dash_tex, "Near a trainer counter the skill slot shows the pixel ! icon")
	assert(not shop_panel.visible, "Trainer counters stay self-serve without a stall panel")
	var forge_index := -1
	var skill_index := -1
	for slot_i: int in range(shop.slots.size()):
		var slot: Dictionary = shop.slots[slot_i]
		if slot.get("vendor", &"") != &"trainer":
			continue
		if slot.get("kind", &"") == &"forge":
			forge_index = slot_i
		if slot.get("kind", &"") == &"skill" and slot.get("payload", &"") != &"dash":
			skill_index = slot_i
	assert(forge_index >= 0, "Trainer should sell weapon forge")
	assert(skill_index >= 0, "Trainer should sell the hero skill")
	var skill_title := String(shop.slots[skill_index].get("title", ""))
	assert(skill_title == "技能提升" or skill_title == "技能 满级", "Trainer skill counter stays a generic upgrade")
	assert(not skill_title.contains("影分身") and not skill_title.contains("双持"), "Skill counter must not name a specific skill")
	scene.set("_is_game_over", false)
	shop.is_open = true
	scene.set("scrap", maxi(int(scene.get("scrap")), 2000))
	hero.equip_weapon(&"sword")
	hero.weapon_forge[&"sword"] = 0
	hero.skill_levels[&"ember_hero"] = 0
	scene.call("_sync_trainer_counters")
	# Re-find forge/skill after sync (titles/costs refresh).
	forge_index = -1
	skill_index = -1
	for slot_i: int in range(shop.slots.size()):
		var slot2: Dictionary = shop.slots[slot_i]
		if slot2.get("vendor", &"") != &"trainer":
			continue
		if slot2.get("kind", &"") == &"forge":
			forge_index = slot_i
		if slot2.get("kind", &"") == &"skill" and slot2.get("payload", &"") != &"dash":
			skill_index = slot_i
	assert(forge_index >= 0 and skill_index >= 0, "Trainer counters remain after sync")
	var forge_before := hero.forge_level_for(&"sword")
	scene.call("buy_shop_slot", forge_index)
	scene.call("buy_shop_slot", skill_index)
	assert(hero.forge_level_for(&"sword") > forge_before, "Forge should raise the current weapon attack")
	assert(hero.skill_level_for(&"ember_hero") == 1, "Knight first skill purchase should unlock dual fire")
	assert(hero.floating_weapon_count() == 2, "Knight skill_level 1 should fire two copies")
	var next_skill_title := ""
	for slot: Dictionary in shop.slots:
		if slot.get("kind", &"") == &"skill" and slot.get("payload", &"") != &"dash":
			next_skill_title = String(slot.get("title", ""))
	assert(next_skill_title == "技能提升" or next_skill_title == "技能 满级", "Next skill purchase stays a generic upgrade")
	assert(not next_skill_title.contains("三连") and not next_skill_title.contains("影分身"), "Skill counter must not name a specific skill")
	hero.skill_levels[&"ember_hero"] = 0
	assert(hero.floating_weapon_count() == 1, "Knight skill_level 0 should fire one copy")
	hero.skill_levels[&"ember_hero"] = 1
	assert(hero.floating_weapon_count() == 2, "Knight skill_level 1 should fire two copies")
	hero.skill_levels[&"ember_hero"] = 2
	assert(hero.floating_weapon_count() == 3, "Knight skill_level 2 should fire three copies")
	hero.skill_levels[&"ember_hero"] = 9
	assert(hero.floating_weapon_count() == 3, "Knight floating copies cap at 3")
	hero.skill_levels[&"ember_hero"] = 1
	hero.apply_hero_kind(&"assassin")
	assert(hero.clone_count() == 3, "Assassin clones start at 3")
	assert(hero.floating_weapon_count() == 1, "Assassin skill must not add extra floating guns")
	assert(hero.apply_skill_upgrade(), "Assassin skill should add a clone")
	assert(hero.clone_count() == 4, "Assassin clones should be 3 + skill_level")
	assert(hero.floating_weapon_count() == 1, "Assassin clone upgrades must not piggyback onto floating guns")
	hero.apply_hero_kind(&"ember_hero")

	hero.skill_levels[&"ember_hero"] = 0
	hero.turret_hand = false
	hero.equip_weapon(&"sword")
	assert(hero.apply_skill_upgrade(), "Live N path should apply knight skill 1")
	assert(hero.apply_skill_upgrade(), "Live N path should apply knight skill 2")
	assert(hero.skill_level_for(&"ember_hero") == 2, "Two apply_skill_upgrade calls should reach skill_level 2")
	assert(hero.floating_weapon_count() == 3, "Live N x2 should orbit three copies")
	var n_orbit1 := hero.find_child("HeldOrbit1", true, false) as Sprite2D
	var n_orbit2 := hero.find_child("HeldOrbit2", true, false) as Sprite2D
	assert(n_orbit1 != null and n_orbit1.visible and n_orbit1.texture != null, "Live N x2 must spawn visible HeldOrbit1")
	assert(n_orbit2 != null and n_orbit2.visible and n_orbit2.texture != null, "Live N x2 must spawn visible HeldOrbit2")

	hero.skill_levels[&"ember_hero"] = 2
	hero.equip_weapon(&"sword")
	hero.call("_refresh_held_weapon")
	hero.call("_update_held_weapon")
	var orbit1 := hero.find_child("HeldOrbit1", true, false) as Sprite2D
	var orbit2 := hero.find_child("HeldOrbit2", true, false) as Sprite2D
	assert(orbit1 != null and orbit1.visible and orbit1.texture != null, "Knight skill_level 2 should show HeldOrbit1")
	assert(orbit2 != null and orbit2.visible and orbit2.texture != null, "Knight skill_level 2 should show HeldOrbit2")
	assert(hero.combat_float_origins().size() == 3, "Knight skill_level 2 should expose three combat float origins")
	var melee_origins: Array[Vector2] = []
	var floats_at_hit: Array[Vector2] = []
	var on_melee := func(origin: Vector2, _facing: int) -> void:
		melee_origins.append(origin)
		if floats_at_hit.is_empty():
			for point: Vector2 in hero.combat_float_origins():
				floats_at_hit.append(point)
	hero.attacked.connect(on_melee)
	hero._attack_cooldown = 0.0
	hero.request_attack()
	var max_orbit_rot := 0.0
	var melee_wait := 0
	while melee_origins.is_empty() and melee_wait < 40:
		await create_timer(0.03).timeout
		max_orbit_rot = maxf(max_orbit_rot, absf(orbit1.rotation))
		melee_wait += 1
	hero.attacked.disconnect(on_melee)
	assert(melee_origins.size() == 3, "Knight skill copies should resolve three melee hits")
	assert(floats_at_hit.size() == 3, "Melee extras should sample live HeldOrbit sprites")
	var body_slash := hero.global_position + Vector2(28.0 * float(hero.get_facing()), -18.0)
	assert(melee_origins[0].distance_to(body_slash) < 8.0, "Body slash should stay on the hero")
	assert(melee_origins[1].distance_to(floats_at_hit[1]) < 1.0, "Second melee copy should slash from HeldOrbit1")
	assert(melee_origins[2].distance_to(floats_at_hit[2]) < 1.0, "Third melee copy should slash from HeldOrbit2")
	assert(melee_origins[1].distance_to(body_slash + Vector2(0.0, 10.0)) > 12.0, "Orbit melee must not use the fake 10px Y-stack")
	assert(max_orbit_rot > 0.55, "Orbiting swords should slash when the knight attacks")
	await create_timer(0.25).timeout
	var slash_before := scene.find_children("MeleeSlash", "", true, false).size()
	scene.call("_on_hero_attacked", body_slash, hero.get_facing())
	var slash_after := scene.find_children("MeleeSlash", "", true, false).size()
	assert(slash_after >= slash_before + 1, "Each attacked origin should spawn one slash, not Y-stacked copies")

	hero.equip_weapon(&"pistol")
	hero.call("_refresh_held_weapon")
	hero.call("_update_held_weapon")
	var expected_muzzles := hero.combat_float_origins()
	assert(expected_muzzles.size() == 3, "Knight pistol copies should be three visible floats")
	var shot_origins: Array[Vector2] = []
	var on_shot := func(origin: Vector2, _aim: Vector2, _id: StringName) -> void:
		shot_origins.append(origin)
	hero.ranged_fired.connect(on_shot)
	var shots_before := hero.ranged_shots_emitted
	hero._attack_cooldown = 0.0
	hero.request_attack()
	hero.ranged_fired.disconnect(on_shot)
	assert(hero.ranged_shots_emitted == shots_before + 1, "Ranged copies should still count as one fire")
	assert(shot_origins.size() == 3, "Knight skill_level 2 should fire three shots")
	for shot_i: int in range(3):
		assert(shot_origins[shot_i].distance_to(expected_muzzles[shot_i]) < 1.0, "Ranged copies should fire from HeldOrbit world positions")

	hero.add_turret(&"pulse")
	assert(hero.set_turret_hand(true), "Turret-hand should select the stashed pulse")
	assert(hero.combat_float_origins().is_empty(), "Turret-hand is not a combat float")
	var turret_sprite := hero.find_child("HeldWeapon", true, false) as Sprite2D
	assert(turret_sprite != null and turret_sprite.visible, "Turret-hand should keep the cannon sprite")
	var turret_pos := turret_sprite.global_position
	shot_origins.clear()
	hero.ranged_fired.connect(on_shot)
	hero._attack_cooldown = 0.0
	hero.request_attack()
	hero.ranged_fired.disconnect(on_shot)
	assert(shot_origins.size() == 1, "Turret-hand should not extra-fire from the held cannon")
	assert(shot_origins[0].distance_to(turret_pos) > 8.0, "Turret-hand must not shoot from the turret sprite")
	hero.set_turret_hand(false)
	hero.equip_weapon(&"sword")
	hero.set_turret_hand(true)
	hero.call("_update_held_weapon")
	melee_origins.clear()
	hero.attacked.connect(on_melee)
	hero._attack_cooldown = 0.0
	hero.request_attack()
	var turret_swung := false
	var turret_wait := 0
	while melee_origins.is_empty() and turret_wait < 40:
		await create_timer(0.03).timeout
		if absf(turret_sprite.rotation) > 0.40:
			turret_swung = true
		turret_wait += 1
	hero.attacked.disconnect(on_melee)
	assert(melee_origins.size() == 1, "Turret-hand melee should keep only the body slash")
	assert(not turret_swung, "Turret-hand must not slash-sync")
	hero.set_turret_hand(false)

	hero.apply_hero_kind(&"assassin")
	hero.equip_weapon(&"sword")
	hero.call("_refresh_held_weapon")
	hero.call("_update_held_weapon")
	assert(hero.floating_weapon_count() == 1, "Assassin stays one floating weapon")
	assert(hero.combat_float_origins().size() == 1, "Assassin should expose one combat float")
	var assassin_orbit := hero.find_child("HeldOrbit1", true, false) as Sprite2D
	assert(assassin_orbit == null or not assassin_orbit.visible or assassin_orbit.texture == null, "Assassin should not show extra orbit copies")
	melee_origins.clear()
	hero.attacked.connect(on_melee)
	hero._attack_cooldown = 0.0
	hero.request_attack()
	var assassin_wait := 0
	while melee_origins.is_empty() and assassin_wait < 40:
		await create_timer(0.03).timeout
		assassin_wait += 1
	hero.attacked.disconnect(on_melee)
	assert(melee_origins.size() == 1, "Assassin melee stays one copy")
	hero.equip_weapon(&"pistol")
	hero.call("_refresh_held_weapon")
	hero.call("_update_held_weapon")
	var assassin_muzzles := hero.combat_float_origins()
	assert(assassin_muzzles.size() == 1, "Assassin ranged stays one muzzle")
	shot_origins.clear()
	hero.ranged_fired.connect(on_shot)
	hero._attack_cooldown = 0.0
	hero.request_attack()
	hero.ranged_fired.disconnect(on_shot)
	assert(shot_origins.size() == 1, "Assassin should fire one shot")
	assert(shot_origins[0].distance_to(assassin_muzzles[0]) < 1.0, "Assassin shot should come from the held sprite")
	assert(hero.current_state == &"attack", "Assassin pistol fire should play a body attack clip")
	assert(float(hero.get("_attack_elapsed")) >= 0.0, "Assassin pistol fire should lock the attack visual")

	hero.apply_hero_kind(&"ember_hero")
	hero.skill_levels[&"ember_hero"] = 1
	hero.equip_weapon(&"sword")
	hero.call("_refresh_held_weapon")

	scene.call("start_wave")
	assert(not shop_panel.visible, "Combat should close the stall panel")
	assert(hero.position.y > 72.0, "Combat must eject the hero through the shop's south door")
	assert(bool(scene.call("_is_walkable", hero.position)), "Shop ejection must land on a walkable combat tile")
	var ejected_position := hero.position
	hero.move_in_direction(Vector2.DOWN, 0.15)
	assert(hero.position.y > ejected_position.y, "The hero must be able to move after shop ejection")
	assert(not bool(scene.call("is_shop_gate_open")), "Combat should close the shop gate")
	assert(scene.get("current_wave") == 1, "First wave should start at wave 1")
	assert(scene.get("_wave_active"), "Wave should be active after launch")
	var combat_towers: int = (scene.get("_towers") as Array).size()
	var scrap_before_combat_place: int = int(scene.get("scrap"))
	scene.set("scrap", 500)
	hero.turret_hand = false
	scene.call("_try_place_tower", Vector2(888.0, 360.0))
	assert((scene.get("_towers") as Array).size() == combat_towers, "Combat must not scrap-build a default tower on an empty tile")
	assert(int(scene.get("scrap")) == 500, "Combat tile click must not spend scrap to build")
	scene.set("scrap", scrap_before_combat_place)
	await create_timer(1.35).timeout
	assert(scene.get("_enemies").size() > 0, "Wave should spawn enemies")
	# Empty hologram pads are silent — mount a pistol so the projectile loop still fires.
	var combat_pad: EmberTower = scene.call("_spawn_tower_at", Vector2(920.0, 360.0), &"pulse", 1)
	assert(combat_pad != null, "Combat kill probe needs a mounted pad")
	combat_pad.mount_weapon(&"pistol")
	var kill_probe := FrontierEnemy.new()
	kill_probe.variant = &"scout"
	kill_probe.max_health = 20
	kill_probe.move_speed = 0.0
	kill_probe.configure_seek(Vector2(968.0, 360.0), scene.call("core_goal") as Vector2, scene)
	scene.call("_register_enemy", kill_probe)
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

	var reward_scene: Node = load("res://main.tscn").instantiate()
	root.add_child(reward_scene)
	await process_frame
	reward_scene.call("start_wave")
	reward_scene.set("_restoring_run", true)
	var reward_shop: EmberShop = reward_scene.get("_shop")
	reward_shop.slots.clear()
	reward_scene.set("scrap", 125)
	reward_scene.call("_finish_wave")
	assert(int(reward_scene.get("scrap")) == 175, "Finishing a wave must grant exactly 50 scrap")
	var reward_status := reward_scene.find_child("StatusLabel", true, false) as Label
	assert(reward_status != null and reward_status.text.contains("+50"), "Wave-clear feedback must keep the +50 reward visible")
	reward_scene.queue_free()
	await process_frame
	EmberRunSave.delete_run()

	var auto_scene: Node = load("res://main.tscn").instantiate()
	root.add_child(auto_scene)
	await process_frame
	var director: WaveDirector = auto_scene.get("_director")
	director.prep_duration = 0.2
	director.prep_left = 0.2
	var auto_wait := 0.0
	while (not bool(auto_scene.get("_wave_active"))) and auto_wait < 2.0:
		await create_timer(0.1).timeout
		auto_wait += 0.1
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
		"hero": {
			"health": 80, "max_health": 100, "weapon": "sword",
			"has_dash": false, "attack_bonus_level": 0,
			"vitality_level": 0, "dash_cd_level": 0,
			"weapon_forge": {"sword": 2},
			"skill_levels": {"ember_hero": 1, "assassin": 2},
			"turret_stash": {"pulse": 2},
			"turret_hand": true,
			"position": [640.0, 336.0],
		},
		"towers": [],
		"drop_rng_state": 1,
		"shop_rng_state": 1,
		"slots": [{"kind": "tower", "payload": "pulse", "cost": 86, "sold": false, "vendor": "merchant", "title": "脉冲塔"}],
	}, "user://run_smoke.json")
	var loaded_run := EmberRunSave.load_run("user://run_smoke.json")
	assert(not loaded_run.is_empty() and int(loaded_run.get("cleared_wave", 0)) == 2, "Smoke save path should round-trip")
	var loaded_hero: Dictionary = loaded_run.get("hero", {})
	assert(int((loaded_hero.get("weapon_forge", {}) as Dictionary).get("sword", 0)) == 2, "Save should keep forge levels")
	assert(int((loaded_hero.get("skill_levels", {}) as Dictionary).get("assassin", 0)) == 2, "Save should keep assassin skill")
	assert(int((loaded_hero.get("turret_stash", {}) as Dictionary).get("pulse", 0)) == 2, "Save should keep turret stash")
	assert(bool(loaded_hero.get("turret_hand", false)), "Save should keep turret-hand")
	EmberRunSave.update_records(2, 12, 30.0, "user://records_smoke.json")
	var records := EmberRunSave.load_records("user://records_smoke.json")
	assert(int(records.get("highest_wave", 0)) == 2, "Records smoke path should store high-water wave")
	EmberRunSave.delete_run("user://run_smoke.json")
	EmberRunSave.delete_records("user://records_smoke.json")

	while not (scene.get("_towers") as Array).is_empty():
		scene.call("_select_tower", (scene.get("_towers") as Array)[0])
		scene.call("sell_selected_tower")
	scene.set("scrap", 300)
	var hp_tower: EmberTower = scene.call("_spawn_tower_at", Vector2(990.0, 205.0), &"pulse", 1)
	assert(hp_tower != null, "HP probe tower should spawn")
	assert(hp_tower.max_health == 120, "Default tower HP is 120")
	assert(hp_tower.health == 120, "New tower starts at full HP")
	var wreck_cell: Vector2i = scene.call("_cell_at", hp_tower.position)
	var wreck_pos: Vector2 = hp_tower.position
	var scrap_before_break: int = int(scene.get("scrap"))
	hp_tower.take_damage(120)
	await scene.get_tree().process_frame
	assert((scene.get("_towers") as Array).is_empty(), "0 HP must clear the tower from the pad")
	assert(not (scene.get("_cell_towers") as Dictionary).has(wreck_cell), "Destroyed tower must leave the cell empty")
	assert(int(scene.get("scrap")) == scrap_before_break, "Destroy must not refund scrap")
	hero.position = wreck_pos
	hero.turret_hand = false
	var rebuilt := bool(scene.call("try_rebuild_nearby"))
	assert(rebuilt, "Standing on wrecked pad should rebuild")
	assert((scene.get("_towers") as Array).size() == 1, "Rebuild should place the same kind")
	assert((scene.get("_cell_towers") as Dictionary).has(wreck_cell), "Rebuild should occupy the wrecked cell")
	assert(int(scene.get("scrap")) == scrap_before_break - 80, "Pulse rebuild costs 80")
	var rebuilt_tower: EmberTower = (scene.get("_towers") as Array)[0]
	assert(rebuilt_tower.kind == &"pulse" and rebuilt_tower.weapon_id == &"", "Rebuild keeps pulse as an empty cannon")

	# --- SK parity probes ---
	assert(scene.has_method("clear_enemy_bullets_in_radius"), "Clear-bullet helper must exist")
	scene.call("spawn_enemy_projectile", hero.global_position + Vector2(40, 0), Vector2.LEFT, 5)
	var cleared: int = int(scene.call("clear_enemy_bullets_in_radius", hero.global_position, 80.0))
	assert(cleared >= 1, "Melee/dash clear radius must recycle enemy bullets")
	var silent: EmberTower = scene.call("_spawn_tower_at", Vector2(760.0, 250.0), &"pulse", 1)
	assert(silent != null and silent.weapon_id == &"" and silent.is_hologram_pad(), "Empty hologram pad for silence probe")
	assert(silent.has_method("is_hologram_pad"), "Pad helper present")
	# Empty pads skip fire: cooldown stays at 0 while no weapon is mounted.
	silent.set("_cooldown_left", 0.0)
	for _i: int in range(30):
		silent.call("_process", 0.05)
	assert(float(silent.get("_cooldown_left")) == 0.0, "Empty pad must not enter fire cooldown")
	var barrier: EmberTower = scene.call("_spawn_tower_at", Vector2(700.0, 250.0), &"barrier", 1)
	assert(barrier != null and barrier.blocks_enemies(), "Barrier facility blocks enemies")
	assert(EmberTower.build_cost(&"amplifier") == 100, "Amplifier costs 100")
	assert(EmberRunSave.is_valid_tower_kind(&"pulse_clear"), "pulse_clear is a valid facility kind")
	var fac_probe: EmberHero = scene.get_node("HeroSlot/HeroController")
	var stash_snap: Dictionary = fac_probe.turret_stash.duplicate(true)
	var hand_snap := fac_probe.turret_hand
	fac_probe.turret_stash.clear()
	fac_probe.add_turret(&"pulse_clear")
	fac_probe.set_turret_hand(true)
	assert(fac_probe.current_turret_kind() == &"pulse_clear", "Bought facilities must be selectable from turret hand")
	fac_probe.turret_stash = stash_snap
	fac_probe.set_turret_hand(hand_snap and fac_probe.turret_stash_count() > 0)
	assert(FileAccess.file_exists("res://assets/generated/towers/barrier.png"), "Barrier art must exist")
	assert(FileAccess.file_exists("res://assets/generated/npc/summoner.png"), "Summoner art must exist")
	assert(FileAccess.file_exists("res://assets/generated/ui/home-chest.png"), "Home chest art must exist")
	assert(float(WeaponCatalog.get_def(&"pistol").get("bloom", 0.0)) > 0.0, "Pistol bloom must be non-zero")
	assert(bool(scene.call("_needs_boss")) == false or scene.get("current_wave") % 15 == 0, "Boss cadence helper exists")
	assert(scene.has_method("_is_mass_wave"), "Mass-wave helper exists")
	assert(scene.has_method("repair_all_mechs"), "Mech repair-all exists")
	assert(scene.has_method("amplifier_damage_mult"), "Amplifier aura helper exists")

	print("SMOKE TEST PASS: SK endless TD parity — clear bullets, facilities, mentor, portals, hero-death fail")
	quit()

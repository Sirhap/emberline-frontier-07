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
	assert(scene.find_child("HeroSelect_assassin", true, false) != null, "HUD should expose assassin select")
	assert(scene.find_child("HeroSelect_ember_hero", true, false) != null, "HUD should expose knight select")

	var cheats: Array = scene.get("DEV_CHEATS")
	assert(cheats.size() >= 16, "DEV_CHEATS must list live overlay keys")
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
			assert(shown <= 42.0, "Home rewards must stay pickup-sized in the shop view")
	assert(home_kinds.has(&"scrap"), "Three home rewards must include scrap")
	hero.global_position = Vector2(252.0, 336.0)
	await process_frame
	scene.call("_process_pickups")
	assert((scene.get("_pickups") as Array).size() < 3, "Walking onto a home reward should collect it")
	for leftover: Variant in (scene.get("_pickups") as Array).duplicate():
		if leftover is EmberPickup and is_instance_valid(leftover):
			(leftover as EmberPickup).queue_free()
	scene.set("_pickups", [])
	scene.set("scrap", 300)
	var economy_shop: EmberShop = EmberShop.new()
	economy_shop.refresh(2, true, 10, 10)
	assert(economy_shop.slots.size() >= 4, "Wave 2 shop must expose the fourth merchant slot")
	assert(economy_shop.slots[3].get("kind", &"") == &"scrap", "A full core must offer emergency scrap, not another random tower")
	assert(int(economy_shop.slots[3].get("cost", -1)) == 0, "Emergency scrap must be free")
	var live_shop: EmberShop = scene.get("_shop")
	var saved_slots: Array = live_shop.slots.duplicate(true)
	live_shop.restore_slots([economy_shop.slots[3].duplicate(true)])
	scene.set("_talking_npc", &"merchant")
	scene.call("buy_shop_slot", 0)
	assert(int(scene.get("scrap")) == 340, "Claiming emergency scrap must add 40 scrap")
	live_shop.restore_slots(saved_slots)
	scene.set("_talking_npc", &"")
	scene.set("scrap", 300)
	scene.call("_refresh_shop_ui")
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
	assert(skill_button.disabled, "A locked skill pad should not be usable")
	var skill_overlay := skill_button.find_child("SkillPadOverlay", true, false)
	assert(skill_overlay != null, "Skill pad should keep a state overlay")
	assert(skill_overlay.get("mode") == &"locked", "A locked skill pad should draw the unused overlay")
	assert(scene.find_child("MoveStick", true, false) != null, "Mobile virtual stick should be present")
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
	scene.call("_try_place_tower", Vector2(990.0, 205.0))
	var selected_tower: EmberTower = scene.get("_selected_tower")
	assert(selected_tower != null, "Clicking an occupied pad should select the tower")
	scene.call("upgrade_selected_tower")
	assert(selected_tower.level == 2, "Selected tower should upgrade to level 2")
	assert(selected_tower.attack_damage == 38, "Level 2 tower should deal more damage")
	assert(scene.get("scrap") == 110, "Level 2 upgrade should cost 110 scrap")

	scene.set("scrap", 500)
	scene.set("default_tower_kind", &"burst")
	scene.call("_spawn_tower_at", Vector2(820.0, 205.0), &"burst", 1)
	scene.set("default_tower_kind", &"frost")
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
	var before_ninth: int = (scene.get("_towers") as Array).size()
	var scrap_before_ninth: int = int(scene.get("scrap"))
	scene.call("_try_place_tower", Vector2(720.0, 336.0))
	assert((scene.get("_towers") as Array).size() == before_ninth, "A ninth tower must fail")
	assert(int(scene.get("scrap")) == scrap_before_ninth, "Failed ninth placement must not spend scrap")
	scene.call("_try_place_tower", Vector2(990.0, 205.0))
	scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).size() == 7, "Selling should free a pad")
	assert(int(scene.get("scrap")) == scrap_before_ninth + 48, "Pulse sell refund is 60% of build cost")
	scene.call("_spawn_tower_at", Vector2(990.0, 205.0), &"pulse", 1)
	assert((scene.get("_towers") as Array).size() == 8, "Freed pad should accept a new tower")
	scene.call("_try_place_tower", Vector2(888.0, 360.0))
	scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).size() == 7, "Pad 7 should be empty for the combat placement probe")

	var melee_hits := hero.total_attack_hits_emitted
	var held := hero.find_child("HeldWeapon", true, false) as Sprite2D
	assert(held != null and held.texture != null and held.visible, "Starter hero should hold the greatsword overlay")
	assert(held.position.y <= -18.0, "Knight sword grip should sit in the hand, not at the shins")
	assert(held.position.y >= -90.0, "Knight sword should stay on the body after the scale restore")
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
	assert((assassin_idle.get("frames", []) as Array).size() == 8, "Assassin idle must stay a standing loop")
	assert((assassin_down.get("frames", []) as Array).size() >= 3, "Assassin down must exist as a terminal clip")
	assert(float(assassin_actor.call("animation_duration", "skill_cast")) >= 0.70, "Assassin skill_cast should last through the spin")
	hero.health = hero.max_health
	hero.down_duration = 0.25
	hero.take_damage(999)
	assert(hero.is_down and hero.current_state == &"down", "Assassin fatal damage should play down, not idle")
	await create_timer(0.45).timeout
	assert(not hero.is_down, "Assassin should revive after the down clip")
	assert(hero.select_weapon_slot(0) and hero.current_weapon == &"sword", "Assassin melee probe uses the starter sword")
	assert(not held.visible, "Assassin melee must hide the hold overlay")
	assert(held.texture == null, "Assassin melee must clear the hold texture")
	assert(hero.select_weapon_slot(1) and WeaponCatalog.is_ranged(hero.current_weapon), "Assassin gun probe needs a ranged slot")
	assert(held.visible and held.texture != null, "Assassin ranged may show the catalog gun overlay")
	hero.unlock_dash()
	hero.dash_cooldown_left = 0.0
	hero.request_dash()
	assert(hero.current_state == &"dash", "Assassin skill should reuse the dash slot")
	var clone_count := 0
	for child: Node in hero.get_children():
		if String(child.name).begins_with("ShadowClone"):
			clone_count += 1
	assert(clone_count == 3, "Assassin skill should spawn three bubble clones")
	hero.apply_hero_kind(&"ember_hero")
	await process_frame
	assert(hero.hero_kind == &"ember_hero", "Smoke must restore the knight after assassin checks")

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
	assert(hero.position.y >= 217.0, "East corridor north wall should block walking into the void")
	hero.position = Vector2(1500.0, 620.0)
	hero.move_in_direction(Vector2.DOWN, 0.50)
	assert(hero.position.y > 640.0, "Hero should walk out the south-east road")
	hero.position = Vector2(640.0, 620.0)
	hero.move_in_direction(Vector2.DOWN, 0.50)
	assert(hero.position.y <= 640.0, "South wall stays at the original combat edge")
	hero.position = Vector2(568.0, 140.0)
	hero.move_in_direction(Vector2.UP, 0.90)
	assert(hero.position.y < 112.0, "Hero should walk north through the shop door")
	var trainer := scene.find_child("NpcTrainer", true, false) as Sprite2D
	assert(trainer != null, "Trainer should stand in the north trainer room")
	hero.position = Vector2(800.0, -80.0)
	hero.move_in_direction(Vector2.UP, 0.35)
	var trainer_body: Vector2 = trainer.get_meta("rest_pos", trainer.global_position) + Vector2(0.0, 24.0)
	assert(hero.position.distance_to(trainer_body) >= 34.0, "Hero should collide with the trainer instead of walking through")
	assert(scene.find_child("NpcMerchant", true, false) != null, "Merchant should stand in the north merchant room")
	assert(scene.find_child("ShopPen", true, false) != null, "Home shop rooms should still expose ShopPen")
	var north_portal := scene.find_child("SpawnPortalNorth", true, false) as Node2D
	var south_portal := scene.find_child("SpawnPortalSouth", true, false) as Node2D
	var east_portal := scene.find_child("SpawnPortalEast", true, false) as Node2D
	assert(north_portal != null, "North enemy mouth should have a portal")
	assert(south_portal != null, "South enemy mouth should have a portal")
	assert(east_portal != null, "East enemy mouth should have a portal")
	var tile_w := 1280.0 / 1536.0 * 64.0
	var tile_h := 720.0 / 1024.0 * 64.0
	var wall_h := 80.0 * (720.0 / 1024.0)
	var east_wall_x := 1760.0 + 8.0 * tile_w
	var east_hole_y0 := -8.0 + 6.5 * tile_h
	var east_hole_y1 := -8.0 + 8.5 * tile_h
	assert(east_portal.position.x > east_wall_x and east_portal.position.x < east_wall_x + 2.0 * tile_w, "East portal must sit in the wall hole, not out in the void")
	assert(east_portal.position.y > east_hole_y0 and east_portal.position.y < east_hole_y1, "East portal must sit in the east wall opening")
	var north_end_y := -8.0 - 12.0 * tile_h - wall_h
	assert(north_portal.position.y > north_end_y and north_portal.position.y < north_end_y + wall_h, "North portal must sit in the end-wall hole")
	var south_end_y := 640.0 + 16.0 * tile_h
	assert(south_portal.position.y > south_end_y and south_portal.position.y < south_end_y + wall_h, "South portal must sit in the end-wall hole")
	var mouth_mid_x := 24.0 * (1280.0 / 1536.0 * 64.0) + 2.5 * (1280.0 / 1536.0 * 64.0)
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

	hero.position = Vector2(320.0, -110.0)
	assert(bool(scene.call("try_talk_to_nearby_npc")), "Standing next to the merchant should allow talking")
	assert(shop_panel.visible, "Talking to the merchant should open their stall")
	assert(not mini.visible, "Opening a shop must hide the overlapping mini-map")
	var place_ghost := scene.find_child("PlaceGhost", true, false) as Sprite2D
	assert(place_ghost != null, "Tile hover should have a placement ghost")
	assert(not place_ghost.visible, "Prep without a held tower must not draw a place ghost")
	var place_fill := scene.find_child("PlaceFill", true, false) as Polygon2D
	assert(place_fill != null, "Tile hover should have a gold cell fill")
	assert(not place_fill.visible, "Prep without a held tower must not draw a gold cell")
	var towers_before_gun: int = (scene.get("_towers") as Array).size()
	scene.call("_try_place_tower", Vector2(188.0, 263.0))
	assert((scene.get("_towers") as Array).size() == towers_before_gun, "The crystal dais must reject towers")
	scene.call("buy_shop_slot", 1)
	var shop: EmberShop = scene.get("_shop")
	assert(shop.held_kind == &"pistol", "Wave 1 weapon shelf should hold a pistol for placing")
	scene.set("_place_preview_world", Vector2(720.0, 380.0))
	scene.call("_sync_place_preview")
	assert(place_ghost.visible, "Holding a shop weapon should ghost the hovered floor tile")
	assert(place_ghost.texture != null, "Place ghost should use the held weapon art")
	assert(place_fill.visible, "Holding a shop weapon should mark the hovered floor tile")
	var hover_rect: Rect2 = scene.call("_cell_rect", scene.call("_cell_at", Vector2(720.0, 380.0)))
	var atlas_x := hover_rect.position.x / (1280.0 / 1536.0)
	var atlas_y := (hover_rect.position.y + 8.0) / (720.0 / 1024.0)
	assert(minf(fposmod(atlas_x - 4.0, 64.0), 64.0 - fposmod(atlas_x - 4.0, 64.0)) < 0.6, "Place preview X must sit on painted grout phase 4")
	assert(minf(fposmod(atlas_y - 42.0, 64.0), 64.0 - fposmod(atlas_y - 42.0, 64.0)) < 0.6, "Place preview Y must sit on painted grout phase 42")
	scene.call("_try_place_tower", Vector2(720.0, 380.0))
	scene.set("_place_preview_world", Vector2(INF, INF))
	scene.call("_sync_place_preview")
	var after_gun: Array = scene.get("_towers")
	assert(after_gun.size() == towers_before_gun + 1, "Buying a shop weapon should plant it on a floor tile")
	var planted: EmberTower = after_gun[after_gun.size() - 1]
	assert(planted.weapon_id == &"pistol", "Planted shop weapon must keep its catalog id")
	var planted_cell: Vector2i = scene.call("_cell_at", planted.position)
	var snapped: Vector2 = scene.call("_cell_center", planted_cell)
	assert(planted.position.distance_to(snapped) < 1.0, "Planted turret must sit on a floor-tile center")
	scene.call("sell_selected_tower")
	assert((scene.get("_towers") as Array).size() == towers_before_gun, "Selling the planted weapon should free the tile")
	hero.position = Vector2(800.0, -110.0)
	assert(bool(scene.call("try_talk_to_nearby_npc")), "Standing next to the trainer should switch stalls")
	assert(shop_panel.visible, "Talking to the trainer should keep a stall open")

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
	scene.set("scrap", 500)
	scene.set("default_tower_kind", &"pulse")
	scene.call("_try_place_tower", Vector2(888.0, 360.0))
	assert((scene.get("_towers") as Array).size() == combat_towers + 1, "Combat should allow placing towers on an empty tile")
	await create_timer(1.35).timeout
	assert(scene.get("_enemies").size() > 0, "Wave should spawn enemies")
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

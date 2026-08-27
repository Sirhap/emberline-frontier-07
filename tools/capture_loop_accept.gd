extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	var shop: EmberShop = scene.get("_shop")
	var shop_panel := scene.find_child("ShopPanel", true, false) as Control

	hero.apply_hero_kind(&"ember_hero")
	hero.equip_weapon(&"sword")
	scene.set("_talking_npc", &"")
	scene.call("_refresh_shop_ui")

	# Hall: merchant 3 + trainer 2, no talk panel.
	hero.position = Vector2(540.0, -70.0)
	_snap(cam, Vector2(540.0, -90.0))
	await process_frame
	await process_frame
	_save("res://tools/look-accept-shop-hall.png")
	print("HALL panel=%s talking=%s slots=%s" % [
		shop_panel.visible if shop_panel else false,
		scene.get("_talking_npc"),
		_slot_summary(shop),
	])
	var shelf_vis: Array[String] = []
	for i: int in range(5):
		var shelf := scene.find_child("ShopShelf%d" % i, true, false) as Sprite2D
		shelf_vis.append("%d vis=%s tex=%s pos=%s" % [
			i,
			shelf.visible if shelf else false,
			shelf.texture.resource_path.get_file() if shelf and shelf.texture else "",
			shelf.position if shelf else Vector2.ZERO,
		])
	print("SHELVES %s" % " | ".join(shelf_vis))

	# Far click must not buy.
	hero.position = Vector2(640.0, 336.0)
	var scrap0: int = int(scene.get("scrap"))
	var slots0 := hero.weapon_slots.duplicate()
	scene.call("_try_buy_shelf", Vector2(320.0, -70.0))
	print("FAR scrap=%s->%s slots=%s panel=%s" % [
		scrap0, int(scene.get("scrap")), hero.weapon_slots, shop_panel.visible if shop_panel else false,
	])

	# Near pistol counter, no E-talk.
	hero.position = Vector2(320.0, -70.0)
	scene.set("_talking_npc", &"")
	scene.call("_refresh_shop_ui")
	scene.call("_try_buy_shelf", Vector2(320.0, -70.0))
	_snap(cam, Vector2(320.0, -90.0))
	await process_frame
	await process_frame
	_save("res://tools/look-accept-buy-pistol.png")
	print("BUY_PISTOL slots=%s current=%s scrap=%s restock_sold=%s restock=%s panel=%s" % [
		hero.weapon_slots,
		hero.current_weapon,
		int(scene.get("scrap")),
		shop.slots[1].get("sold", false),
		shop.slots[1].get("payload", &""),
		shop_panel.visible if shop_panel else false,
	])

	# Pulse turret into stash.
	hero.position = Vector2(200.0, -70.0)
	scene.call("_try_buy_shelf", Vector2(200.0, -70.0))
	print("BUY_PULSE stash=%s scrap=%s" % [hero.turret_stash, int(scene.get("scrap"))])
	hero.cycle_weapon()
	scene.call("_sync_weapon_hud")
	_snap(cam, Vector2(200.0, -90.0))
	await process_frame
	await process_frame
	_save("res://tools/look-accept-turret-hand-dock.png")
	var dock := scene.find_child("WeaponSwitch", true, false) as Button
	var dock_count := scene.find_child("WeaponCount", true, false) as Label
	print("DOCK turret_hand=%s count=%s icon=%s text=%s" % [
		hero.turret_hand,
		dock_count.text if dock_count else "",
		dock.icon.resource_path.get_file() if dock and dock.icon else "",
		dock_count.visible if dock_count else false,
	])

	# Place in prep.
	hero.position = Vector2(720.0, 380.0)
	scene.set("_place_preview_world", Vector2(720.0, 380.0))
	scene.call("_sync_place_preview")
	_snap(cam, Vector2(720.0, 360.0))
	await process_frame
	await process_frame
	_save("res://tools/look-accept-place-ghost.png")
	scene.call("_try_place_tower", Vector2(720.0, 380.0))
	scene.set("_place_preview_world", Vector2(INF, INF))
	scene.call("_sync_place_preview")
	await process_frame
	await process_frame
	_save("res://tools/look-accept-placed.png")
	var towers: Array = scene.get("_towers")
	var planted: EmberTower = towers[towers.size() - 1]
	print("PLACE kind=%s weapon=%s stash=%s towers=%d" % [
		planted.kind, planted.weapon_id, hero.turret_stash, towers.size(),
	])

	# Mount pistol onto empty pad.
	hero.turret_hand = false
	hero.select_weapon_slot(1)
	scene.call("_sync_weapon_hud")
	scene.call("_try_place_tower", planted.position)
	await process_frame
	await process_frame
	_save("res://tools/look-accept-mounted.png")
	print("MOUNT weapon_id=%s slots=%s" % [planted.weapon_id, hero.weapon_slots])

	# Swap: click pad with sword in hand.
	hero.select_weapon_slot(0)
	scene.call("_try_place_tower", planted.position)
	print("SWAP weapon_id=%s slots=%s" % [planted.weapon_id, hero.weapon_slots])

	# Trainer two counters, never sold-out.
	hero.position = Vector2(800.0, -70.0)
	_snap(cam, Vector2(800.0, -90.0))
	await process_frame
	await process_frame
	_save("res://tools/look-accept-trainer.png")
	print("TRAINER slots=%s" % _slot_summary(shop))

	# Combat: no scrap-build; stash-place still works.
	scene.call("start_wave")
	await process_frame
	var combat_n: int = (scene.get("_towers") as Array).size()
	scene.set("scrap", 500)
	hero.turret_hand = false
	scene.call("_try_place_tower", Vector2(888.0, 360.0))
	print("COMBAT_SCRAP_BUILD towers=%s->%s scrap=%s" % [combat_n, (scene.get("_towers") as Array).size(), int(scene.get("scrap"))])
	hero.add_turret(&"frost")
	hero.turret_hand = true
	scene.call("_try_place_tower", Vector2(888.0, 360.0))
	var after_combat: Array = scene.get("_towers")
	var last_tower: EmberTower = after_combat[after_combat.size() - 1]
	print("COMBAT_STASH_PLACE towers=%s stash=%s kind_last=%s" % [
		after_combat.size(),
		hero.turret_stash,
		last_tower.kind,
	])
	print("LOOP_ACCEPT_CAPTURE ok")
	quit()


func _slot_summary(shop: EmberShop) -> String:
	var parts: Array[String] = []
	for slot: Dictionary in shop.slots:
		parts.append("%s/%s/%s sold=%s" % [
			slot.get("vendor", &""),
			slot.get("kind", &""),
			slot.get("payload", &""),
			slot.get("sold", false),
		])
	return " ; ".join(parts)


func _snap(cam: Camera2D, world: Vector2) -> void:
	if cam != null:
		cam.global_position = world
		cam.reset_smoothing()
		cam.force_update_scroll()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SAVED %s err=%s" % [path, err])

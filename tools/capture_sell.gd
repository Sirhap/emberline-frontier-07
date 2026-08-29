extends SceneTree

## Real sell QA: place → select → HUD sell label → sell → scrap/refund assert + shots.
const OUT := "/workspace/emberline-qa/sell"
const PAD := Vector2(648.0, 336.0)

var _failures: Array[String] = []


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
	hero.position = PAD + Vector2(-80.0, 40.0)

	# --- 1) pulse L1 sell = 48 ---
	scene.set("scrap", 300)
	var pulse: EmberTower = scene.call("_spawn_tower_at", PAD, &"pulse", 1)
	await _settle(cam, PAD + Vector2(0.0, -20.0))
	_expect(pulse.sell_value() == 48, "pulse L1 sell_value=48 got=%d" % pulse.sell_value())
	_expect_hud_sell(scene, 48)
	await _save("01-pulse-selected")
	var scrap0: int = int(scene.get("scrap"))
	scene.call("sell_selected_tower")
	await process_frame
	await process_frame
	_expect((scene.get("_towers") as Array).is_empty(), "pulse pad empty after sell")
	_expect(int(scene.get("scrap")) == scrap0 + 48, "pulse refund +48 scrap %d->%d" % [scrap0, int(scene.get("scrap"))])
	_expect_status_contains(scene, "已出售")
	await _settle(cam, PAD + Vector2(0.0, -20.0))
	await _save("02-pulse-sold")
	print("CASE pulse ok scrap=%d" % int(scene.get("scrap")))

	# --- 2) upgraded pulse still refunds base 48 (no upgrade fee back) ---
	scene.set("scrap", 500)
	pulse = scene.call("_spawn_tower_at", PAD, &"pulse", 1)
	scene.call("upgrade_selected_tower")
	scene.call("upgrade_selected_tower")
	_expect(pulse.level == 3, "pulse should be L3 after 2 upgrades got=%d" % pulse.level)
	_expect(pulse.sell_value() == 48, "upgraded pulse still sell 48 got=%d" % pulse.sell_value())
	_expect_hud_sell(scene, 48)
	await _settle(cam, PAD + Vector2(0.0, -20.0))
	await _save("03-pulse-l3-selected")
	scrap0 = int(scene.get("scrap"))
	scene.call("sell_selected_tower")
	await process_frame
	_expect(int(scene.get("scrap")) == scrap0 + 48, "L3 pulse refund still +48")
	await _settle(cam, PAD + Vector2(0.0, -20.0))
	await _save("04-pulse-l3-sold")
	print("CASE pulse-l3 ok")

	# --- 3) facilities ---
	var cases: Array = [
		[&"barrier", 60, 36],
		[&"amplifier", 100, 60],
		[&"pulse_clear", 120, 72],
		[&"energy_orb", 90, 54],
		[&"burst", 110, 66],
		[&"frost", 90, 54],
	]
	var shot_i := 5
	for row: Array in cases:
		var kind: StringName = row[0]
		var cost: int = row[1]
		var expect_refund: int = row[2]
		_expect(EmberTower.build_cost(kind) == cost, "%s build_cost=%d got=%d" % [kind, cost, EmberTower.build_cost(kind)])
		_expect(EmberTower.sell_refund(kind) == expect_refund, "%s sell_refund=%d got=%d" % [kind, expect_refund, EmberTower.sell_refund(kind)])
		scene.set("scrap", 800)
		var t: EmberTower = scene.call("_spawn_tower_at", PAD, kind, 1)
		_expect(t.sell_value() == expect_refund, "%s sell_value=%d got=%d" % [kind, expect_refund, t.sell_value()])
		_expect_hud_sell(scene, expect_refund)
		await _settle(cam, PAD + Vector2(0.0, -20.0))
		await _save("%02d-%s-selected" % [shot_i, String(kind)])
		shot_i += 1
		scrap0 = int(scene.get("scrap"))
		scene.call("sell_selected_tower")
		await process_frame
		_expect((scene.get("_towers") as Array).is_empty(), "%s emptied" % kind)
		_expect(int(scene.get("scrap")) == scrap0 + expect_refund, "%s scrap refund" % kind)
		await _settle(cam, PAD + Vector2(0.0, -20.0))
		await _save("%02d-%s-sold" % [shot_i, String(kind)])
		shot_i += 1
		print("CASE %s ok refund=%d" % [kind, expect_refund])

	# --- 4) weapon-mounted pad: sell_value from place_cost ---
	scene.set("scrap", 400)
	var mounted: EmberTower = scene.call("_spawn_tower_at", PAD, &"pulse", 1, &"pistol")
	var expected_mount := int(floor(float(maxi(mounted.place_cost, 1)) * 0.60))
	_expect(mounted.weapon_id == &"pistol", "mounted weapon_id pistol")
	_expect(mounted.sell_value() == expected_mount, "mounted sell=%d got=%d place=%d" % [expected_mount, mounted.sell_value(), mounted.place_cost])
	_expect_hud_sell(scene, expected_mount)
	await _settle(cam, PAD + Vector2(0.0, -20.0))
	await _save("%02d-pistol-mount-selected" % shot_i)
	shot_i += 1
	scrap0 = int(scene.get("scrap"))
	scene.call("sell_selected_tower")
	await process_frame
	_expect(int(scene.get("scrap")) == scrap0 + expected_mount, "mounted refund")
	await _settle(cam, PAD + Vector2(0.0, -20.0))
	await _save("%02d-pistol-mount-sold" % shot_i)
	print("CASE pistol-mount ok refund=%d place_cost=%d" % [expected_mount, mounted.place_cost if is_instance_valid(mounted) else -1])

	# --- 5) sell with no selection ---
	scene.call("_select_tower", null)
	scrap0 = int(scene.get("scrap"))
	scene.call("sell_selected_tower")
	_expect(int(scene.get("scrap")) == scrap0, "no-selection sell must not change scrap")
	_expect_status_contains(scene, "请先选中")

	# --- 6) HUD button path (emit sell_pressed like player click) ---
	scene.set("scrap", 300)
	pulse = scene.call("_spawn_tower_at", PAD, &"pulse", 1)
	await _settle(cam, PAD + Vector2(0.0, -20.0))
	await _save("%02d-hud-before-click" % (shot_i))
	shot_i += 1
	scrap0 = int(scene.get("scrap"))
	var hud: Node = scene.get("_hud")
	hud.emit_signal("sell_pressed")
	await process_frame
	await process_frame
	_expect((scene.get("_towers") as Array).is_empty(), "HUD sell_pressed empties pad")
	_expect(int(scene.get("scrap")) == scrap0 + 48, "HUD sell_pressed +48")
	await _settle(cam, PAD + Vector2(0.0, -20.0))
	await _save("%02d-hud-after-click" % shot_i)
	print("CASE hud-button ok")

	if _failures.is_empty():
		print("SELL_QA_PASS cases=ok shots_dir=%s" % OUT)
		quit(0)
	else:
		for f: String in _failures:
			printerr("SELL_FAIL %s" % f)
		print("SELL_QA_FAIL count=%d" % _failures.size())
		quit(1)


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_failures.append(msg)
		printerr("EXPECT_FAIL %s" % msg)


func _expect_hud_sell(scene: Node, refund: int) -> void:
	var hud: Node = scene.get("_hud")
	if hud == null:
		_expect(false, "hud missing")
		return
	var btn: Button = hud.get("sell_button")
	if btn == null:
		_expect(false, "sell_button missing")
		return
	_expect(not btn.disabled, "sell_button should be enabled")
	_expect(btn.text == "出售 %d" % refund, "sell_button text want=出售 %d got=%s" % [refund, btn.text])


func _expect_status_contains(scene: Node, needle: String) -> void:
	var hud: Node = scene.get("_hud")
	var status: Label = hud.get("status_label") if hud != null else null
	var text := status.text if status != null else ""
	_expect(text.find(needle) >= 0, "status contains '%s' got='%s'" % [needle, text])


func _lock_cam(cam: Camera2D, at: Vector2, zoom: float) -> void:
	if cam == null:
		return
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(zoom, zoom)
	cam.global_position = at
	cam.reset_smoothing()
	cam.force_update_scroll()


func _settle(cam: Camera2D, at: Vector2) -> void:
	_lock_cam(cam, at, 1.55)
	await process_frame
	await process_frame
	_lock_cam(cam, at, 1.55)
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUT, name]
	var tex := root.get_viewport().get_texture()
	if tex == null:
		printerr("no viewport tex for %s" % name)
		return
	var img: Image = tex.get_image()
	img.save_png(path)
	print("SHOT %s" % path)

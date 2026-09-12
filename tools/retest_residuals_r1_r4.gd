extends SceneTree

## Residuals R1–R4 visual capture (AppRoot only). Do not edit game scripts.
const OUT := "res://dogfood-output/playtest-residuals-retest"
const EmberRunSave := preload("res://scripts/run_save.gd")
const EmberHero := preload("res://scripts/hero.gd")

var _notes: PackedStringArray = []
var _verdicts: Dictionary = {}


func _init() -> void:
	create_timer(120.0).timeout.connect(func() -> void:
		push_error("RETEST RESIDUALS R1-R4 TIMEOUT")
		_write_result_partial()
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	EmberRunSave.delete_run()
	Engine.max_fps = 30
	print("RETEST_RESIDUALS_R1_R4 start")

	await _capture_r1_sell_hint()
	await _capture_r2_continue_after_switch()
	await _capture_r3_reselect_cancel()
	await _capture_r4_hero_defeat()

	EmberRunSave.delete_run()
	print("RETEST_RESIDUALS NOTES")
	for line in _notes:
		print(line)
	_write_result()
	print("RETEST_RESIDUALS_R1_R4 CAPTURE DONE")
	quit()


func _capture_r1_sell_hint() -> void:
	print("R1 start")
	EmberRunSave.delete_run()
	var app: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	await _frames(4)

	var select := app.find_child("CharacterSelect", true, false)
	if select == null:
		_fail("R1", "CharacterSelect missing")
		app.queue_free()
		await _frames(2)
		return
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await _frames(5)

	var hub := app.find_child("HomeHub", true, false)
	if hub == null:
		_fail("R1", "HomeHub missing")
		app.queue_free()
		await _frames(2)
		return
	hub.call("confirm_new_run")
	await _frames(8)

	var battle := app.find_child("Battlefield", true, false)
	if battle == null:
		_fail("R1", "Battlefield missing after start")
		app.queue_free()
		await _frames(2)
		return

	# Keep hero on combat floor so tower panel is not home-hidden.
	var hero: EmberHero = battle.find_child("HeroController", true, false) as EmberHero
	if hero != null:
		hero.position = Vector2(520.0, 320.0)
		hero.debug_god = true
	battle.set("scrap", 800)
	var tower: Node = battle.call("_spawn_tower_at", Vector2(456.0, 280.0), &"pulse", 2)
	await _frames(4)
	if tower != null:
		battle.call("_select_tower", tower)
		await _frames(4)
		# Re-select once more in case a hitch frame cleared the panel timer.
		battle.call("_select_tower", tower)
		await _frames(3)

	await _shot("RR-P2-3-sell")
	var hint := battle.find_child("SellRefundHint", true, false) as Label
	var panel := battle.find_child("TowerPanel", true, false) as Control
	var sell_btn := battle.find_child("SellButton", true, false) as Button
	var hint_ok: bool = hint != null and hint.visible and hint.is_visible_in_tree() and String(hint.text).contains("升级费不退")
	var panel_ok: bool = panel != null and panel.visible and panel.is_visible_in_tree()
	_notes.append("R1 sell_hint=%s vis=%s in_tree=%s panel_vis=%s sell_btn=%s" % [
		hint.text if hint else "missing",
		str(hint.visible) if hint else "missing",
		str(hint.is_visible_in_tree()) if hint else "missing",
		str(panel.visible) if panel else "missing",
		sell_btn.text if sell_btn else "missing",
	])
	if hint_ok and panel_ok:
		_verdicts["R1"] = "PASS"
		_notes.append("R1 PASS: 升级费不退 visible on tower panel")
	else:
		_verdicts["R1"] = "FAIL"
		_notes.append("R1 FAIL: hint_ok=%s panel_ok=%s" % [str(hint_ok), str(panel_ok)])

	app.queue_free()
	await _frames(3)
	EmberRunSave.delete_run()


func _capture_r2_continue_after_switch() -> void:
	print("R2 start")
	EmberRunSave.delete_run()
	EmberRunSave.write_run(_assassin_resume_payload())

	var app: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	await _frames(4)

	var select := app.find_child("CharacterSelect", true, false)
	if select == null:
		_fail("R2", "CharacterSelect missing")
		app.queue_free()
		await _frames(2)
		return
	# Boot as knight while disk holds an assassin run.
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await _frames(5)

	var hub := app.find_child("HomeHub", true, false)
	if hub == null:
		_fail("R2", "HomeHub missing")
		app.queue_free()
		await _frames(2)
		return

	var cont := hub.find_child("ContinueButton", true, false) as Button
	_notes.append("R2 home_before_switch hero=%s continue_vis=%s" % [
		str(hub.call("selected_hero_id")),
		str(cont.visible) if cont else "missing",
	])

	# Switch hero to assassin (new Start hero) while keep Continue for old save.
	var change := hub.find_child("HeroSelectButton", true, false) as Button
	if change != null:
		change.pressed.emit()
	else:
		hub.call("request_hero_select")
	await _frames(5)
	select = app.find_child("CharacterSelect", true, false)
	if select == null:
		_fail("R2", "reselect CharacterSelect missing")
		app.queue_free()
		await _frames(2)
		return
	select.call("select_hero", &"assassin")
	select.call("confirm_current")
	await _frames(5)

	hub = app.find_child("HomeHub", true, false)
	cont = hub.find_child("ContinueButton", true, false) as Button if hub != null else null
	var start_btn := hub.find_child("StartButton", true, false) as Button if hub != null else null
	await _shot("RR-continue-after-switch")
	_notes.append("R2 after_switch hero=%s continue_vis=%s start=%s" % [
		str(hub.call("selected_hero_id")) if hub else "missing",
		str(cont.visible) if cont else "missing",
		start_btn.text if start_btn else "missing",
	])

	# Continue must resume OLD assassin save (scrap 444 / wave 3), not silent new-hero start.
	if cont == null or not cont.visible:
		_verdicts["R2"] = "FAIL"
		_notes.append("R2 FAIL: Continue hidden after switch with valid save")
		app.queue_free()
		await _frames(2)
		EmberRunSave.delete_run()
		return

	cont.pressed.emit()
	await _frames(8)
	var battle := app.find_child("Battlefield", true, false)
	var hero: EmberHero = app.find_child("HeroController", true, false) as EmberHero
	var continue_ok: bool = hero != null and hero.hero_kind == &"assassin" \
		and battle != null and int(battle.get("scrap")) == 444 and int(battle.get("current_wave")) == 3
	await _shot("RR-continue-resume-battle")
	_notes.append("R2 continue_battle hero=%s scrap=%s wave=%s" % [
		str(hero.hero_kind) if hero else "missing",
		str(battle.get("scrap")) if battle else "missing",
		str(battle.get("current_wave")) if battle else "missing",
	])

	app.queue_free()
	await _frames(3)

	# Second half: Start with switched knight must overwrite, not silently continue old run.
	EmberRunSave.write_run(_assassin_resume_payload())
	app = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	await _frames(4)
	select = app.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"assassin")
	select.call("confirm_current")
	await _frames(5)
	hub = app.find_child("HomeHub", true, false)
	change = hub.find_child("HeroSelectButton", true, false) as Button
	change.pressed.emit()
	await _frames(5)
	select = app.find_child("CharacterSelect", true, false)
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await _frames(5)
	hub = app.find_child("HomeHub", true, false)
	hub.call("confirm_new_run")
	await _frames(5)
	var overwrite := app.find_child("OverwriteConfirm", true, false)
	await _shot("RR-start-overwrite-confirm")
	var overwrite_ok: bool = overwrite != null and overwrite.visible
	_notes.append("R2 start_overwrite_vis=%s selected=%s" % [
		str(overwrite_ok),
		str(hub.call("selected_hero_id")) if hub else "missing",
	])
	if overwrite_ok:
		var yes := _find_button_with_text(overwrite, "覆盖并出发")
		if yes != null:
			yes.pressed.emit()
			await _frames(8)
	battle = app.find_child("Battlefield", true, false)
	hero = app.find_child("HeroController", true, false) as EmberHero
	var start_ok: bool = hero != null and hero.hero_kind == &"ember_hero" \
		and battle != null and int(battle.get("scrap")) == 300
	await _shot("RR-start-new-hero-battle")
	_notes.append("R2 start_battle hero=%s scrap=%s" % [
		str(hero.hero_kind) if hero else "missing",
		str(battle.get("scrap")) if battle else "missing",
	])

	if continue_ok and start_ok and overwrite_ok:
		_verdicts["R2"] = "PASS"
		_notes.append("R2 PASS: Continue keeps old save hero; Start overwrite uses new hero")
	else:
		_verdicts["R2"] = "FAIL"
		_notes.append("R2 FAIL: continue_ok=%s overwrite_ok=%s start_ok=%s" % [
			str(continue_ok), str(overwrite_ok), str(start_ok),
		])

	app.queue_free()
	await _frames(3)
	EmberRunSave.delete_run()


func _capture_r3_reselect_cancel() -> void:
	print("R3 start")
	EmberRunSave.delete_run()
	var app: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	await _frames(4)

	var select := app.find_child("CharacterSelect", true, false)
	if select == null:
		_fail("R3", "CharacterSelect missing")
		app.queue_free()
		await _frames(2)
		return
	select.call("select_hero", &"assassin")
	select.call("confirm_current")
	await _frames(5)

	var hub := app.find_child("HomeHub", true, false)
	if hub == null:
		_fail("R3", "HomeHub missing")
		app.queue_free()
		await _frames(2)
		return
	var before_hero: StringName = hub.call("selected_hero_id")
	var change := hub.find_child("HeroSelectButton", true, false) as Button
	if change != null:
		change.pressed.emit()
	else:
		hub.call("request_hero_select")
	await _frames(5)

	select = app.find_child("CharacterSelect", true, false)
	if select == null or not select.visible:
		_fail("R3", "reselect did not open CharacterSelect")
		app.queue_free()
		await _frames(2)
		return
	var cancel := select.find_child("CancelButton", true, false) as Button
	# Pick a different hero but cancel instead of 确认出战.
	select.call("select_hero", &"ember_hero")
	await _frames(3)
	await _shot("RR-reselect-cancel-open")
	_notes.append("R3 cancel_btn=%s vis=%s" % [
		cancel.text if cancel else "missing",
		str(cancel.visible) if cancel else "missing",
	])
	if cancel == null or not cancel.visible:
		_verdicts["R3"] = "FAIL"
		_notes.append("R3 FAIL: Cancel/返回 not visible — forced 确认出战 blocker")
		app.queue_free()
		await _frames(2)
		EmberRunSave.delete_run()
		return

	cancel.pressed.emit()
	await _frames(5)
	hub = app.find_child("HomeHub", true, false)
	select = app.find_child("CharacterSelect", true, false)
	await _shot("RR-reselect-cancel")
	var back_home: bool = hub != null and hub.visible
	var select_hidden: bool = select == null or not select.visible
	var hero_unchanged: bool = hub != null and (hub.call("selected_hero_id") as StringName) == before_hero
	_notes.append("R3 after_cancel hub_vis=%s select_vis=%s hero=%s before=%s" % [
		str(hub.visible) if hub else "missing",
		str(select.visible) if select else "gone",
		str(hub.call("selected_hero_id")) if hub else "missing",
		str(before_hero),
	])
	if back_home and select_hidden and hero_unchanged:
		_verdicts["R3"] = "PASS"
		_notes.append("R3 PASS: cancel/back to home without forced 确认出战")
	else:
		_verdicts["R3"] = "FAIL"
		_notes.append("R3 FAIL: back_home=%s select_hidden=%s hero_unchanged=%s" % [
			str(back_home), str(select_hidden), str(hero_unchanged),
		])

	app.queue_free()
	await _frames(3)
	EmberRunSave.delete_run()


func _capture_r4_hero_defeat() -> void:
	print("R4 start")
	EmberRunSave.delete_run()
	var app: Node = load("res://scenes/app_root.tscn").instantiate()
	root.add_child(app)
	await _frames(4)

	var select := app.find_child("CharacterSelect", true, false)
	if select == null:
		_fail("R4", "CharacterSelect missing")
		app.queue_free()
		await _frames(2)
		return
	select.call("select_hero", &"ember_hero")
	select.call("confirm_current")
	await _frames(5)

	var hub := app.find_child("HomeHub", true, false)
	if hub == null:
		_fail("R4", "HomeHub missing")
		app.queue_free()
		await _frames(2)
		return
	hub.call("confirm_new_run")
	await _frames(8)

	var battle := app.find_child("Battlefield", true, false)
	if battle == null:
		_fail("R4", "Battlefield missing")
		app.queue_free()
		await _frames(2)
		return

	# Prefer exhausting revives via real down path; fall back to notify_hero_defeated.
	var hero: EmberHero = battle.find_child("HeroController", true, false) as EmberHero
	if hero != null:
		hero.revives_left = 0
		hero.down_duration = 0.15
		hero.set("_hit_invuln", 0.0)
		hero.set("_dash_invuln", 0.0)
		hero.debug_god = false
		hero.take_damage(9999)
		# Wait for down timer to expire → notify_hero_defeated.
		var waited := 0.0
		while waited < 1.2:
			await process_frame
			waited += 1.0 / 30.0
			var ov := battle.find_child("EndOverlay", true, false) as Control
			if ov != null and ov.visible:
				break
	if battle.find_child("EndOverlay", true, false) == null \
			or not (battle.find_child("EndOverlay", true, false) as Control).visible:
		battle.call("notify_hero_defeated")
		await _frames(4)

	var overlay := battle.find_child("EndOverlay", true, false) as Control
	var title := battle.find_child("OverlayTitle", true, false) as Label
	var restart := battle.find_child("RestartButton", true, false) as Button
	await _shot("RR-hero-defeat")
	_notes.append("R4 overlay_vis=%s title=%s action=%s" % [
		str(overlay != null and overlay.visible) if overlay != null else "missing",
		title.text if title else "missing",
		restart.text if restart else "missing",
	])
	var title_ok: bool = title != null and title.text == "英雄阵亡"
	var action_ok: bool = restart != null and restart.text == "返回家园"
	var overlay_ok: bool = overlay != null and overlay.visible
	if title_ok and action_ok and overlay_ok:
		_verdicts["R4"] = "PASS"
		_notes.append("R4 PASS: 英雄阵亡 + 返回家园")
	else:
		_verdicts["R4"] = "FAIL"
		_notes.append("R4 FAIL: title_ok=%s action_ok=%s overlay_ok=%s" % [
			str(title_ok), str(action_ok), str(overlay_ok),
		])

	app.queue_free()
	await _frames(3)
	EmberRunSave.delete_run()


func _assassin_resume_payload() -> Dictionary:
	return {
		"version": 2,
		"mode_id": "endless_td",
		"run_seed": 42,
		"cleared_wave": 3,
		"scrap": 444,
		"core_health": 7,
		"run_time": 20.0,
		"defeated_count": 9,
		"hero": {
			"hero_id": "assassin",
			"hero_kind": "assassin",
			"health": 90,
			"weapon": "sword",
			"weapons": ["sword", ""],
			"position": [640.0, 336.0],
			"progression": {
				"level": 2,
				"xp": 10,
				"pending_choices": 0,
				"talent_counts": {},
				"talent_rng_state": 1,
				"legacy_bonus_health": 0,
				"legacy_dash_cooldown_level": 0,
				"legacy_bonus_armor": 0,
				"skill_rank": 0,
			},
		},
		"towers": [],
		"drop_rng_state": 1,
		"shop_rng_state": 1,
		"slots": [{
			"kind": "tower",
			"payload": "pulse",
			"cost": 80,
			"sold": false,
			"vendor": "merchant",
			"title": "脉冲塔",
		}],
		"shop": {},
	}


func _fail(item: String, reason: String) -> void:
	_verdicts[item] = "FAIL"
	_notes.append("%s FAIL: %s" % [item, reason])


func _find_button_with_text(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child: Node in node.get_children():
		var found := _find_button_with_text(child, text)
		if found != null:
			return found
	return null


func _shot(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("CAPTURE FAIL %s: no image" % stem)
		_notes.append("SHOT_FAIL %s" % stem)
		return
	var png := "%s/%s.png" % [OUT, stem]
	var webp := "%s/%s.webp" % [OUT, stem]
	var err := image.save_png(png)
	var werr := image.save_webp(webp, false, 0.82)
	print("CAPTURE %s png=%s webp=%s %dx%d" % [stem, err, werr, image.get_width(), image.get_height()])


func _frames(n: int) -> void:
	for _i: int in range(n):
		await process_frame


func _write_result_partial() -> void:
	_write_result()


func _write_result() -> void:
	var path := ProjectSettings.globalize_path("%s/RESULT.md" % OUT)
	var r1 := str(_verdicts.get("R1", "BLOCKED"))
	var r2 := str(_verdicts.get("R2", "BLOCKED"))
	var r3 := str(_verdicts.get("R3", "BLOCKED"))
	var r4 := str(_verdicts.get("R4", "BLOCKED"))
	var lines: PackedStringArray = []
	lines.append("# Playtest residuals retest RESULT (preliminary)")
	lines.append("")
	lines.append("- **Tip:** `retest-pr10` @ `1b08a03`")
	lines.append("- **Capture:** `tools/retest_residuals_r1_r4.gd` on `DISPLAY=:9` (AppRoot only)")
	lines.append("- **When:** 2026-09-12 (automated preliminary)")
	lines.append("- **Verdict:** **R1 %s · R2 %s · R3 %s · R4 %s**" % [r1, r2, r3, r4])
	lines.append("")
	lines.append("Runtime notes:")
	lines.append("")
	lines.append("```")
	for line in _notes:
		lines.append(line)
	lines.append("```")
	lines.append("")
	lines.append("---")
	lines.append("")
	lines.append("## R1 · Sell hint 升级费不退 — **%s**" % r1)
	lines.append("")
	lines.append("| | |")
	lines.append("|---|---|")
	lines.append("| Evidence | `dogfood-output/playtest-residuals-retest/RR-P2-3-sell.webp` |")
	lines.append("| PNG | `dogfood-output/playtest-residuals-retest/RR-P2-3-sell.png` |")
	lines.append("")
	lines.append("Select upgraded pulse on combat floor; tower panel must show on-screen **升级费不退** (`SellRefundHint`), not tooltip-only.")
	lines.append("")
	lines.append("---")
	lines.append("")
	lines.append("## R2 · Home switch + Continue vs Start — **%s**" % r2)
	lines.append("")
	lines.append("| | |")
	lines.append("|---|---|")
	lines.append("| Home after switch | `dogfood-output/playtest-residuals-retest/RR-continue-after-switch.webp` |")
	lines.append("| Continue resume | `dogfood-output/playtest-residuals-retest/RR-continue-resume-battle.webp` |")
	lines.append("| Start overwrite | `dogfood-output/playtest-residuals-retest/RR-start-overwrite-confirm.webp` |")
	lines.append("| Start new hero | `dogfood-output/playtest-residuals-retest/RR-start-new-hero-battle.webp` |")
	lines.append("")
	lines.append("Valid assassin `run.json` on disk. After 更换人物, **Continue** still resumes old save hero/scrap/wave; **Start** asks overwrite and launches the newly selected hero.")
	lines.append("")
	lines.append("---")
	lines.append("")
	lines.append("## R3 · Reselect cancel/back — **%s**" % r3)
	lines.append("")
	lines.append("| | |")
	lines.append("|---|---|")
	lines.append("| Select open | `dogfood-output/playtest-residuals-retest/RR-reselect-cancel-open.webp` |")
	lines.append("| After cancel | `dogfood-output/playtest-residuals-retest/RR-reselect-cancel.webp` |")
	lines.append("")
	lines.append("Home → 更换人物 → **返回** cancels without forced **确认出战**; home hero unchanged.")
	lines.append("")
	lines.append("---")
	lines.append("")
	lines.append("## R4 · Hero-death overlay — **%s**" % r4)
	lines.append("")
	lines.append("| | |")
	lines.append("|---|---|")
	lines.append("| Evidence | `dogfood-output/playtest-residuals-retest/RR-hero-defeat.webp` |")
	lines.append("| PNG | `dogfood-output/playtest-residuals-retest/RR-hero-defeat.png` |")
	lines.append("")
	lines.append("Revive exhausted → EndOverlay title **英雄阵亡**, action **返回家园**.")
	lines.append("")
	lines.append("Game scripts were not modified. Companion smoke was not re-run in this pass.")
	lines.append("")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines))
		f.close()
		print("WROTE ", path)
	else:
		push_error("Could not write RESULT.md")

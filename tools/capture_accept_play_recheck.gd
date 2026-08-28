extends SceneTree

var _attack_origins: Array[Vector2] = []
var _ranged_origins: Array[Vector2] = []
var _seq_clips: Array[String] = []
var _seq_frames: Array[int] = []
var _seq_states: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	Engine.max_fps = 60
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	if cam != null:
		cam.position_smoothing_enabled = false
	hero.attacked.connect(_on_attacked)
	hero.ranged_fired.connect(_on_ranged)

	# --- assassin + sword: idle then attack ---
	_reset_emits()
	hero.apply_hero_kind(&"assassin")
	hero.skill_levels[&"assassin"] = 0
	_set_loadout(hero, &"sword")
	hero.position = Vector2(640.0, 336.0)
	_pose(hero)
	await _settle(scene, hero, cam, 2.2)
	_seq_clips.clear()
	_seq_frames.clear()
	_seq_states.clear()
	for i: int in range(4):
		await _capture_named(scene, hero, cam, "assassin-idle-%02d" % i, 2.2)
	hero.set("_attack_cooldown", 0.0)
	hero.request_attack()
	_seq_clips.clear()
	_seq_frames.clear()
	_seq_states.clear()
	for i: int in range(28):
		await _capture_named(scene, hero, cam, "assassin-atk-%02d" % i, 2.2)
	_print_emits("assassin-sword")
	_print_idle_pop("assassin-atk")
	_print_assassin_sword_clip(hero)

	# --- assassin + pistol ---
	_reset_emits()
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.equip_weapon(&"pistol")
	_pose(hero)
	await _settle(scene, hero, cam, 2.2)
	hero.set("_attack_cooldown", 0.0)
	hero.request_attack()
	_seq_clips.clear()
	_seq_frames.clear()
	_seq_states.clear()
	for i: int in range(16):
		await _capture_named(scene, hero, cam, "assassin-pistol-%02d" % i, 2.2)
	_print_emits("assassin-pistol")
	_print_idle_pop("assassin-pistol")

	# --- knight + sword skill 0 ---
	_reset_emits()
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.apply_hero_kind(&"ember_hero")
	hero.skill_levels[&"ember_hero"] = 0
	_set_loadout(hero, &"sword")
	hero.position = Vector2(640.0, 336.0)
	_pose(hero)
	await _settle(scene, hero, cam, 2.2)
	hero.set("_attack_cooldown", 0.0)
	hero.request_attack()
	_seq_clips.clear()
	_seq_frames.clear()
	_seq_states.clear()
	for i: int in range(20):
		await _capture_named(scene, hero, cam, "knight-atk-%02d" % i, 2.2)
	_print_emits("knight-sword-s0")
	_print_idle_pop("knight-atk")
	_print_knight_body("knight-atk", hero)

	# --- knight + sword skill 2 (3 floats) ---
	_reset_emits()
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.skill_levels[&"ember_hero"] = 2
	_set_loadout(hero, &"sword")
	_pose(hero)
	await _settle(scene, hero, cam, 2.2)
	print("KNIGHT_TRIPLE setup floats=%d origins=%d skill=%s" % [
		hero.floating_weapon_count(),
		hero.combat_float_origins().size(),
		hero.skill_levels,
	])
	hero.set("_attack_cooldown", 0.0)
	hero.request_attack()
	_seq_clips.clear()
	_seq_frames.clear()
	_seq_states.clear()
	for i: int in range(20):
		await _capture_named(scene, hero, cam, "knight-triple-atk-%02d" % i, 2.2)
	_print_emits("knight-sword-s2")
	_print_idle_pop("knight-triple-atk")
	_print_knight_body("knight-triple-atk", hero)

	# --- shop hall ---
	if float(hero.get("_attack_elapsed")) >= 0.0:
		hero.call("_finish_combo")
	hero.skill_levels[&"ember_hero"] = 0
	_set_loadout(hero, &"sword")
	scene.set("_talking_npc", &"")
	scene.call("_refresh_shop_ui")
	hero.position = Vector2(540.0, -70.0)
	_pose(hero)
	var shop_zoom := 1.22
	if scene.has_method("camera_zoom_for"):
		shop_zoom = (scene.call("camera_zoom_for", hero.position) as Vector2).x
	await _settle(scene, hero, cam, shop_zoom)
	await _save("shop-hall")
	_print_frame("shop-hall", hero)
	var shop_panel := scene.find_child("ShopPanel", true, false) as Control
	print("SHOP_HALL panel=%s talking=%s pos=%s" % [
		shop_panel.visible if shop_panel else false,
		scene.get("_talking_npc"),
		hero.position,
	])

	# --- HUD Chinese labels ---
	hero.position = Vector2(640.0, 336.0)
	_pose(hero)
	var hud: Node = scene.get("_hud")
	if hud != null:
		hud.call("update_status", "废料不足，先守住核心")
		hud.call("update_stats", int(scene.get("scrap")), int(scene.get("core_health")), int(scene.get("current_wave")))
		hud.call("set_wave_button_enabled", true, "提前开战")
		hud.call("set_shop_countdown", 88.0)
		hud.call("poke_action_cluster")
	await _settle(scene, hero, cam, 1.0)
	await _save("hud-zh")
	_print_frame("hud-zh", hero)
	_print_hud_zh(scene)

	print("ACCEPT_PLAY_CAPTURE ok")
	quit()


func _on_attacked(origin: Vector2, _facing: int) -> void:
	_attack_origins.append(origin)
	print("EMIT attacked n=%d origin=%s" % [_attack_origins.size(), origin])


func _on_ranged(origin: Vector2, aim_dir: Vector2, weapon_id: StringName) -> void:
	_ranged_origins.append(origin)
	print("EMIT ranged_fired n=%d origin=%s aim=%s weapon=%s" % [_ranged_origins.size(), origin, aim_dir, String(weapon_id)])


func _reset_emits() -> void:
	_attack_origins.clear()
	_ranged_origins.clear()


func _set_loadout(hero: EmberHero, weapon_id: StringName) -> void:
	hero.weapon_slots = [weapon_id, &""]
	hero.weapon_slot_index = 0
	hero.current_weapon = weapon_id
	hero.turret_hand = false
	hero.call("_refresh_held_weapon")


func _print_emits(tag: String) -> void:
	var atk_parts: Array[String] = []
	for origin: Vector2 in _attack_origins:
		atk_parts.append(str(origin))
	var rng_parts: Array[String] = []
	for origin: Vector2 in _ranged_origins:
		rng_parts.append(str(origin))
	print("SEQ_EMIT %s attacked=%d origins=[%s] ranged=%d origins=[%s]" % [
		tag,
		_attack_origins.size(),
		", ".join(atk_parts),
		_ranged_origins.size(),
		", ".join(rng_parts),
	])


func _print_idle_pop(tag: String) -> void:
	var first_n := mini(3, _seq_clips.size())
	var idle_like := false
	var details: Array[String] = []
	var saw_attack := false
	for i: int in range(first_n):
		var clip := _seq_clips[i]
		var frame_i := _seq_frames[i]
		var state := _seq_states[i]
		var looks_idle := clip == "idle" or clip == "待机" or state == "idle"
		if clip == "attack" or clip == "attack_b":
			saw_attack = true
		if looks_idle and not saw_attack:
			idle_like = true
		details.append("%d clip=%s frame=%d state=%s" % [i, clip, frame_i, state])
	var verdict := "FAIL" if idle_like else "OK"
	print("IDLE_POP %s %s first3=[%s] (idle clip/frames before attack starts = FAIL)" % [
		tag, verdict, " | ".join(details),
	])


func _print_assassin_sword_clip(hero: EmberHero) -> void:
	var became := false
	var stayed := true
	var saw_attack := false
	var clip_run: Array[String] = []
	for clip: String in _seq_clips:
		clip_run.append(clip)
		if clip == "attack" or clip == "attack_b":
			became = true
			saw_attack = true
		elif saw_attack and clip != "attack" and clip != "attack_b":
			stayed = false
	if not became:
		stayed = false
	var float_on_body := _float_visible_count(hero) > 0
	print("ASSASSIN_SWORD clip_became_attack=%s stayed_on_attack=%s float_visible_on_body=%s clips=[%s] %s" % [
		became,
		stayed,
		float_on_body,
		", ".join(clip_run),
		_weapon_slot_dump(hero),
	])


func _print_knight_body(tag: String, hero: EmberHero) -> void:
	var attack_frames := 0
	var idle_after_start := 0
	var saw_attack := false
	for i: int in range(_seq_clips.size()):
		var clip := _seq_clips[i]
		if clip == "attack" or clip == "attack_b":
			saw_attack = true
			attack_frames += 1
		elif saw_attack and (clip == "idle" or _seq_states[i] == "idle"):
			idle_after_start += 1
	print("KNIGHT_BODY %s attack_clip_frames=%d idle_after_attack_started=%d floats=%d origins=%d %s" % [
		tag,
		attack_frames,
		idle_after_start,
		_float_visible_count(hero),
		hero.combat_float_origins().size(),
		_weapon_slot_dump(hero),
	])


func _print_hud_zh(scene: Node) -> void:
	var names: Array[String] = [
		"StatusLabel", "PrepCountdown", "WaveLabel", "ResourcesLabel", "BaseLabel",
		"StartWaveButton", "AttackButton", "JumpButton", "SkillButton", "TalkButton",
		"HeroStatusLabel", "LoadoutLabel", "TowerNameLabel", "TowerInfoLabel",
	]
	var parts: Array[String] = []
	for name: String in names:
		var node := scene.find_child(name, true, false)
		if node == null:
			continue
		var text := ""
		if node.get("text") != null:
			text = str(node.get("text"))
		parts.append("%s='%s' vis=%s" % [name, text, node.visible if node is CanvasItem else "?"])
	print("HUD_ZH %s" % " | ".join(parts))
	var hud: Node = scene.get("_hud")
	if hud == null:
		return
	for prop: String in ["wave_label", "resources_label", "base_label", "prep_label", "start_button", "attack_button", "status_label", "hero_status_label"]:
		var ctrl: Variant = hud.get(prop)
		if ctrl == null:
			continue
		var text2 := ""
		if ctrl.get("text") != null:
			text2 = str(ctrl.get("text"))
		print("HUD_PROP %s text='%s' vis=%s" % [prop, text2, ctrl.visible if ctrl is CanvasItem else "?"])


func _capture_named(scene: Node, hero: EmberHero, cam: Camera2D, shot_name: String, zoom: float) -> void:
	_pose(hero)
	_aim_camera(scene, hero, cam, zoom)
	await _save(shot_name)
	var info := _print_frame(shot_name, hero)
	_seq_clips.append(str(info.get("clip", "")))
	_seq_frames.append(int(info.get("frame", -1)))
	_seq_states.append(str(info.get("state", "")))
	await process_frame


func _settle(scene: Node, hero: EmberHero, cam: Camera2D, zoom: float) -> void:
	_pose(hero)
	_aim_camera(scene, hero, cam, zoom)
	await process_frame
	await process_frame
	_aim_camera(scene, hero, cam, zoom)
	await RenderingServer.frame_post_draw


func _print_frame(shot_name: String, hero: EmberHero) -> Dictionary:
	var actor: Node = hero.get("_xsxb_actor")
	var frame_animation := ""
	var current_animation := ""
	var current_frame := -1
	if actor != null:
		frame_animation = str(actor.get("frame_animation"))
		current_animation = str(actor.get("_current_animation"))
		current_frame = int(actor.get("_current_frame"))
	var float_vis := _float_visible_count(hero)
	var origins := hero.combat_float_origins()
	var elapsed: float = float(hero.get("_attack_elapsed"))
	print("FRAME name=%s kind=%s state=%s xsxb frame_animation=%s _current_animation=%s _current_frame=%d _attack_elapsed=%.4f float_vis=%d origins=%d slots=%s" % [
		shot_name,
		String(hero.hero_kind),
		String(hero.current_state),
		frame_animation,
		current_animation,
		current_frame,
		elapsed,
		float_vis,
		origins.size(),
		hero.weapon_slots,
	])
	return {
		"clip": current_animation if current_animation != "" else frame_animation,
		"frame": current_frame,
		"state": String(hero.current_state),
	}


func _float_visible_count(hero: EmberHero) -> int:
	var visible_n := 0
	for child in hero.get_children():
		if not (child is Sprite2D):
			continue
		var sprite := child as Sprite2D
		var name := String(sprite.name)
		if name != "HeldWeapon" and not name.begins_with("HeldOrbit"):
			continue
		if sprite.visible and sprite.texture != null:
			visible_n += 1
	return visible_n


func _weapon_slot_dump(hero: EmberHero) -> String:
	var parts: Array[String] = []
	for child in hero.get_children():
		if not (child is Sprite2D):
			continue
		var sprite := child as Sprite2D
		var name := String(sprite.name)
		if name != "HeldWeapon" and not name.begins_with("HeldOrbit"):
			continue
		var tex := "" if sprite.texture == null else sprite.texture.resource_path.get_file()
		parts.append("%s vis=%s pos=%s rot=%.2f tex=%s" % [
			name, sprite.visible, sprite.position, sprite.rotation, tex,
		])
	return " | ".join(parts)


func _pose(hero: EmberHero) -> void:
	Input.warp_mouse(Vector2(1100.0, 360.0))
	hero.set("_aim_dir", Vector2.RIGHT)
	hero.call("_apply_facing", 1)
	hero.call("_refresh_held_weapon")


func _aim_camera(scene: Node, hero: Node2D, cam: Camera2D, zoom: float) -> void:
	if cam == null:
		return
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(zoom, zoom)
	cam.global_position = hero.global_position
	cam.reset_smoothing()
	cam.force_update_scroll()


func _save(shot_name: String) -> void:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var path := "res://tools/accept-shots/recheck/%s.png" % shot_name
	var tex := root.get_viewport().get_texture()
	if tex == null:
		print("SAVED %s err=no-texture" % path)
		return
	var image := tex.get_image()
	if image == null:
		print("SAVED %s err=no-image" % path)
		return
	var err := image.save_png(path)
	print("SAVED %s err=%s size=%sx%s" % [path, err, image.get_width(), image.get_height()])

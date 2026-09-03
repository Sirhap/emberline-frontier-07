extends SceneTree

## Headless: log every attack frame. Windowed opengl3: also dump crops.
const OUT := "res://dogfood-output/frost-armed-visual"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	EmberRunSave.delete_run()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	hero.apply_hero_kind(&"ember_hero", &"frost_armed")
	await process_frame
	hero.unlock_dash()
	hero.position = Vector2(640.0, 336.0)
	hero.call("_apply_facing", 1)
	var actor := hero.get_node_or_null("XSXBHeroActor")
	var anims: Dictionary = actor.get("_animations") if actor != null else {}
	var n: int = ((anims.get("attack_side", {}) as Dictionary).get("frames", []) as Array).size()
	var combo: Array = hero.get("_combo_end")
	print("ATTACK_CLIP n=%d combo_end=%s followup=%s speed_prop=%s" % [
		n, str(combo), str(hero.get("_followup_start")), str(actor.get("playback_speed")) if actor != null else "?"
	])
	hero.request_attack()
	await process_frame
	print("ATTACK_START elapsed=%s frame=%s speed=%s end=%s" % [
		str(hero.get("_attack_elapsed")),
		str(hero.call("_actor_frame")),
		str(actor.get("playback_speed")) if actor != null else "?",
		str(actor.get("playback_end_frame")) if actor != null else "?",
	])
	var seen: Dictionary = {}
	var order: PackedInt32Array = PackedInt32Array()
	var ticks := 0
	var last_dump := -1
	while float(hero.get("_attack_elapsed")) >= 0.0 and ticks < 180:
		var f := int(hero.call("_actor_frame"))
		order.append(f)
		seen[f] = true
		if f != last_dump and (f == 0 or f == int(n / 2) or f == n - 1 or f % 6 == 0):
			_save_tex(hero, "attack-f%02d" % f)
			last_dump = f
		await process_frame
		ticks += 1
	print("ATTACK_TICKS=%d unique=%d last=%d combo_live=%s order=%s" % [
		ticks,
		seen.size(),
		order[order.size() - 1] if order.size() else -1,
		str(hero.get("_attack_elapsed")),
		str(order),
	])
	assert(seen.size() >= n - 1, "attack must play the full clip, not stop at combo frame 6")
	assert(int(combo[0]) == n - 1, "combo end must be the last attack frame")
	print("ATTACK_PLAYALL_PASS unique=%d/%d" % [seen.size(), n])
	quit()


func _save_tex(hero: EmberHero, name: String) -> void:
	var actor := hero.get_node_or_null("XSXBHeroActor")
	if actor == null:
		return
	var sprite := actor.get_node_or_null("VisualOwner/FrameSprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return
	var img: Image = sprite.texture.get_image()
	if img == null:
		return
	var path := "%s/%s.png" % [OUT, name]
	img.save_png(path)

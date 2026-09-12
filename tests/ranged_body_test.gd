extends SceneTree

const Hero := preload("res://scripts/hero.gd")


## Exercise real body clips without a battlefield or production save access.
func _init() -> void:
	create_timer(20.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


## Verify idle/run continuity, shot feedback, action guards, and melee isolation.
func _run() -> void:
	for identity: StringName in [&"ember_hero", &"assassin"]:
		var hero := Hero.new()
		root.add_child(hero)
		hero.apply_hero_kind(identity)
		hero.equip_weapon(&"pistol")
		var actor := hero.get_node("XSXBHeroActor")
		actor.set_process(false)
		var shots: Array[StringName] = []
		hero.ranged_fired.connect(func(_origin: Vector2, _aim: Vector2, weapon: StringName) -> void:
			shots.append(weapon)
		)
		for motion: Vector2 in [Vector2.ZERO, Vector2.RIGHT]:
			hero.move_in_direction(motion, 0.0)
			hero._update_animation_state()
			var state: StringName = &"idle" if motion.is_zero_approx() else &"run"
			actor.set("_current_frame", 1)
			var frame_before := int(actor.get("_current_frame"))
			var origin := hero.position
			var shots_before := shots.size()
			hero._attack_cooldown = 0.0
			hero.request_attack()
			assert(shots.size() == shots_before + 1 and shots.back() == &"pistol", "One pistol projectile signal per shot")
			assert(hero.position == origin, "Recoil must not move the body")
			assert(float(hero.get("_recoil_bloom")) > 0.0, "Existing recoil spread remains active")
			assert(hero.current_state == state, "Shooting keeps idle/run state")
			assert(str(actor.get("_current_animation")) == hero._clip_name(state), "Shooting uses the resolved locomotion clip")
			assert(int(actor.get("_current_frame")) == frame_before, "Repeated fire must not restart locomotion")
			hero._update_attack(1.0)
			assert(hero.total_attack_hits_emitted == 0 and hero._attack_elapsed < 0.0, "No delayed melee hit or animation lock")
			assert(str(actor.get("_current_animation")) == hero._clip_name(state), "Attack tick cannot restore a slash")
			hero.request_attack()
			assert(shots.size() == shots_before + 1, "Cooldown still prevents immediate repeat fire")
			hero.call("_clear_action_queue")
		hero.move_in_direction(Vector2.ZERO, 0.0)
		hero._update_animation_state()
		assert(hero.current_state == &"idle", "Stopping while the gun cools down returns to idle")
		hero.request_jump()
		var shots_before_jump := shots.size()
		hero._attack_cooldown = 0.0
		hero.request_attack()
		assert(hero.current_state == &"jump" and shots.size() == shots_before_jump, "Shooting during jump remains queued")
		hero.call("_cancel_jump")
		hero.call("_clear_action_queue")
		hero.dash_cooldown_left = 0.0
		hero.request_dash()
		hero.request_attack()
		assert(hero.current_state == &"dash" and shots.size() == shots_before_jump, "Shooting during skill remains queued")
		hero.call("_clear_action_queue")
		hero.set("_dash_elapsed", -1.0)
		hero.equip_weapon(&"sword")
		hero.request_attack()
		assert(hero.current_state == &"attack" and hero._attack_elapsed >= 0.0, "Sword still starts the melee action")
		assert(str(actor.get("_current_animation")) == hero._clip_name(&"attack"), "Sword still plays the melee body clip")
		hero.free()
	await process_frame
	print("RANGED BODY PASS: knight/assassin locomotion, recoil, cooldown, action guards, melee isolation")
	quit(0)

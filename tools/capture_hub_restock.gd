extends SceneTree

## Buy a merchant shelf and capture the run→restock→home loop.
func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("RESTOCK_CAP_START")
	EmberRunSave.delete_run()
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hero: EmberHero = scene.get_node("HeroSlot/HeroController")
	var cam: Camera2D = scene.get("_camera")
	var mer: Sprite2D = scene.find_child("NpcMerchant", true, false)
	var director = scene.get("_director")
	if director != null:
		director.prep_left = 9999.0
	scene.get("_shop").is_open = true
	scene.set("scrap", 500)
	scene.call("_refresh_shop_ui")
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.enabled = true
		cam.zoom = Vector2(1.35, 1.35)
		cam.global_position = Vector2(420.0, -230.0)
		cam.reset_smoothing()
		cam.force_update_scroll()
	hero.position = Vector2(460.0, -140.0)
	for _i in range(12):
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://dogfood-output/qa"))
	root.get_viewport().get_texture().get_image().save_png("res://dogfood-output/qa/hub_restock_before.png")
	print("SHOT before job=", mer.get_meta("job", &""), " pos=", mer.position)
	scene.call("_try_buy_shelf", Vector2(460.0, -205.0))
	print("BUY job=", mer.get_meta("job", &""), " shelf=", mer.get_meta("job_shelf", -1))
	## Advance until merchant is mid-run or restocking.
	for _i in range(90):
		await process_frame
		var job: StringName = mer.get_meta("job", &"idle")
		if job == &"restock" or (job == &"run_to" and mer.position.distance_to(Vector2(460.0, -269.0)) < 40.0):
			break
	root.get_viewport().get_texture().get_image().save_png("res://dogfood-output/qa/hub_restock_run.png")
	print("SHOT run job=", mer.get_meta("job", &""), " clip=", mer.get_meta("clip", &""), " pos=", mer.position)
	for _i in range(120):
		await process_frame
		if StringName(mer.get_meta("job", &"")) == &"restock":
			break
	root.get_viewport().get_texture().get_image().save_png("res://dogfood-output/qa/hub_restock_anim.png")
	print("SHOT anim job=", mer.get_meta("job", &""), " clip=", mer.get_meta("clip", &""))
	for _i in range(180):
		await process_frame
		if StringName(mer.get_meta("job", &"")) == &"idle":
			break
	root.get_viewport().get_texture().get_image().save_png("res://dogfood-output/qa/hub_restock_home.png")
	print("SHOT home job=", mer.get_meta("job", &""), " pos=", mer.position)
	print("RESTOCK_CAP_PASS")
	quit(0)

extends SceneTree

const TalentCatalog := preload("res://scripts/talent_catalog.gd")
const OverlayScene := preload("res://scenes/ui/talent_choice_overlay.tscn")


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	var overlay = OverlayScene.instantiate()
	assert(overlay != null, "overlay scene must instantiate")
	root.add_child(overlay)
	assert(overlay.process_mode == Node.PROCESS_MODE_WHEN_PAUSED, "overlay processes only while paused")

	var choices: Array = [
		TalentCatalog.get_def(&"force_training"),
		TalentCatalog.get_def(&"tempered_body"),
		TalentCatalog.get_def(&"swift_step"),
	]
	assert(choices[0]["id"] == &"force_training")
	assert(choices[1]["id"] == &"tempered_body")
	assert(choices[2]["id"] == &"swift_step")

	var fired: Array = []
	overlay.talent_chosen.connect(func(talent_id: StringName) -> void:
		fired.append(talent_id)
	)

	overlay.show_choices(3, choices, {&"force_training": 1})
	assert(overlay.visible, "show_choices must show the overlay")

	overlay.choose_index(0)
	assert(fired.size() == 1, "talent_chosen must fire once")
	assert(fired[0] == &"force_training", "chosen id is the first card")
	assert(not overlay.visible, "overlay hides after a pick")

	overlay.choose_index(1)
	assert(fired.size() == 1, "hidden overlay must not emit again")

	print("TALENT OVERLAY PASS")
	quit()

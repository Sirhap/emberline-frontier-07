extends SceneTree

const SCENE_PATH := "res://scenes/ui/codex_panel.tscn"
const WeaponCatalog := preload("res://scripts/weapon_catalog.gd")
const EnemyCatalog := preload("res://scripts/enemy_catalog.gd")


func _init() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	assert(ResourceLoader.exists(SCENE_PATH), "codex panel scene must exist")
	var panel: Node = load(SCENE_PATH).instantiate()
	assert(panel != null, "codex panel instantiates")
	root.add_child(panel)
	await process_frame

	assert(not panel.visible, "codex panel starts hidden")

	var profile := {
		"codex": {
			"weapons": {"sword": {"discovered": true}},
			"enemies": {"scout": {"seen": true, "kills": 3, "leaks": 1, "first_seen_wave": 2}},
		},
		"records": {"highest_wave": 6, "best_kills": 10, "best_survive_time": 33.5},
		"heroes": {
			"ember_hero": {"runs": 2, "highest_run_level": 5, "highest_wave": 6, "total_kills": 10},
			"assassin": {"runs": 0, "highest_run_level": 0, "highest_wave": 0, "total_kills": 0},
		},
	}

	panel.call("open_weapons", profile)
	assert(panel.visible, "open_weapons shows the panel")
	assert(_title(panel) == "兵器图鉴", "weapon title")
	assert(_row_name(panel, "sword") == "大宝剑", "discovered sword shows catalog name")
	assert(_row_detail(panel, "sword") == "近战", "weapon kind is Chinese")
	assert(_row_name(panel, "pistol") == "???", "undiscovered pistol is hidden")
	assert(WeaponCatalog.has_id(&"pistol"), "pistol stays in the catalog")

	panel.call("open_enemies", profile)
	assert(panel.visible, "open_enemies keeps the panel open")
	assert(_title(panel) == "敌人图鉴", "enemy title")
	assert(_row_name(panel, "scout") == "侦察敌人", "seen scout shows catalog title")
	assert(_row_detail(panel, "scout").contains("击杀 3"), "scout kills")
	assert(_row_name(panel, "boss") == "???", "unseen boss is hidden")
	assert(EnemyCatalog.has_id(&"boss"), "boss stays in the catalog")

	panel.call("open_records", profile)
	assert(_title(panel) == "战绩碑", "records title")
	assert(_row_name(panel, "highest_wave") == "最高波次  6", "highest wave")
	assert(_row_name(panel, "best_kills") == "最高击杀  10", "best kills")
	assert(_row_name(panel, "best_survive_time").begins_with("最长存活"), "survive time row")

	var closer := panel.find_child("CloseButton", true, false) as Button
	assert(closer != null, "close button exists")
	assert(closer.custom_minimum_size.x >= 48.0 and closer.custom_minimum_size.y >= 48.0, "close is 48px+")
	panel.call("hide_panel")
	assert(not panel.visible, "hide_panel hides")

	print("CODEX PANEL PASS")
	quit()


func _title(panel: Node) -> String:
	var label := panel.find_child("PanelTitle", true, false) as Label
	assert(label != null, "PanelTitle exists")
	return label.text


func _row_name(panel: Node, id: String) -> String:
	var row := panel.find_child("Row_%s" % id, true, false)
	assert(row != null, "row %s exists" % id)
	var name_label := row.find_child("Name", true, false) as Label
	assert(name_label != null, "row %s has Name" % id)
	return name_label.text


func _row_detail(panel: Node, id: String) -> String:
	var row := panel.find_child("Row_%s" % id, true, false)
	assert(row != null, "row %s exists" % id)
	var detail := row.find_child("Detail", true, false) as Label
	assert(detail != null, "row %s has Detail" % id)
	return detail.text

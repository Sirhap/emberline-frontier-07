@tool
extends VBoxContainer

const HeroPackValidator := preload("res://scripts/hero_pack_validator.gd")
const HeroPackImporter := preload("res://scripts/hero_pack_importer.gd")

var _path: LineEdit
var _status: Label
var _list: ItemList
var _import_btn: Button
var _report: Dictionary = {}
var _dialog: EditorFileDialog


func _ready() -> void:
	name = "HeroPackImport"
	custom_minimum_size = Vector2(280, 360)
	var title := Label.new()
	title.text = "英雄/皮肤包"
	add_child(title)
	_path = LineEdit.new()
	_path.placeholder_text = "文件夹或 zip"
	add_child(_path)
	var row := HBoxContainer.new()
	add_child(row)
	var browse := Button.new()
	browse.text = "浏览"
	browse.pressed.connect(_browse)
	row.add_child(browse)
	var check := Button.new()
	check.text = "校验"
	check.pressed.connect(_validate)
	row.add_child(check)
	_import_btn = Button.new()
	_import_btn.text = "入库"
	_import_btn.disabled = true
	_import_btn.pressed.connect(_import)
	row.add_child(_import_btn)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(0, 220)
	add_child(_list)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	_dialog = EditorFileDialog.new()
	_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_ANY
	_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	_dialog.add_filter("*.zip", "Zip pack")
	_dialog.dir_selected.connect(_on_picked)
	_dialog.file_selected.connect(_on_picked)
	add_child(_dialog)


func _browse() -> void:
	_dialog.popup_file_dialog()


func _on_picked(path: String) -> void:
	_path.text = path
	_validate()


func _validate() -> void:
	var pack_dir := _path.text.strip_edges()
	_list.clear()
	_import_btn.disabled = true
	if pack_dir == "":
		_status.text = "先选文件夹或 zip"
		return
	_report = HeroPackValidator.validate_dir(pack_dir) if not pack_dir.to_lower().ends_with(".zip") else {"complete": false, "missing": ["zip: 点入库时解压再校验"], "slots": []}
	if pack_dir.to_lower().ends_with(".zip"):
		_status.text = "zip 将在入库时解压并校验"
		_import_btn.disabled = false
		return
	for row: Variant in _report.get("slots", []):
		if not (row is Dictionary):
			continue
		var slot: Dictionary = row
		var ok := bool(slot.get("ok", false))
		var label := "%s  %s  %d帧" % ["OK" if ok else "缺", String(slot.get("slot", "")), int(slot.get("frames", 0))]
		var idx := _list.add_item(label)
		_list.set_item_custom_fg_color(idx, Color(0.4, 0.9, 0.55) if ok else Color(1.0, 0.45, 0.45))
	for miss: Variant in _report.get("missing", []):
		var idx := _list.add_item(String(miss))
		_list.set_item_custom_fg_color(idx, Color(1.0, 0.45, 0.45))
	var complete := bool(_report.get("complete", false))
	_import_btn.disabled = not complete
	_status.text = "COMPLETE" if complete else "INCOMPLETE"


func _import() -> void:
	var pack_dir := _path.text.strip_edges()
	var result: Dictionary = HeroPackImporter.import_pack(pack_dir)
	if bool(result.get("ok", false)):
		_status.text = "已入库 %s" % String((result.get("pack", {}) as Dictionary).get("id", ""))
		_import_btn.disabled = true
		if Engine.is_editor_hint() and EditorInterface.get_resource_filesystem() != null:
			EditorInterface.get_resource_filesystem().scan()
	else:
		_report = result.get("report", {})
		_status.text = "失败：%s" % String(result.get("error", ""))
		_validate()

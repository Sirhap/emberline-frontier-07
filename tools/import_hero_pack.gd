extends SceneTree

const HeroPackImporter := preload("res://scripts/hero_pack_importer.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage: godot --headless --script tools/import_hero_pack.gd -- <pack_dir_or_zip>")
		quit(1)
		return
	var result: Dictionary = HeroPackImporter.import_pack(args[0])
	print(JSON.stringify(result))
	quit(0 if bool(result.get("ok", false)) else 1)

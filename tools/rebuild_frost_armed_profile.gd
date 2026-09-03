extends SceneTree

const HeroPackImporter := preload("res://scripts/hero_pack_importer.gd")


func _init() -> void:
	var rebuilt: Dictionary = HeroPackImporter.rebuild_profile("frost_armed")
	print("REBUILD %s" % JSON.stringify(rebuilt))
	quit(0 if bool(rebuilt.get("ok", false)) else 1)

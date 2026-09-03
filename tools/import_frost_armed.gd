extends SceneTree

const HeroPackImporter := preload("res://scripts/hero_pack_importer.gd")


func _init() -> void:
	var draft: Dictionary = HeroPackImporter.create_draft("frost_armed", "霜晶持械", "skin", "ember_hero")
	print("DRAFT %s" % JSON.stringify(draft))
	var published: Dictionary = HeroPackImporter.publish("frost_armed")
	print("PUBLISH %s" % JSON.stringify(published))
	quit(0 if bool(published.get("ok", false)) else 1)

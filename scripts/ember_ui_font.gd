extends RefCounted

const BUNDLED_PATH := "res://assets/fonts/cjk-ui.ttf"
const MACOS_FALLBACK := "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"

static var _cached: Font


static func bundled() -> Font:
	if _cached != null:
		return _cached
	var from_res := _load_bundled_resource()
	if from_res != null:
		_cached = from_res
		return _cached
	if FileAccess.file_exists(BUNDLED_PATH):
		var loaded := FontFile.new()
		if loaded.load_dynamic_font(BUNDLED_PATH) == OK:
			_cached = loaded
			return _cached
	if FileAccess.file_exists(MACOS_FALLBACK):
		var fallback := FontFile.new()
		if fallback.load_dynamic_font(MACOS_FALLBACK) == OK:
			_cached = fallback
			return _cached
	# Web has no system CJK. If the bundled TTF is in the pck, never hand
	# HUD a ThemeDB.fallback_font (Latin-only, tofu for Chinese).
	if FileAccess.file_exists(BUNDLED_PATH) or ResourceLoader.exists(BUNDLED_PATH):
		push_error("CJK UI font exists at %s but failed to load" % BUNDLED_PATH)
		_cached = FontFile.new()
		return _cached
	_cached = ThemeDB.fallback_font
	return _cached


static func _load_bundled_resource() -> Font:
	if not ResourceLoader.exists(BUNDLED_PATH):
		return null
	var res: Variant = load(BUNDLED_PATH)
	if res is Font:
		return res
	return null

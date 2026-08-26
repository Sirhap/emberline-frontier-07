extends RefCounted

const BUNDLED_PATH := "res://assets/fonts/cjk-ui.ttf"
const MACOS_FALLBACK := "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"

static var _cached: Font


static func bundled() -> Font:
	if _cached != null:
		return _cached
	var loaded := FontFile.new()
	if FileAccess.file_exists(BUNDLED_PATH) and loaded.load_dynamic_font(BUNDLED_PATH) == OK:
		_cached = loaded
		return _cached
	if FileAccess.file_exists(MACOS_FALLBACK):
		var fallback := FontFile.new()
		if fallback.load_dynamic_font(MACOS_FALLBACK) == OK:
			_cached = fallback
			return _cached
	_cached = ThemeDB.fallback_font
	return _cached

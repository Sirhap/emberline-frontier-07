class_name MobileFullscreen
extends RefCounted

## Web: ask the HTML shell to toggle Fullscreen API (needs a user gesture).
## Native: DisplayServer windowed / fullscreen. iOS Safari has no system fullscreen.
static func toggle() -> void:
	if OS.has_feature("web"):
		var js := Engine.get_singleton("JavaScriptBridge")
		if js != null:
			js.call("eval", "window.emberlineFullscreen&&window.emberlineFullscreen.toggle();", true)
		return
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

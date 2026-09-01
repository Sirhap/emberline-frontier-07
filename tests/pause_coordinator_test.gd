extends SceneTree

const PauseCoordinatorScript := preload("res://scripts/pause_coordinator.gd")

## Reason-dictionary checks only. Do not assert SceneTree.paused after quit.
func _init() -> void:
	var coord := PauseCoordinatorScript.new()
	assert(not coord.is_paused(), "starts with no pause reasons")
	assert(not coord.is_paused_for(&"talent"), "talent is not held at start")
	assert(coord.active_reasons().is_empty(), "active reasons start empty")

	coord.acquire(&"talent")
	assert(coord.is_paused_for(&"talent"), "acquire talent pauses for talent")
	assert(coord.is_paused(), "acquire talent pauses overall")
	assert(coord.active_reasons().size() == 1, "talent is the only reason")
	assert(coord.active_reasons()[0] == &"talent", "active reason is talent")

	coord.acquire(&"talent")
	assert(coord.is_paused_for(&"talent"), "second acquire still paused for talent")
	assert(coord.active_reasons().size() == 1, "duplicate acquire stays one entry")

	coord.acquire(&"user")
	assert(coord.is_paused_for(&"talent"), "talent still held after user")
	assert(coord.is_paused_for(&"user"), "acquire user pauses for user")
	assert(coord.is_paused(), "two reasons still pause overall")
	assert(coord.active_reasons().size() == 2, "talent and user are both active")

	coord.release(&"talent")
	assert(not coord.is_paused_for(&"talent"), "release talent drops talent")
	assert(coord.is_paused_for(&"user"), "user still held after releasing talent")
	assert(coord.is_paused(), "user keeps overall pause")
	assert(coord.active_reasons().size() == 1, "only user remains")
	assert(coord.active_reasons()[0] == &"user", "remaining reason is user")

	coord.release(&"user")
	assert(not coord.is_paused_for(&"user"), "release user drops user")
	assert(not coord.is_paused(), "no reasons means not paused")
	assert(coord.active_reasons().is_empty(), "no active reasons after last release")

	coord.release(&"missing")
	assert(not coord.is_paused(), "releasing unknown reason is a no-op")
	assert(coord.active_reasons().is_empty(), "unknown release does not add reasons")

	print("PAUSE COORDINATOR PASS")
	quit()

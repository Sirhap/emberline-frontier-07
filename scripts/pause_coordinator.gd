class_name PauseCoordinator
extends RefCounted

## Named pause reasons. Tree pause follows whether any reason is true.

var _tree: SceneTree
var _reasons: Dictionary[StringName, bool] = {}


## Optional SceneTree. When set, tree.paused tracks whether any reason is true.
func _init(tree: SceneTree = null) -> void:
	_tree = tree
	_sync_tree()


## Hold a pause reason. Acquiring the same reason twice stays one entry.
func acquire(reason: StringName) -> void:
	_reasons[reason] = true
	_sync_tree()


## Drop one reason. Releasing an unknown reason is a no-op.
func release(reason: StringName) -> void:
	_reasons.erase(reason)
	_sync_tree()


## True when this reason is currently held.
func is_paused_for(reason: StringName) -> bool:
	return bool(_reasons.get(reason, false))


## True when any pause reason is held.
func is_paused() -> bool:
	for held: bool in _reasons.values():
		if held:
			return true
	return false


## Reason names currently holding a pause.
func active_reasons() -> Array[StringName]:
	var names: Array[StringName] = []
	for reason: StringName in _reasons.keys():
		if _reasons[reason]:
			names.append(reason)
	return names


func _sync_tree() -> void:
	if _tree == null:
		return
	_tree.paused = is_paused()

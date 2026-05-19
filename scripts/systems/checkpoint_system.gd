extends Node
## Autoload. Tracks the currently active checkpoint across deaths.
## Falls back to the area's default_spawn when no checkpoint has been activated.

signal checkpoint_activated(checkpoint_name: String, position: Vector2)

var _active_name: String = ""
var _active_position: Vector2 = Vector2.ZERO
var _default_spawn: Vector2 = Vector2.ZERO
var _has_active: bool = false

# Called by each area on _ready() with the area's StartPoint position.
## Clears checkpoint state and sets the default respawn location for a new area.
func reset_for_new_area(default_spawn: Vector2) -> void:
	_default_spawn = default_spawn
	_active_name = ""
	_active_position = Vector2.ZERO
	_has_active = false

# Called by a Checkpoint when Kira enters it for the first time.
## Stores [param checkpoint_name] as the active checkpoint at [param position].
func activate(checkpoint_name: String, position: Vector2) -> void:
	_active_name = checkpoint_name
	_active_position = position
	_has_active = true
	checkpoint_activated.emit(checkpoint_name, position)

# Returns the world position Kira should respawn at.
## Returns the current checkpoint spawn point.
func get_spawn_point() -> Vector2:
	if _has_active:
		return _active_position
	return _default_spawn

## Returns the active checkpoint name, or an empty string if none is active.
func get_active_name() -> String:
	return _active_name

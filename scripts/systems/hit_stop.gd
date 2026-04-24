extends Node
## Autoload. Freezes Engine.time_scale for short weighty hit-impact moments.
## Non-stacking: a second call only extends the active window; it never shortens.

var _active_until_ms: int = 0

# Freeze time for `duration` seconds. Calling while already frozen extends, never shortens.
func freeze(duration: float = 0.06) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var new_end_ms: int = now_ms + int(duration * 1000.0)
	if new_end_ms <= _active_until_ms:
		return  # shorter-or-equal than active window; ignore
	_active_until_ms = new_end_ms
	Engine.time_scale = 0.0

	# Use a process_always timer so it ticks during the freeze.
	var remaining_s: float = max(0.001, (new_end_ms - now_ms) / 1000.0)
	var t: SceneTreeTimer = get_tree().create_timer(remaining_s, true, false, true)
	t.timeout.connect(_on_timeout.bind(new_end_ms), CONNECT_ONE_SHOT)

func _on_timeout(expected_end_ms: int) -> void:
	# Guard: only restore if this timeout matches the most recent freeze window.
	if expected_end_ms < _active_until_ms:
		return  # a later freeze superseded this timer; that one will restore
	Engine.time_scale = 1.0
	_active_until_ms = 0

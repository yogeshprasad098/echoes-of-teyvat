extends Node
## Autoload. Owns the active member of the current party and handles
## 1/2/3 keyboard input to swap between them.
##
## Swap is instant and in-place: the incoming character inherits the
## outgoing character's position, velocity, and facing direction.

signal active_changed(active: CharacterBase, slot: int)

var _party: Array[CharacterBase] = []
var _active_index: int = -1

func register(party: Array[CharacterBase]) -> void:
	_party = party.duplicate()
	_active_index = -1
	for member in _party:
		member.visible = false
		member.process_mode = Node.PROCESS_MODE_DISABLED
	if _party.is_empty():
		return
	set_active(0)

func set_active(index: int) -> void:
	if index < 0 or index >= _party.size():
		return
	if index == _active_index:
		return
	var incoming: CharacterBase = _party[index]
	if _active_index >= 0 and _active_index < _party.size():
		var outgoing: CharacterBase = _party[_active_index]
		incoming.global_position = outgoing.global_position
		incoming.velocity = outgoing.velocity
		incoming.facing_direction = outgoing.facing_direction
		outgoing.visible = false
		outgoing.process_mode = Node.PROCESS_MODE_DISABLED
	incoming.visible = true
	incoming.process_mode = Node.PROCESS_MODE_INHERIT
	_active_index = index
	_pulse_hitstop()
	active_changed.emit(incoming, _active_index)

# HitStop is an autoload — accessed indirectly so that unit tests
# instantiating this script outside the main runtime don't fail to compile.
func _pulse_hitstop() -> void:
	var ml := Engine.get_main_loop()
	if ml == null or not (ml is SceneTree):
		return
	var hs := (ml as SceneTree).root.get_node_or_null("HitStop")
	if hs and hs.has_method("freeze"):
		hs.freeze(0.04)

func active() -> CharacterBase:
	if _active_index < 0 or _active_index >= _party.size():
		return null
	return _party[_active_index]

func active_slot() -> int:
	return _active_index

func party_size() -> int:
	return _party.size()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_1"):
		set_active(0)
	elif event.is_action_pressed("switch_2"):
		set_active(1)
	elif event.is_action_pressed("switch_3"):
		set_active(2)

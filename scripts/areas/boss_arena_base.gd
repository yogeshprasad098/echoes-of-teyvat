class_name BossArenaBase
extends AreaBase
## One-screen boss arena that clears when its boss dies.

@export var boss_node_path: NodePath = ^"Enemies/Boss"

var boss: BossBase = null
var _completed: bool = false

func _ready() -> void:
	super._ready()
	boss = get_node_or_null(boss_node_path) as BossBase
	if boss:
		boss.died.connect(_on_boss_died)

func reset_area() -> void:
	_completed = false
	super.reset_area()
	boss = get_node_or_null(boss_node_path) as BossBase
	if boss and not boss.died.is_connected(_on_boss_died):
		boss.died.connect(_on_boss_died)

func _on_boss_died() -> void:
	if _completed:
		return
	_completed = true
	area_completed.emit()

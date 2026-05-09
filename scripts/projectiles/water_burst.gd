class_name WaterBurst
extends Area2D
## Marina's skill projectile. Stationary puddle that applies hydro aura
## to enemies in radius and heals the active character once on cast.
## CharacterSwitcher is accessed indirectly so the script compiles outside
## production boot (e.g., headless test contexts).

const DIRECT_DAMAGE: float = 18.0
const HEAL_AMOUNT: float = 12.0
const LIFETIME_SEC: float = 0.5

@onready var lifetime_timer: Timer = %LifetimeTimer

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_release)
	reset_projectile()
	_heal_active()

## Restarts lifetime and collision state when reused from the projectile pool.
func reset_projectile() -> void:
	monitoring = true
	monitorable = true
	if lifetime_timer:
		lifetime_timer.start(LIFETIME_SEC)

func _heal_active() -> void:
	var switcher: Node = get_tree().root.get_node_or_null("CharacterSwitcher")
	if switcher == null or not switcher.has_method("active"):
		return
	var active: CharacterBase = switcher.active()
	if active == null:
		return
	active.current_health = min(active.max_health, active.current_health + HEAL_AMOUNT)
	active.health_changed.emit(active.current_health, active.max_health)

func _on_body_entered(body: Node) -> void:
	if body is EnemyBase:
		body.take_damage(DIRECT_DAMAGE, "hydro")

func _release() -> void:
	monitoring = false
	if lifetime_timer:
		lifetime_timer.stop()
	var pool := _projectile_pool()
	if pool and pool.has_method("release_projectile"):
		pool.release_projectile(self)
	else:
		queue_free()

func _projectile_pool() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("ProjectilePool")

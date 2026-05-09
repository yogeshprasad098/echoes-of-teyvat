extends Node
## Reuses short-lived projectile and combat effect scenes to avoid repeated allocation churn.

const POOL_KEY_META: StringName = &"pool_key"

var _pool: Dictionary[String, Array] = {}

## Returns a pooled scene instance at [param world_position], parented under [param parent].
func spawn_projectile(scene: PackedScene, parent: Node, world_position: Vector2) -> Node:
	if scene == null or parent == null:
		return null
	var key: String = scene.resource_path
	var instance: Node = _take_from_pool(key)
	if instance == null:
		instance = scene.instantiate()
		instance.set_meta(POOL_KEY_META, key)
	parent.add_child(instance)
	if instance is Node2D:
		(instance as Node2D).global_position = world_position
	instance.visible = true
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance.has_method("reset_projectile"):
		instance.reset_projectile()
	return instance

## Hides and stores [param projectile] for reuse, or frees it if it was not pool-created.
func release_projectile(projectile: Node) -> void:
	if projectile == null:
		return
	var key: String = str(projectile.get_meta(POOL_KEY_META, ""))
	if key == "":
		projectile.queue_free()
		return
	if projectile.get_parent() != null:
		projectile.get_parent().remove_child(projectile)
	projectile.visible = false
	projectile.process_mode = Node.PROCESS_MODE_DISABLED
	if not _pool.has(key):
		_pool[key] = []
	_pool[key].append(projectile)

func _take_from_pool(key: String) -> Node:
	if not _pool.has(key):
		return null
	var entries: Array = _pool[key]
	while not entries.is_empty():
		var candidate := entries.pop_back() as Node
		if is_instance_valid(candidate):
			return candidate
	return null

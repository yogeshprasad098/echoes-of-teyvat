class_name MuzzleFlash
extends Node2D
## Spawned at the hand on orb release. One-shot particle burst + flash polygon
## that fades out, then queue_frees.

const SCENE: PackedScene = preload("res://scenes/effects/muzzle_flash.tscn")

@onready var burst: GPUParticles2D = %Burst
@onready var flash: Polygon2D = %Flash

# Spawn at world position, with horizontal facing (1 = right, -1 = left)
# and a tinted color (defaults to fire orange).
static func spawn(world_position: Vector2, facing: int, tint: Color = Color(1, 0.78, 0.32)) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var fx: MuzzleFlash = null
	var pool := tree.root.get_node_or_null("ProjectilePool")
	if pool and pool.has_method("spawn_projectile"):
		fx = pool.spawn_projectile(SCENE, tree.current_scene, world_position) as MuzzleFlash
	else:
		fx = SCENE.instantiate() as MuzzleFlash
		fx.global_position = world_position
		tree.current_scene.add_child(fx)
	fx.scale.x = float(facing)
	fx._fire(tint)

## Restores visual state when reused from the projectile pool.
func reset_projectile() -> void:
	visible = true
	modulate.a = 1.0
	flash.modulate.a = 1.0
	flash.scale = Vector2.ONE
	flash.visible = true
	burst.emitting = false

func _fire(tint: Color) -> void:
	flash.color = tint
	burst.modulate = tint
	burst.emitting = true
	# Quick scale + fade on the flash polygon, then free.
	flash.scale = Vector2(0.3, 0.3)
	var tween := create_tween()
	tween.parallel().tween_property(flash, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.18)
	tween.tween_interval(0.3)
	tween.tween_callback(_release)

func _release() -> void:
	var tree := get_tree()
	var pool := tree.root.get_node_or_null("ProjectilePool") if tree else null
	if pool and pool.has_method("release_projectile"):
		pool.release_projectile(self)
	else:
		queue_free()

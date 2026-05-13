class_name RyneElectroEffect
extends Node2D
## Sprite-based one-shot electro slash and impact effects for Ryne.

const SCENE: PackedScene = preload("res://scenes/effects/ryne_electro_effect.tscn")

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D

static func spawn_slash(world_position: Vector2, facing: int) -> void:
	_spawn(world_position, facing, &"slash")

static func spawn_impact(world_position: Vector2) -> void:
	_spawn(world_position, 1, &"impact")

static func _spawn(world_position: Vector2, facing: int, animation: StringName) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var fx: RyneElectroEffect = null
	var pool := tree.root.get_node_or_null("ProjectilePool")
	if pool and pool.has_method("spawn_projectile"):
		fx = pool.spawn_projectile(SCENE, tree.current_scene, world_position) as RyneElectroEffect
	else:
		fx = SCENE.instantiate() as RyneElectroEffect
		fx.global_position = world_position
		tree.current_scene.add_child(fx)
	if fx:
		fx.play(animation, facing)

func _ready() -> void:
	if sprite:
		sprite.animation_finished.connect(_release)

func reset_projectile() -> void:
	visible = true
	scale = Vector2.ONE
	if sprite:
		sprite.visible = true
		sprite.stop()
		sprite.frame = 0

func play(animation: StringName, facing: int = 1) -> void:
	scale.x = float(facing)
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation):
		_release()
		return
	sprite.play(animation)

func _release() -> void:
	var tree := get_tree()
	var pool := tree.root.get_node_or_null("ProjectilePool") if tree else null
	if pool and pool.has_method("release_projectile"):
		pool.release_projectile(self)
	else:
		queue_free()

class_name EnemyElectricOrb
extends Area2D

const PhysicsModel := preload("res://scripts/core/game_physics.gd")
const ELITE_VFX_FRAMES := preload("res://resources/sprite_frames/storm_peak_elite_enemy_vfx_sprite_frames.tres")
const ENEMY_VFX := preload("res://scripts/effects/enemy_vfx_effect.gd")

@export var damage: float = 12.0
@export var speed: float = PhysicsModel.TILE_SIZE_PX * 5.5
@export var lifetime_sec: float = 3.0

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var lifetime_timer: Timer = %LifetimeTimer

var _direction: Vector2 = Vector2.RIGHT
var _released: bool = false

func _ready() -> void:
	collision_layer = PhysicsModel.PROJECTILE_LAYER
	collision_mask = PhysicsModel.PLAYER_LAYER | PhysicsModel.WORLD_LAYER
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_release)
	lifetime_timer.start(lifetime_sec)
	if sprite:
		sprite.play(&"electric_orb")

func launch(start_position: Vector2, direction: Vector2) -> void:
	global_position = start_position
	_direction = direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	if sprite:
		sprite.flip_h = _direction.x < 0.0

func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if _released:
		return
	if body is CharacterBase:
		body.take_damage(damage)
		ENEMY_VFX.spawn(get_parent(), ELITE_VFX_FRAMES, &"electric_burst", global_position, false, Vector2.ONE, 11)
		_release()
	elif body is TileMapLayer or body is TileMap or body is StaticBody2D:
		ENEMY_VFX.spawn(get_parent(), ELITE_VFX_FRAMES, &"electric_burst", global_position, false, Vector2.ONE, 11)
		_release()

func _release() -> void:
	if _released:
		return
	_released = true
	queue_free()

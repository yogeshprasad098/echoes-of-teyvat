class_name Grunt
extends EnemyBase
## Basic patrol enemy. Walks back and forth, chases Kira when nearby, deals contact damage.

# === Enums ===
enum State { PATROL, CHASE, DEAD }

# === Constants ===
const CHASE_SPEED: float = 120.0
const CONTACT_COOLDOWN: float = 1.0

# === Private Variables ===
var _state: State = State.PATROL
var _patrol_direction: int = 1
var _target: CharacterBase = null
var _contact_cooldown: float = 0.0

# === Onready ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_left: RayCast2D = $PatrolRayLeft
@onready var ray_right: RayCast2D = $PatrolRayRight
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection: Area2D = $DetectionArea2D
@onready var patrol_timer: Timer = $PatrolTimer

func _ready() -> void:
	super._ready()
	detection.body_entered.connect(_on_detection_body_entered)
	detection.body_exited.connect(_on_detection_body_exited)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	sprite.play("walk")

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	_contact_cooldown = max(0.0, _contact_cooldown - delta)
	velocity.y += gravity * delta

	match _state:
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()

	move_and_slide()

# === Patrol ===

func _process_patrol() -> void:
	var active_ray := ray_right if _patrol_direction == 1 else ray_left
	var has_ground: bool = active_ray.is_colliding()
	var wall_hit: bool = is_on_wall()

	# Reverse direction at ledges or walls.
	if not has_ground or wall_hit:
		_patrol_direction *= -1

	velocity.x = _patrol_direction * move_speed
	sprite.flip_h = _patrol_direction == -1

func _on_patrol_timer_timeout() -> void:
	_patrol_direction *= -1

# === Chase ===

func _process_chase() -> void:
	if not is_instance_valid(_target):
		_state = State.PATROL
		return

	var dir: float = sign(_target.global_position.x - global_position.x)
	velocity.x = dir * CHASE_SPEED
	sprite.flip_h = dir == -1.0

	# Contact damage with cooldown.
	var dist: float = global_position.distance_to(_target.global_position)
	if dist < 40.0 and _contact_cooldown <= 0.0:
		_target.take_damage(damage)
		_contact_cooldown = CONTACT_COOLDOWN

func _on_detection_body_entered(body: Node) -> void:
	if body is CharacterBase:
		_target = body
		_state = State.CHASE

func _on_detection_body_exited(body: Node) -> void:
	if body == _target:
		_target = null
		_state = State.PATROL
		sprite.play("walk")

# === Hurt / Death ===

func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Damage is dealt by Kira's hitbox via take_damage() directly; this handles AoE areas.
	pass

func take_damage(amount: float, element: String = "") -> void:
	if _state == State.DEAD:
		return
	super.take_damage(amount, element)

func die() -> void:
	_state = State.DEAD
	velocity = Vector2.ZERO
	sprite.play("death")
	await sprite.animation_finished
	super.die()

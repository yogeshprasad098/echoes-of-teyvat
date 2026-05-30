class_name StormPeaksBossProjectile
extends EnemyHydroProjectile

@export var rotate_to_direction: bool = true

func launch(start_position: Vector2, direction: Vector2) -> void:
	super.launch(start_position, direction)
	if rotate_to_direction and _direction != Vector2.ZERO:
		rotation = _direction.angle()
		if sprite:
			sprite.flip_h = false

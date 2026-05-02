extends Camera3D
## Reads the MAIN window's active Camera2D (not this SubViewport's) and nudges
## the 3D camera's x position so the 3D background parallaxes with the 2D scene.

@export var parallax_factor: float = 0.04

var _base_x: float = 0.0

func _ready() -> void:
	_base_x = position.x

func _process(_delta: float) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var root_vp: Viewport = tree.root
	if root_vp == null:
		return
	var main_cam_2d: Camera2D = root_vp.get_camera_2d()
	if main_cam_2d == null:
		return
	position.x = _base_x + main_cam_2d.global_position.x * parallax_factor

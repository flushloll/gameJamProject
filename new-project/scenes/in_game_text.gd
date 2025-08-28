extends Node3D
@export var move_speed: float = 2.0
@onready var cam = get_node("/root/Main/SubViewportContainer/SubViewport/Player/Camera3D")

func _process(delta):
	look_at(cam.global_position, Vector3.UP, true)

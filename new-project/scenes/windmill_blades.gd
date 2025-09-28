extends MeshInstance3D

@export var rotation_speed = 0.25

func _process(delta):
	rotate_z(rotation_speed * delta)

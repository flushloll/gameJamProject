extends Node3D

var speed := 300
var target : Node3D
var on_hit_callback : Callable  # Called when egg reaches target

var spin_speed := Vector3(5.0, 0.0, 5.0)  # radians per second on x, y, z

# EggNode3D.gd
func _process(delta):
	#var i = 1.05
	#speed += i*i*i
	if visible and target:
		look_at(target.global_position, Vector3.UP)
		translate(Vector3.FORWARD * speed * delta)
		if global_position.distance_to(target.global_position) < 0.2:
			visible = false
			if on_hit_callback:
				on_hit_callback.call()
	# Spin child mesh
	#$EggMesh.rotate_x(spin_speed.x * delta)
	#$EggMesh.rotate_y(spin_speed.y * delta)
	#$EggMesh.rotate_z(spin_speed.z * delta)

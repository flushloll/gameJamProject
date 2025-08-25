extends Camera3D
#
#@export var decay: float = 1.5
#@export var max_offset: float = 0.3
#@export var max_roll: float = 5.0
#@export var trauma_power: float = 2.0
#
#var trauma: float = 0.0
#var noise := FastNoiseLite.new()
#var time: float = 0.0
#
#func _ready():
	#noise.seed = randi()
	#noise.frequency = 2.0
#
#func _process(delta: float):
	#if trauma > 0:
		#trauma = max(trauma - decay * delta, 0)
		#time += delta
		#apply_shake()
		#
#
#func add_trauma(amount: float):
	#trauma = clamp(trauma + amount, 0, 1)
#
#func apply_shake():
	#var intensity = pow(trauma, trauma_power)
#
	## Positional offset
	#var offset = Vector3(
		#max_offset * intensity * noise.get_noise_2d(time, 0),
		#max_offset * intensity * noise.get_noise_2d(0, time),
		#0
	#)
#
	## Rotational roll
	#var roll_angle = deg_to_rad(max_roll) * intensity * noise.get_noise_2d(time, time)
#
	## Apply **local offsets**, keeping the camera’s current parent/follow logic intact
	#transform.origin += offset
	#transform.basis = Basis(Vector3(0, 0, 1), roll_angle) * transform.basis

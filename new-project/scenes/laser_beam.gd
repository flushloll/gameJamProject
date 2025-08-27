extends MeshInstance3D
#
#@export var beam_material: StandardMaterial3D
#@export var beam_radius: float = 0.05
#@export var beam_duration: float = 0.1  # seconds laser stays visible
#
#var timer: Timer
#
#func _ready():
	## Create thin cylinder mesh
	#var cylinder = CylinderMesh.new()
	#cylinder.top_radius = beam_radius
	#cylinder.bottom_radius = beam_radius
	#cylinder.height = 1
	#cylinder.radial_segments = 6
	#mesh = cylinder
	#material_override = beam_material
	#visible = false
#
	## Timer for hiding the laser automatically
	#timer = Timer.new()
	#timer.one_shot = true
	#timer.wait_time = beam_duration
	#add_child(timer)
	#timer.timeout.connect(self._on_timer_timeout)
#
#func _on_timer_timeout():
	#visible = false
#
## Call this when you shoot
#func show_laser(start: Vector3, end: Vector3):
	#visible = true
#
	#var direction = end - start
	#var length = direction.length()
#
	## Position in the middle
	#global_position = start + direction / 2
#
	## Scale to match length
	#scale = Vector3(1, length / 2, 1)
#
	## Rotate to point toward target
	#look_at(end, Vector3.UP)
#
	## Restart the timer
	#timer.start()

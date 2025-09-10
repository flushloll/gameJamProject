extends Camera3D

@export var intensity := 0.5        # How much the camera moves
@export var duration := 0.3         # Total shake duration in seconds
@export var frequency := 25.0       # How fast it jitters

var original_transform : Transform3D
var time_elapsed := 0.0
var shaking := false

func shake(_intensity := 0.5, _duration := 0.3):
	intensity = _intensity
	duration = _duration
	time_elapsed = 0.0
	original_transform = transform
	shaking = true

func _process(delta):
	if shaking:
		time_elapsed += delta
		if time_elapsed < duration:
			# Simple random offset
			var offset = Vector3(
				randf_range(-1,1),
				randf_range(-1,1),
				randf_range(-1,1)
			) * intensity
			transform.origin = original_transform.origin + offset
		else:
			# Reset camera
			transform = original_transform
			shaking = false

extends MeshInstance3D   # or MeshInstance3D if that’s your sword mesh

@export var jitter_strength: float = 0.02   # distance of jitter
@export var jitter_speed: float = 20.0      # speed of jitter

var jittering: bool = false
var base_transform: Transform3D
var time: float = 0.0

func _ready():
	base_transform = transform

func _process(delta):
	if jittering:
		time += delta * jitter_speed

		var offset = Vector3(
			sin(time * 1.3) * jitter_strength,
			cos(time * 1.7) * jitter_strength,
			0
		)

		transform.origin = base_transform.origin + offset
	else:
		transform = base_transform

func start_jitter():
	jittering = true
	time = 0.0   # reset noise so it starts fresh

func stop_jitter():
	jittering = false

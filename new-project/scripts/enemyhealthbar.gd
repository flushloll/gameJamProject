
extends TextureProgressBar

# The 3D character whose health this bar represents
@onready var character = get_parent()
# Camera to calculate screen-space position
var camera: Camera3D

func _ready():
	# Get the active camera
	camera = get_node("/root/GameController/World3D/Main/SubViewportContainer/SubViewport").get_camera_3d()
	show()
	
	# Set the initial value to a placeholder (e.g., full health)
	if character and "max_health" in character:
		value = character.max_health
	if character and "current_health" in character:
		value = character.current_health

func _process(delta):
	if not character or not camera:
		return
	
	# Update health bar value
	if character and "current_health" in character:
		value = character.current_health
	
	var screen_pos = camera.unproject_position(character.global_position + Vector3(0, 2, 0)) 
	global_position = screen_pos
	#  you can adjust the position for visual clarity
	global_position += Vector2(-get_rect().size.x / 2, 0)
	
	var distance = camera.global_transform.origin.distance_to(character.global_transform.origin)
	var scale_factor = clamp(0.25 - distance / 100.0, 0.11, 0.25)
	scale = Vector2(scale_factor, scale_factor)

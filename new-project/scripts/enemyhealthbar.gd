extends TextureProgressBar

# The 3D enemy whose health this bar represents
@onready var enemy = get_parent()
# Camera to calculate screen-space position
var camera: Camera3D

func _ready():
	# Get the active camera
	camera = get_node("/root/GameController/World3D/Main/SubViewportContainer/SubViewport").get_camera_3d()
	show()
	
	# Set the initial value to a placeholder (e.g., full health)
	if enemy and "max_health" in enemy:
		value = enemy.max_health
	if enemy and "current_health" in enemy:
		value = enemy.current_health

func _process(delta):
	if not enemy or not camera:
		return
	
	# Update health bar value
	if enemy and "current_health" in enemy:
		value = enemy.current_health
	
	var to_enemy = enemy.global_position - camera.global_transform.origin
	var forward = -camera.global_transform.basis.z  # Camera's forward direction
	
	# Check if enemy is in front of camera
	if forward.dot(to_enemy) <= 0:
		visible = false
		return
	
	# Project enemy position to screen space
	var screen_pos = camera.unproject_position(enemy.global_position + Vector3(0, 1, 0))
	var viewport_rect = get_viewport_rect()
	
	# Check if on screen
	if screen_pos.x < 0 or screen_pos.y < 0 or screen_pos.x > viewport_rect.size.x or screen_pos.y > viewport_rect.size.y:
		visible = false
	else:
		if value > 0:
			visible = true
		global_position = screen_pos
		global_position += Vector2(-get_rect().size.x / 2, 0)
		
		var distance = camera.global_transform.origin.distance_to(enemy.global_transform.origin)
		var scale_factor = clamp(0.25 - distance / 100.0, 0.11, 0.25)
		scale = Vector2(scale_factor, scale_factor)

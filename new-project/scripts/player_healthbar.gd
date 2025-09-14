extends TextureProgressBar

# The 3D character whose health this bar represents
@onready var character = $"../../Player"

func _ready():
	
	# Set the initial value to a placeholder (e.g., full health)
	if character and "max_health" in character:
		value = character.max_health
	if character and "current_health" in character:
		value = character.current_health

func _process(delta):
	
	# Update health bar value
	if character and "current_health" in character:
		value = character.current_health

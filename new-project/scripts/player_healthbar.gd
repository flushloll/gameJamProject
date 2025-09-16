extends TextureProgressBar

# The 3D character whose health this bar represents
@onready var character = $"../../../Player"

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
		if value == 100:
			texture_over = load("res://ui/PlayerHealthBarTopLeftFull.png")
		elif value <= 99 and value >= 66:
			texture_over = load("res://ui/PlayerHealthBarTopLeft66.png")
		elif value <= 65 and value >= 33:
			texture_over = load("res://ui/PlayerHealthBarTopLeft33.png")
		elif value <= 32 and value >= 1:
			texture_over = load("res://ui/PlayerHealthBarTopLeft1.png")
		elif value <= 0:
			texture_over = load("res://ui/PlayerHealthBarTopLeft0.png")

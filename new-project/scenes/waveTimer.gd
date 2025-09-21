extends Label

func _ready():
	pass

func fadeIn():
			# Make sure it starts invisible
	modulate.a = 0.0

	# Create and configure a tween
	await get_tree().create_timer(1)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 3.0) # (target node, property, final value, duration)

func changeWaveTimerLabel(newTime):
	text = str(newTime)
	

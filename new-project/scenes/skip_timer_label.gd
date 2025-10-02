extends Label

func _ready():
	modulate.a = 0.0

func skipWaveTimerFadeIn():
	
	modulate.a = 0.0
	visible = true
		
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 3.0)

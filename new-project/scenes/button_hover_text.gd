extends VBoxContainer

func _ready():
	modulate.a = 0.0

func fadeIn():
	await get_tree().create_timer(0.25)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
func fadeOut():
	await get_tree().create_timer(0.25)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)

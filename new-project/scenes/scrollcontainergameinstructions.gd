extends ScrollContainer

@export var scroll_speed := 20.0  # Pixels per input press

func _input(event):
	if event.is_action_pressed("ui_down"):
		scroll_vertical += scroll_speed
	elif event.is_action_pressed("ui_up"):
		scroll_vertical -= scroll_speed

extends Sprite2D

func _process(delta):
	var viewport_size = get_viewport_rect().size
	position = viewport_size / 2

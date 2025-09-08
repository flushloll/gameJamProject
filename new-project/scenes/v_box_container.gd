extends VBoxContainer

@export var arrow_texture: Texture2D                # your arrow PNG
@export var arrow_scale: Vector2 = Vector2.ONE      # e.g. (0.5, 0.5) or (2, 2)
@export var flip_h: bool = false                    # flip horizontally
@export var flip_v: bool = false                    # flip vertically
@export var right_padding: int = 10                 # space from the right edge

var current_index: int = 0
var panels: Array[Control] = []
var arrows: Array[TextureRect] = []


func _ready():
	_create_arrows()
	call_deferred("_layout_all_arrows") # wait until panel sizes are valid


func _create_arrows():
	panels.clear()
	arrows.clear()

	for child in get_children():
		if child is Control:
			var panel: Control = child
			panels.append(panel)

			var arrow := TextureRect.new()
			arrow.texture = arrow_texture
			arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			arrow.visible = (panels.size() - 1 == current_index)

			# Set real size using scale
			var scaled_size = arrow_texture.get_size() * arrow_scale
			arrow.set_size(scaled_size)

			# Built-in flip support
			arrow.flip_h = flip_h
			arrow.flip_v = flip_v

			panel.add_child(arrow)
			arrows.append(arrow)

			panel.resized.connect(func(): _position_arrow(panel, arrow))


func _layout_all_arrows():
	for i in range(arrows.size()):
		_position_arrow(panels[i], arrows[i])


func _position_arrow(panel: Control, arrow: TextureRect):
	if arrow.texture == null:
		return

	var arrow_size = arrow.size

	# Lock arrow to right side
	arrow.anchor_left = 1.0
	arrow.anchor_right = 1.0
	arrow.offset_right = -right_padding
	arrow.offset_left = (arrow_size.x + right_padding)

	# Vertically center
	var top = (panel.size.y - arrow_size.y) * 0.5
	arrow.offset_top = top
	arrow.offset_bottom = top + arrow_size.y


func _unhandled_input(event):
	if event.is_action_pressed("ui_down"):
		_move_selection(1)
	elif event.is_action_pressed("ui_up"):
		_move_selection(-1)


func _move_selection(direction: int):
	if arrows.is_empty():
		return

	arrows[current_index].visible = false
	current_index = (current_index + direction + arrows.size()) % arrows.size()
	arrows[current_index].visible = true

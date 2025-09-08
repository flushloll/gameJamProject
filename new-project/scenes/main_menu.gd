extends Control

@onready var arrow = $Arrow
@onready var options = $VBoxContainer.get_children()  # Panels

var current_index = 0
var arrow_offset = Vector2(80, 45) # Adjust as needed

var target_position: Vector2
var smoothing_speed := 8.0  # higher = faster, lower = slower

func _ready():
	call_deferred("update_arrow_position")
	target_position = arrow.global_position

func _input(event):
	if event.is_action_pressed("ui_down"):
		current_index = (current_index + 1) % options.size()
		update_arrow_position()
	elif event.is_action_pressed("ui_up"):
		current_index = (current_index - 1 + options.size()) % options.size()
		update_arrow_position()
	elif event.is_action_pressed("ui_accept"):
		select_option()

func _process(delta):
	# Smoothly move the arrow towards the target position
	arrow.global_position = arrow.global_position.lerp(target_position, smoothing_speed * delta)

func update_arrow_position():
	var panel = options[current_index]
	target_position = panel.get_global_position() + Vector2(panel.size.x, 0) + arrow_offset

func select_option():
	match current_index:
		0:
			print("Start Game")
			GlobalController.game_controller.change_3d_scene("res://scenes/main.tscn")
			# new_scene, delete, keep_running, transition, transition_in, transition_out, seconds
			GlobalController.game_controller.change_gui_scene("null", true)
		1:
			print("Options")
		2:
			print("Quit Game")

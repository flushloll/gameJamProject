extends HBoxContainer

@onready var arrow = $Arrow

# The buttons/labels inside the DeathScreenMenu
@onready var options: Array = [
	$MarginContainer/VBoxContainer/RetryButton, 
	$MarginContainer/VBoxContainer/MarginContainer/MainMenuButton
]

@onready var selectionAudio = $"../SelectOptionSFX"
@onready var changeSelectionSFX = $"../ChangeSelectionSFX"

var current_index = 0
var target_position: Vector2
var smoothing_speed := 8.0
var bounce_amplitude := 1.2
var bounce_speed := 4.0
var time_passed := 0.0

func _ready():
	current_index = 0
	var current_option = options[current_index]
	target_position = current_option.global_position + Vector2(current_option.size.x / 2, current_option.size.y / 2) + Vector2(670, 30)# Adjust offset 
	$"../DeathScreenBackground".hide()
	hide()
	
func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_down"):
		current_index = (current_index + 1) % options.size()
		play_moving_audio()
		update_arrow_position()
	elif event.is_action_pressed("ui_up"):
		current_index = (current_index - 1 + options.size()) % options.size()
		play_moving_audio()
		update_arrow_position()
	elif event.is_action_pressed("ui_accept"):
		_on_option_selected(options[current_index])

func _process(delta):
	if not visible:
		return

	time_passed += delta
	# Smooth movement
	arrow.global_position = arrow.global_position.lerp(target_position, smoothing_speed * delta)

	# Wiggle effect
	var bounce = sin(time_passed * bounce_speed) * bounce_amplitude
	arrow.global_position.x += bounce

func update_arrow_position():
	var current_option = options[current_index]
	if current_index == 0:
		target_position = current_option.global_position + Vector2(current_option.size.x / 2, current_option.size.y / 2) + Vector2(240, 5)# Adjust offset 
	elif current_index == 1:
		target_position = current_option.global_position + Vector2(current_option.size.x / 2, current_option.size.y / 2) + Vector2(190, 5)# Adjust offset 
	time_passed = 0.0

func play_moving_audio():
	changeSelectionSFX.pitch_scale = randf_range(0.97, 1.03)
	changeSelectionSFX.play()

func _on_option_selected(option_node):
	selectionAudio.play()
	match option_node.name:
		"RetryButton":
			GlobalController.game_controller.change_3d_scene("res://scenes/main.tscn", true, false, true)
		"MainMenuButton":
			GlobalController.game_controller.change_3d_scene("res://main_menu_3d.tscn", true, false)
		"QuitButton":
			get_tree().quit()

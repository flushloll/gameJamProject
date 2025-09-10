extends Control

@onready var arrow = $Arrow
@onready var options = $VBoxContainer.get_children()  # Panels
@onready var music = $MainMenuMusic  # <- your AudioStreamPlayer node
@onready var chickenSquawk = $ChickenSquawk
@onready var selectionAudio = $SelectOptionSFX
var current_index = 0
var arrow_offset = Vector2(80, 45) # Adjust as needed
@onready var locked = false

var target_position: Vector2
var smoothing_speed := 8.0  # higher = faster, lower = slower

var bounce_amplitude := 1.2   # how far left/right it moves
var bounce_speed := 4.0       # how fast it wiggles
var time_passed := 0.0

func _ready():
	call_deferred("update_arrow_position")
	target_position = arrow.global_position
	
	# Start music with fade in
	music.volume_db = -40.0  # very quiet start
	music.play()
	var tween = create_tween()
	tween.tween_property(music, "volume_db", 0.0, 2.0) # fade to normal volume in 2 seconds

func _input(event):
	if event.is_action_pressed("ui_down") and not locked:
		current_index = (current_index + 1) % options.size()
		update_arrow_position()
		$ChangeSelectionSFX.pitch_scale = randf_range(0.97, 1.03)
		$ChangeSelectionSFX.play()
	elif event.is_action_pressed("ui_up") and not locked:
		current_index = (current_index - 1 + options.size()) % options.size()
		update_arrow_position()
		$ChangeSelectionSFX.pitch_scale = randf_range(0.97, 1.03)
		$ChangeSelectionSFX.play()
	elif event.is_action_pressed("ui_accept") and not locked and current_index == 0:
		select_option()
		locked = true

func _process(delta):
	
	if locked == true:
		smoothing_speed = 8.0  # higher = faster, lower = slower
		bounce_amplitude = 0.2  # how far left/right it moves
		bounce_speed = 8.0       # how fast it wiggles
	
	time_passed += delta
	
	# Smoothly move the arrow towards the target position
	arrow.global_position = arrow.global_position.lerp(target_position, smoothing_speed * delta)
	
	# Apply passive horizontal bounce
	var bounce = sin(time_passed * bounce_speed) * bounce_amplitude
	arrow.global_position.x += bounce
		

func update_arrow_position():
	var panel = options[current_index]
	target_position = panel.get_global_position() + Vector2(panel.size.x, 0) + arrow_offset
	
	# Reset bounce when switching options
	time_passed = 0.0

func select_option():
	# Fade out music
	var tween = create_tween()
	tween.tween_property(music, "volume_db", -40.0, 1.5) # fade out over 1.5s
	#chickenSquawk.play(0.1)
	selectionAudio.play()
	
	var egg = $"../EggNode3D"
	egg.visible = true
	egg.target = get_viewport().get_camera_3d()
	egg.on_hit_callback = Callable(self, "_on_egg_hit")
	
func _on_egg_hit():
	# Show omelette overlay
	var omelette = $OmeletteTextureRect
	omelette.visible = true
	omelette.modulate.a = 1.0
	omelette.show_omelette()

func _do_scene_change():
	match current_index:
		0:
			print("Start Game")
			#GlobalController.game_controller.change_3d_scene("res://scenes/main.tscn", true)
			#GlobalController.game_controller.change_gui_scene("null", true)
		1:
			print("Options")
		2:
			print("Quit Game")

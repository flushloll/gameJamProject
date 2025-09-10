extends Control

#@export var load_scene : PackedScene # Cannot use a packed scene as a path
@export var in_time : float = 0.5
@export var fade_in_time : float = 1.5
@export var pause_time : float = 1.5
@export var fade_out_time : float = 1.5
@export var out_time : float = 0.5
@export var splash_screen : TextureRect
@export var splash_screen_container: Node
@onready var firstScene = "res://main_menu_3d.tscn"
@onready var dogBark = $dogBarkPlayer
@onready var retroArcadeSound = $retroArcadeSoundPlayer

var splash_screens : Array

func fade() -> void:
	playDogBark()
	playRetroArcadeWindUp()
	for screen in splash_screens:
		screen.modulate.a = 0.0
		var tween = self.create_tween()
		tween.tween_interval(in_time)
		tween.tween_property(screen, "modulate:a", 1.0, fade_in_time)
		tween.tween_interval(pause_time)
		tween.tween_property(screen, "modulate:a", 0.0, fade_out_time)
		tween.tween_interval(out_time)
		await tween.finished
	GlobalController.game_controller.change_3d_scene(firstScene)
	GlobalController.game_controller.change_gui_scene("null", true)

func _ready() -> void:
	get_screens()
	fade()
	
func get_screens() -> void:
	splash_screens = splash_screen_container.get_children()
	for screen in splash_screens:
		screen.modulate.a = 0.0

func playDogBark():
	await get_tree().create_timer(2).timeout
	dogBark.play()

func playRetroArcadeWindUp():
	await get_tree().create_timer(2).timeout
	retroArcadeSound.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		#get_tree().change_scene_to_packed(load_scene) #Used to cycle between splashcreens
		GlobalController.game_controller.change_3d_scene(firstScene, true, false, true, "Fade In", "Fade Out", 0.1)
		GlobalController.game_controller.change_gui_scene("null", true)

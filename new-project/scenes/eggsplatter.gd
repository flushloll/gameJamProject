extends TextureRect

@onready var alreadyDone = false
@onready var cam = $"../../Camera3D"

func show_omelette():
	if alreadyDone == false:
		visible = true
		modulate.a = 0.8
		$"../EggSplatSound".play()
		print(str(cam))
		cam.shake(5, 5) # intensity, duration
		alreadyDone = true
		await get_tree().create_timer(1).timeout
		fade_out_and_hide()

func fade_out_and_hide():
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5) # fade alpha to 0
	tween.tween_callback(Callable(self, "hide"))
	await tween.finished
	GlobalController.game_controller.change_3d_scene("res://scenes/main.tscn", true, false, true, "MenuToGameIn", "MenuToGameOut")

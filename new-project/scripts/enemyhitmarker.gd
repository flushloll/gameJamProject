extends Node3D

@export var move_speed: float = 2.0
@export var life_time: float = 10
@export var fade_time: float = 5
@onready var cam = get_node("/root/Main/SubViewportContainer/SubViewport/Player/Camera3D")
@onready var DamageLabel = $DamageLabel

var timer: float = 0.0

func display_damage(amount):
	timer = 0.0
	DamageLabel.modulate.a = 1.0
	if str(amount) != "KILL":
		DamageLabel.modulate = Color(
		randi_range(180, 255) / 255.0, # red
		randi_range(100, 255) / 255.0, # green
		randi_range(80, 255) / 255.0,  # blue
		1.0
		)
		DamageLabel.outline_modulate = Color("e39b56")
	else:
		DamageLabel.outline_modulate = Color(randi_range(172, 202) / 255.0, randi_range(110,140) / 255.0, randi_range(53,83) / 255.0)
		DamageLabel.modulate = Color(randi_range(152,182) / 255.0, randi_range(139,169) / 255.0, randi_range(71,101) / 255.0)
	
	DamageLabel.text = str(amount)
	DamageLabel.visible = true
	DamageLabel.position = Vector3(0, 2, 0) # reset to above enemy

func _process(delta):
	if not DamageLabel.visible:
		return

	DamageLabel.translate(Vector3(0, move_speed * delta, 0)) #float upwards
	DamageLabel.look_at(cam.global_position, Vector3.UP, true)

	if timer > life_time:
		DamageLabel.modulate.a -= delta / fade_time
		if DamageLabel.modulate.a <= 0:
			DamageLabel.visible = false

	timer += delta

extends Camera3D

@export var randomStrength: float = 0.2  # subtle shake
@export var shakeFade: float = 5.0

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0
var original_local_position: Vector3
var can_shake = true
var camera_rot_tempSaved

func _ready():
	original_local_position = transform.origin  # store local position
	
func apply_shake(shakeStrengthBasedOnInput):
	shakeStrengthBasedOnInput = str(shakeStrengthBasedOnInput)
	if shakeStrengthBasedOnInput == "1":
		shake_strength = randomStrength
	elif shakeStrengthBasedOnInput == "stomp":
		shake_strength = randomStrength * 3.3
		

func _process(delta):
	if Input.is_action_just_pressed("attack") and Global.WeaponTypeNameGlobal == "BaseWeapon" and can_shake:
		can_shake = false
		await get_tree().create_timer(0.58).timeout
		apply_shake(1)
		await get_tree().create_timer(1 - 0.58).timeout
		can_shake = true
		
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		var offset = random_offset()
		var new_transform = transform
		new_transform.origin = original_local_position + offset
		transform = new_transform
	else:
		# ensure camera returns to local origin
		var new_transform = transform
		new_transform.origin = original_local_position
		transform = new_transform

func random_offset() -> Vector3:
	return Vector3(
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength)
	)

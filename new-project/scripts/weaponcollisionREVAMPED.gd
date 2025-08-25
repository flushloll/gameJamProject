extends CollisionShape3D  # Or Area3D if you want the swing detection there

@onready var animation_player: AnimationPlayer = $"../../../../../PlayerAnimationPlayer"
var swinging
@onready var player: CharacterBody3D = $"../../../../.."
@onready var WeaponAreaShape3D: Area3D = $".."
#@onready var whooshSoundReference = $"../../../../../../WhooshSound"

var swingSoundPlaying

var can_doDamage = true
var weapon_damage

# func _ready() -> void:
		
func _process(delta):
	if Input.is_action_just_pressed("attack"):
		start_swing()

func attack() -> void:
	can_doDamage = false
	weapon_damage = Global.WeaponDamage * randf_range(1.7, 2.8)
	
	for body in WeaponAreaShape3D.get_overlapping_bodies():
		if body.is_in_group("Enemies"):
			body.take_damage(weapon_damage)
			
	await get_tree().create_timer(Global.WeaponCollisionCooldown).timeout
	can_doDamage = true
	
# Called by the player when attack input is detected
func start_swing():
	#whooshSoundReference.start_whoosh_sound()
	animation_player.play("swinganim")
	await get_tree().create_timer(0.63).timeout
	if can_doDamage:
		attack()
	

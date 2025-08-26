extends CollisionShape3D  # Or Area3D if you want the swing detection there

@onready var animation_player: AnimationPlayer = $"../../../../../PlayerAnimationPlayer"
var swinging
@onready var player: CharacterBody3D = $"../../../../.."
@onready var WeaponAreaShape3D: Area3D = $".."
#@onready var whooshSoundReference = $"../../../../../../WhooshSound"
@onready var weaponNode = %Weapon

var swingSoundPlaying

var can_swing = true
var weapon_damage
var weaponTypeName
# func _ready() -> void:

@export var reserve_ammo: int = 30
@export var current_ammo: int = 30
@export var mag_size: int = 30

@export var shoot_delay : float = 1.0
@export var reload_time : float = 2.0
var shoot_timer_time : float
var reload_timer_time : float

var is_reloading : bool
var can_shoot: bool = true

#var gui
var ammo_text

@onready var shoot_cast : RayCast3D = $ShootCast
		
func _ready():
	#gui = $UI
	#ammo_text = gui.get_node("AmmoCounter")
	#current_ammo = reserve_ammo
	
	shoot_timer_time = shoot_delay
	shoot_timer_time = reload_time
	print(can_reload())
		
func _process(delta):
	weaponTypeName = weaponNode.WEAPON_TYPE.name
	if Input.is_action_just_pressed("attack"):
		start_attack_animation()
	
	if is_reloading == false:
		ammo_text.text = str(str(current_ammo) + "/" + str(reserve_ammo))
	elif is_reloading == true:
		ammo_text.text = str("RELOADING...")
		reset_reload(delta)
		is_reloading = false
		pass
	
	if current_ammo_depleted() == true and can_reload() == true:
		reload_weapon()
	
	if can_shoot == false:
		reset_shoot(delta)
	
func attack() -> void:
	can_swing = false
	weapon_damage = Global.WeaponDamage * randf_range(1.7, 2.8)
	
	for body in WeaponAreaShape3D.get_overlapping_bodies():
		if body.is_in_group("Enemies"):
			body.take_damage(weapon_damage)
			
	await get_tree().create_timer(Global.WeaponCollisionCooldown).timeout
	can_swing = true
	
# Called by the player when attack input is detected
func start_attack_animation():
	
	if weaponTypeName == "BaseWeapon":
	#whooshSoundReference.start_whoosh_sound()
		animation_player.play("swinganim")
		await get_tree().create_timer(0.58).timeout
		if can_swing:
			attack()
	elif weaponTypeName == "FirstGun" and no_more_ammo() == false and can_shoot == true and not is_reloading:
		shoot()

func can_reload():
	return reserve_ammo > 0

func current_ammo_depleted():
	return current_ammo > 0

func reserve_ammo_depleted():
	return reserve_ammo <= 0

func no_more_ammo():
	if reserve_ammo_depleted() and current_ammo_depleted():
		return true
	else:
		return false
		
func shoot():
	can_shoot = false
	current_ammo -= 1
	if shoot_cast.is_colliding():
		pass
		
func reset_shoot(delta):
	shoot_timer_time -= delta
	if shoot_timer_time <= 0:
		can_shoot = true
		shoot_timer_time = shoot_delay

func reset_reload(delta):
	reload_timer_time -= delta
	if reload_timer_time <= 0:
		current_ammo = reserve_ammo
		reserve_ammo -= mag_size
		is_reloading = false
		reload_timer_time = reload_time

func reload_weapon():
	is_reloading = true
	

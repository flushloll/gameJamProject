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
@onready var gui = $"../../../../../../UI"

var is_reloading : bool
var can_shoot: bool = true

#var gui
var ammo_text

@onready var shoot_cast : RayCast3D = $"../../../../../ShootCast"

func _ready():
	ammo_text = gui.get_node("AmmoCounter")
	current_ammo = reserve_ammo
	
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
		print("HasShot")

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
	
	var camera : Camera3D = $"../../../../../Camera3D"
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var ray_target = ray_origin + ray_dir * 1000  # Ray length

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
	query.collision_mask = 1

	var result = space_state.intersect_ray(query)
	can_shoot = false
	current_ammo -= 1
	if result:
		var collider = result.collider
		if collider and collider.has_method("take_damage"):
			collider.take_damage(weapon_damage)
			print("Hit enemy: ", collider.name)
		else:
			print("Hit something else: ", result.position)
	else:
		print("Missed")
		
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
	

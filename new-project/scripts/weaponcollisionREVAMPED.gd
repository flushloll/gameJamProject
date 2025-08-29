extends CollisionShape3D  # Or Area3D if you want the swing detection there

@onready var animation_player: AnimationPlayer = %PlayerAnimationPlayer
var swinging
@onready var player: CharacterBody3D = $"../../../../../.."
@onready var WeaponAreaShape3D: Area3D = $".."
#@onready var whooshSoundReference = $"../../../../../../WhooshSound"
@onready var weaponNode = %Weapon
@onready var weaponMesh = $"../../WeaponMesh"

var swingSoundPlaying

var can_swing = true
var weaponTypeName
# func _ready() -> void:

@export var reserve_ammo: int = 72
@export var current_ammo: int = 6
@export var mag_size: int = 6

@export var shoot_delay : float = Global.WeaponCollisionCooldown
@export var reload_time : float = 2.0
var reload_timer_time : float
@onready var gui = $"../../../../../../../../../UI"
@onready var shoot_cast = $"../../../../../../ShootCast"
@onready var laserbeam = $"../../../../../../LaserBeam"

var is_reloading : bool
var can_shoot: bool = true
var reload_timer: float = 0.0
@onready var shootsfx = $"../../../../../../../../../ShootSfx"
@onready var reloadsfx = $"../../../../../../../../../ReloadSfx"
@onready var swingsfx = $"../../../../../../../../../SwingSfx"
@onready var errorreloadsfx = $"../../../../../../../../../ErrorReloadSfx"

var ammo_text

func _ready():
	WeaponAreaShape3D.connect("body_entered", Callable(gui, "_on_sword_body_entered"))
	WeaponAreaShape3D.connect("body_exited", Callable(gui, "_on_sword_body_exited"))
	
	ammo_text = gui.get_node("AmmoCounter")
	current_ammo = mag_size
	ammo_text.text = "%d/%d" % [current_ammo, reserve_ammo]
	
	print(can_reload())
		
func _process(delta):
	weaponTypeName = Global.WeaponTypeNameGlobal
	if Input.is_action_just_pressed("attack"):
		start_attack_animation()
	if Input.is_action_just_pressed("reload") and weaponTypeName == "FirstGun":
		reload_weapon()
	
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			finish_reload()
			ammo_text.text = "%d/%d" % [current_ammo, reserve_ammo]
	
	if current_ammo_depleted() == true and can_reload() == true:
		reload_weapon()
	
func attack() -> void:
	can_swing = false
	Global.WeaponDamage = randomWeaponDamage()
	swingsfx.play()
	
	for body in WeaponAreaShape3D.get_overlapping_bodies():
		if body.is_in_group("Enemies"):
			body.take_damage()
			
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
	elif weaponTypeName == "FirstGun" and no_more_ammo() == false and can_shoot == true:
		animation_player.stop()
		weaponMesh.position = Vector3()
		shoot()
		print("HasShot")

func can_reload():
	return reserve_ammo > 0 and current_ammo < mag_size

func current_ammo_depleted():
	return current_ammo <= 0

func reserve_ammo_depleted():
	return reserve_ammo <= 0

func no_more_ammo():
	return reserve_ammo <= 0 and current_ammo <= 0
		
func shoot():
	
	#var GunCamera : Camera3D = $"../.."
	#var mouse_pos = get_viewport().get_mouse_position()
	#var ray_origin = GunCamera.project_ray_origin(mouse_pos)
	#var ray_dir = GunCamera.project_ray_normal(mouse_pos)
	#var ray_target = ray_origin + ray_dir * 1000  # Ray length
	
	#if Engine.has_singleton("DebugDraw3D"):
		#DebugDraw3D.draw_line(shoot_cast.x, shoot_cast.y, Color.RED, 0.15)
	if is_reloading:
		is_reloading = false
		if current_ammo <= 0:
			errorreloadsfx.play()
			return
		else:
			return  # cancel reload if player shoots		
	if not can_shoot or no_more_ammo():
		return  # can't shoot right now
	
	can_shoot = false
	#
	#var origin = shoot_cast.global_position
#
## Calculate the target point (direction * length)
	#var length = 1000  # max ray distance
	#var direction = shoot_cast.global_transform.basis.z.normalized() * -1  # -Z is forward in Godot 4
	#var target = origin + direction * length
#
	#if shoot_cast.is_colliding():
		#target = shoot_cast.get_collision_point()
#
	#laserbeam.show_laser(origin, target)
#
	animation_player.play("shootrevolver")
	current_ammo -= 1
	shootsfx.play()
	ammo_text.text = "%d/%d" % [current_ammo, reserve_ammo]
	
	if shoot_cast.is_colliding():
		var collider = shoot_cast.get_collider()
		Global.collider = shoot_cast.get_collider()
		
		while collider and not collider.is_in_group("Enemies") and collider.get_parent() != null:
			collider = collider.get_parent()
		
		if collider and collider.has_method("take_damage"):
			Global.WeaponDamage = randomWeaponDamage()
			collider.take_damage()
			print("Hit enemy: ", collider.name)
		else:
			print("Hit something else: ", shoot_cast.get_collision_point())
	else:
		print("Missed")
	
	reset_shoot()
		
func reset_shoot():
	await get_tree().create_timer(Global.WeaponCollisionCooldown).timeout
	can_shoot = true

func reload_weapon():
	if not is_reloading and can_reload():
		is_reloading = true
		reload_timer = reload_time
		reloadsfx.play()
		ammo_text.text = "RELOADING..."
		await get_tree().create_timer(reload_time).timeout
		
func finish_reload():
	var ammo_needed = mag_size - current_ammo
	var ammo_to_load = min(ammo_needed, reserve_ammo)
	current_ammo += ammo_to_load
	reserve_ammo -= ammo_to_load
	is_reloading = false

func randomWeaponDamage():
	var randomGeneratedWeaponDamage
	if weaponTypeName == "FirstGun":
		randomGeneratedWeaponDamage = 47 * randf_range(1.7, 2.8)
		return randomGeneratedWeaponDamage
	elif weaponTypeName == "BaseWeapon":
		randomGeneratedWeaponDamage = 41 * randf_range(1.7, 2.8)
		return randomGeneratedWeaponDamage
	
	

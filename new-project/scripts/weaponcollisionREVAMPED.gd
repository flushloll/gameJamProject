extends CollisionShape3D  # Or Area3D if you want the swing detection there

@onready var animation_player: AnimationPlayer = %PlayerAnimationPlayer
var swinging
@onready var player: CharacterBody3D = $"../../../../../.."
@onready var WeaponAreaShape3D: Area3D = $".."
#@onready var whooshSoundReference = $"../../../../../../WhooshSound"
@onready var weaponNode = %Weapon
@onready var weaponMesh = $"../../WeaponVisualRoot/WeaponMesh"

var swingSoundPlaying

var weaponTypeName
# func _ready() -> void:

@export var reserve_ammo: int = 72
@export var current_ammo: int = 6
@export var mag_size: int = 6

@export var shoot_delay : float = Global.WeaponCollisionCooldown
@export var reload_time : float = 0.7
var reload_timer_time : float
@onready var gui = $"../../../../../../../UI"
@onready var shoot_cast = $"../../../../../../ShootCast"
@onready var FPS_shoot_cast = $"../../../FPSCast"

var is_reloading : bool
var can_shoot: bool = true
var reload_timer: float = 0.0
@onready var shootsfx = $"../../../../../../../ShootSfx"
@onready var reloadsfx = $"../../../../../../../ReloadSfx"
@onready var swingsfx = $"../../../../../../../SwingSfx"
@onready var swingsfxRightClick = $"../../../../../../../SwingSfxRightClick"
@onready var errorreloadsfx = $"../../../../../../../ErrorReloadSfx"

var ammo_text

@onready var weaponDamageScaleSword: int
@onready var weaponDamageScaleGun: int
var swingSequence = 1
@onready var slash_particle0 = $"../../WeaponVisualRoot/WeaponMesh/SwordSlashParticle"
@onready var slash_particle1 = $"../../WeaponVisualRoot/WeaponMesh/SwordSlashParticle/GPUParticles3D2"
@onready var slash_particle2 = $"../../WeaponVisualRoot/WeaponMesh/SwordSlashParticle/GPUParticles3D3"
@onready var slash_particle3 = $"../../WeaponVisualRoot/WeaponMesh/SwordSlashParticle/GPUParticles3D4"
@onready var tween := create_tween()
var air_control: float = 12.0  # default
var base_air_control: float = 52.0
var reduced_air_control: float = 12.0
@onready var shotgun = true
@onready var ShotgunRange = $"../../ShotgunRange"
		# 🔹 Apply knockback to player (opposite of shot direction)
@export var default_knockback_strength = 128
var knockback_strength = default_knockback_strength  # tweak this value
@onready var knockbackCooldown = false

func _ready():
	WeaponAreaShape3D.connect("body_entered", Callable(gui, "_on_sword_body_entered"))
	WeaponAreaShape3D.connect("body_exited", Callable(gui, "_on_sword_body_exited"))
	
	ammo_text = gui.get_node("AmmoCounter")
	current_ammo = mag_size
	ammo_text.text = "%d/%d" % [current_ammo, reserve_ammo]
	
	weaponMesh.position = Vector3(0.349, -0.045, -0.389)
	weaponMesh.rotation_degrees = Vector3(-90.0, -12.1, 7.5)
	
	slash_particle0.emitting = false
	slash_particle1.emitting = false
	slash_particle2.emitting = false
	slash_particle3.emitting = false
	
	print(can_reload())
		
func _process(delta):
	weaponTypeName = Global.WeaponTypeNameGlobal
	if Input.is_action_just_pressed("attackRightClick"):
		var clickType = 2 #rightClick
		start_attack_animation(clickType)
	if Input.is_action_just_pressed("attackLeftClick"):
		var clickType = 1 #rightClick
		start_attack_animation(clickType)
	if Input.is_action_just_pressed("reload") and weaponTypeName == "FirstGun":
		reload_weapon()
	
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			finish_reload()
			ammo_text.text = "%d/%d" % [current_ammo, reserve_ammo]
	
	if current_ammo_depleted() == true and can_reload() == true:
		reload_weapon()
		
func swingsfxplay():
	swingsfx.play()

func swingsfxplayRightClick():
	swingsfxRightClick.play()
	
func enemiestakedamageSword(weaponDamageScaleSword):
	Global.WeaponDamage = randomWeaponDamage(weaponDamageScaleSword)
	for body in WeaponAreaShape3D.get_overlapping_bodies():
		if body.is_in_group("Enemies") and Global.WeaponTypeNameGlobal == "BaseWeapon":
			body.take_damage()
	
# Called by the player when attack input is detected
func start_attack_animation(clickType):
	if weaponTypeName == "BaseWeapon":
		Global.can_switch = false
		if clickType == 2 and Global.can_swing:
			swingsfxRightClick.pitch_scale = randf_range(1.1, 1.3)
			animation_player.play("swinganimRightClick")
		elif clickType == 1 and Global.can_swing:
			swingsfx.pitch_scale = randf_range(0.9, 1.1)
			animation_player.play("swinganimLeftClick" + str(swingSequence))
			print("swinganimLeftClick" + str(swingSequence))
			swingSequence += 1
			if swingSequence == 4:
				swingSequence = 1
	elif weaponTypeName == "FirstGun" and no_more_ammo() == false and can_shoot == true:
		if clickType == 1:
			animation_player.stop()
			weaponMesh.position = Vector3()
			var weaponDamageScaleGun = 0.2
			shoot(weaponDamageScaleGun)
			print("HasShot")
		elif clickType == 2:
			# 🔹 Calculate shot direction
			var direction = -$"../../..".global_transform.basis.z.normalized()
			apply_knockback_cooldown(direction)

func can_reload():
	return reserve_ammo > 0 and current_ammo < mag_size

func current_ammo_depleted():
	return current_ammo <= 0

func reserve_ammo_depleted():
	return reserve_ammo <= 0

func no_more_ammo():
	return reserve_ammo <= 0 and current_ammo <= 0
		
func shoot(weaponDamageScaleGun):
	
	if is_reloading:
		if current_ammo <= 0:
			errorreloadsfx.play()
			return
		else:
			return  # cancel reload if player shoots		
	if not can_shoot or no_more_ammo():
		return  # can't shoot right now
	
	player.apply_shake(1/14.0)
	can_shoot = false

	var directionShoot = -$"../../..".global_transform.basis.z.normalized()
	var recoil_strength: float = 12.0  # tweak this
	player.velocity -= directionShoot * recoil_strength

	animation_player.play("shootShotgun")
	shootsfx.play()
	current_ammo -= 1
	ammo_text.text = "%d/%d" % [current_ammo, reserve_ammo]

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(player, "air_control", reduced_air_control, 0.15) \
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.25)  # how long it stays low
	tween.tween_property(player, "air_control", base_air_control, 0.5) \
	
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if weaponTypeName == "Revolver":
		handleRevolverShots(weaponDamageScaleGun)
	elif weaponTypeName == "FirstGun":
		handleShotgunShots(weaponDamageScaleGun)
	
	reset_shoot()
		
func reset_shoot():
	await get_tree().create_timer(Global.WeaponCollisionCooldown).timeout
	can_shoot = true

func handleRevolverShots(weaponDamageScaleGun):
	if shoot_cast.is_colliding and Global.cameraFollowsCursor:
		var collider = shoot_cast.get_collider()
		Global.collider = shoot_cast.get_collider()
		
		while collider and not collider.is_in_group("Enemies") and collider.get_parent() != null:
			collider = collider.get_parent()
		
		if collider and collider.has_method("take_damage"):
			Global.WeaponDamage = randomWeaponDamage(weaponDamageScaleGun)
			collider.take_damage()
			print("Hit enemy: ", collider.name)
		else:
			print("Hit something else TOP: ", shoot_cast.get_collision_point())
	elif FPS_shoot_cast.is_colliding() and not Global.cameraFollowsCursor:
		var colliderFPS = FPS_shoot_cast.get_collider()
		Global.collider = FPS_shoot_cast.get_collider()
		
		while colliderFPS and not colliderFPS.is_in_group("Enemies") and colliderFPS.get_parent() != null:
			colliderFPS = colliderFPS.get_parent()
	
		if colliderFPS and colliderFPS.has_method("take_damage"):
			Global.WeaponDamage = randomWeaponDamage(weaponDamageScaleGun)
			colliderFPS.take_damage()
			print("Hit enemy: ", colliderFPS.name)
		else:
			print("Hit something else FPS: ", FPS_shoot_cast.get_collision_point())
	
func handleShotgunShots(weaponDamageScaleGun):
	for body in ShotgunRange.get_overlapping_bodies():
		print (body.name)
		
		while body and not body.is_in_group("Enemies") and body.get_parent() != null:
			body = body.get_parent()
			
		if not body.is_in_group("Enemies"):
			continue
			
		#var distance = player.global_position.distance_to(body.global_position)
		#var max_range = 100.0
		#var min_damage = 5.0
		#var base_damage = weaponDamageScaleGun
#
		## Correct damage interpolation
		#var factor = clamp(1.0 - (distance / max_range), 0.0, 1.0)
		#var damage = min_damage + (base_damage - min_damage) * factor
		## OR using lerp:
		## var damage = lerp(min_damage, base_damage, factor)

		Global.WeaponDamage = randomWeaponDamage(weaponDamageScaleGun)
		body.take_damage()
		#print("Hit", body.name, "Distance:", distance, "Damage:", damage)


func reload_weapon():
	if not is_reloading and can_reload():
		is_reloading = true
		reload_timer = reload_time
		reloadsfx.play()
		ammo_text.text = "RELOADING..."
		await get_tree().create_timer(reload_time).timeout
		
func finish_reload():
	knockback_strength = default_knockback_strength
	var ammo_needed = mag_size - current_ammo
	var ammo_to_load = min(ammo_needed, reserve_ammo)
	current_ammo += ammo_to_load
	reserve_ammo -= ammo_to_load
	is_reloading = false

func randomWeaponDamage(weaponDamageScale):
	var randomGeneratedWeaponDamage
	if weaponTypeName == "FirstGun":
		randomGeneratedWeaponDamage = 47 * randf_range(1.7, 2.8) * weaponDamageScale
	elif weaponTypeName == "BaseWeapon":
		randomGeneratedWeaponDamage = 41 * randf_range(1.7, 2.8) * weaponDamageScale
	else:
		randomGeneratedWeaponDamage = 10 * weaponDamageScale # fallback
	return randomGeneratedWeaponDamage
	
	
func canSwingAgain():
	if Global.can_swing == true:
		Global.can_swing = false
		Global.can_switch = false
	else:
		Global.can_switch = true
		Global.can_swing = true

func resetSwingSequence():
	swingSequence = 1

func emitRevolverParticle():
	$"../../WeaponVisualRoot/WeaponMesh/RevolverParticle".emitting = true
	$"../../WeaponVisualRoot/WeaponMesh/RevolverParticle".restart()

func emitSwordSlashParticle():
	slash_particle0.emitting = false
	slash_particle1.emitting = false
	slash_particle2.emitting = false
	slash_particle3.emitting = false
	
	slash_particle0.restart()
	slash_particle1.restart()
	slash_particle2.restart()
	slash_particle3.restart()
	
	slash_particle0.emitting = true
	slash_particle1.emitting = true
	slash_particle2.emitting = true
	slash_particle3.emitting = true
	
func apply_knockback_cooldown(direction: Vector3) -> void:
		# Set knockback really low for this shot
	var temp_knockback = knockback_strength * 0.06  # 25% of normal
	var attemptToResetSkill = true
	if knockbackCooldown:
		return
	else:
		knockbackCooldown = true
		player.velocity += -direction * temp_knockback
		player.is_knocked_back = true
		player.knockback_timer = 0.23
		player.apply_shake(temp_knockback / 16.0)
		# Wait 2 seconds before restoring knockback strength
	if attemptToResetSkill == true:
		await get_tree().create_timer(5.4).timeout
		knockback_strength = default_knockback_strength
		knockbackCooldown = false
		attemptToResetSkill = false

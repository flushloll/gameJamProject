extends CharacterBody3D

@onready var hitbox_area: Area3D = $EnemyHitBoxArea
@onready var enemyMesh: MeshInstance3D = $MeshInstance3D
@onready var enemycollisionshape: CollisionShape3D = $EnemyCollisionShape
@onready var animation_player: AnimationPlayer = $EnemyAnimationPlayer
@onready var navigation_agent = $NavigationAgent3D
@onready var enemy = $"."
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var speed = 5.0
@export var wander_radius = 6 # How far the NPC will wander from its starting point
@onready var player = get_node("/root/Main/SubViewportContainer/SubViewport/Player")
@onready var chickendeadsfx = get_node("/root/Main/ChickenDeadSfx")

@export var max_health: int = 100
var current_health: int
var is_dead: bool = false
var canMove: bool = true

func _ready():
	add_to_group("Enemy")
	set_new_random_target()
	current_health = max_health
	
func navigationCooldown():
	await get_tree().create_timer(randf_range(0.4,2)).timeout
	canMove = true

func cubeInput(x):
	var radius = pow(x, 1/3.0) * -40
	
	if sign(radius) == -1:
		var clampedRadius = clamp(-10,x,-2)
		return clampedRadius
	elif sign(radius) == 1:
		var clampedRadius = clamp(2,x,10)
		return clampedRadius
	elif sign(radius) == 0:
		var clampedRadius = 2
		return clampedRadius
	
func set_new_random_target():
	var signDifferenceBetweenPlayerAndEnemyX = sign(player.global_position.x - global_position.x) 
	var signDifferenceBetweenPlayerAndEnemyZ = sign(player.global_position.z - global_position.z) 
	
	var newX
	var newZ
	
	if signDifferenceBetweenPlayerAndEnemyX == 1:
		newX = cubeInput(randf_range((0 - wander_radius), 4))
	elif signDifferenceBetweenPlayerAndEnemyX == -1 or signDifferenceBetweenPlayerAndEnemyX == 0:
		newX = cubeInput(randf_range(-4, wander_radius))
		
	if signDifferenceBetweenPlayerAndEnemyZ == 1:
		newZ = cubeInput(randf_range(0 - wander_radius, 4))
	elif signDifferenceBetweenPlayerAndEnemyZ == -1 or signDifferenceBetweenPlayerAndEnemyZ == 0:
		newZ = cubeInput(randf_range(-4, wander_radius))
	
	navigation_agent.target_position = Vector3(global_position.x + newX, 0, global_position.z + newZ)
	
func _physics_process(delta: float) -> void:
	
	var next_position = navigation_agent.get_next_path_position()
	
	if velocity.length() > 0.1:  # Only rotate if moving\
		var move_dir = Vector3(velocity.x, 0, velocity.z).normalized()
		var target_rotation = atan2(-move_dir.x, -move_dir.z)  # Yaw angle in radians
	# Smoothly rotate the mesh
		var current_rotation = enemyMesh.rotation.y
		enemyMesh.rotation.y = lerp_angle(current_rotation, target_rotation, 0.1)  # 0.1 = rotation speed
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if absf(velocity.y) < 0.01:
			velocity.y = 0.0
			
	if next_position != Vector3.ZERO:
		var direction = (next_position - global_position).normalized()
		
		if canMove:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		if canMove and global_position.distance_to(navigation_agent.target_position) < 1.0:
			canMove = false
			velocity.x = 0
			velocity.z = 0
			navigationCooldown()
			set_new_random_target()
	else:
		# Stop moving if no path
		velocity.x = 0
		velocity.z = 0
		
	move_and_slide()
		
			
func take_damage():
	if is_dead:
		return
	#playerCamera.add_trauma(0.4)  # Amount between 0.1 (light) and 1.0 (extreme)
	flash_red()
	current_health -= Global.WeaponDamage
	print("%s took %d damage. Health: %d" % [name, Global.WeaponDamage, current_health])

	if current_health <= 0:
		die()
		
func die():
	if is_dead:
		return
	is_dead = true
	chickendeadsfx.play()
	# animation_player.play("Death")
	set_physics_process(false)
	# animation_player.animation_finished.connect(_on_death_animation_finished)
	queue_free() # REMOVE THIS AFTER DEATH ANIMATION IS ADDED
		
func flash_red():
	var original = $MeshInstance3D.get_surface_override_material(0)
	if original == null:
		original = $MeshInstance3D.mesh.surface_get_material(0)
	var flash = original.duplicate()
	flash.albedo_color = Color(1, 0, 0)
	enemyMesh.material_override = flash
	await get_tree().create_timer(0.15).timeout
	enemyMesh.material_override = original

# Enemy detects collisions with weapons

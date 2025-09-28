extends CharacterBody3D

@onready var enemyMesh: MeshInstance3D = $chicken4/chicken_0012/Skeleton3D/chicken_001
@onready var enemycollisionshape: CollisionShape3D = $EnemyCollisionShape
@onready var animation_player: AnimationPlayer = $chicken4/AnimationPlayer
@onready var navigation_agent = $NavigationAgent3D
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var speed = 8.0
@export var wander_radius = 6 # How far the NPC will wander from its starting point
@onready var player = $"../SubViewportContainer/SubViewport/Player"
@onready var chickendeadSfx = $"../SubViewportContainer/SubViewport/ChickenDeadSfx"
@onready var spawn_sound = $SpawnSound
@onready var feathers = $FeathersParticle
@onready var ImpactSoundSfx = $"../SubViewportContainer/SubViewport/ImpactSfx"
@onready var animation_tree: AnimationTree = $chicken4/AnimationTree
@onready var animation_state_machine_node = animation_tree.get("parameters/playback")
@export var max_health: int = 100
@onready var enemyDamageScale: float = 1

@export var rotation_speed: float = 8.0            # how fast the enemy turns (higher = snappier)
@export var rotation_offset_degrees: float = 0.0   # use 180 if your model faces the other way
@export var face_threshold: float = 0.05           # minimum horizontal length to face (avoids jitter)

var chasing_player: bool = false
var navigation_paused: bool = false

var current_health: int
var is_dead: bool = false
var canMove: bool = true
signal enemy_died

var stomped_this_frame = false
var pecking: bool = false
@onready var PeckingSfx = $"../SubViewportContainer/SubViewport/PeckingSfx"
@onready var ChickenMissSfx = $"../SubViewportContainer/SubViewport/ChickenMissSfx"
var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
@onready var playerdamageCooldownBool: bool = false
@onready var inventory = $"../SubViewportContainer/SubViewport/UI/Inventory"

# cached safe velocity received from NavigationAgent3D
var agent_safe_velocity: Vector3 = Vector3.ZERO

func _ready():
	add_to_group("Enemy")
	set_new_random_target()
	current_health = max_health
	feathers.emitting = false
	$WanderTimer.start()

	# ensure avoidance is enabled (you can also toggle this in the Inspector)
	navigation_agent.avoidance_enabled = true
	
func navigationCooldown():
	await get_tree().create_timer(randf_range(0.4,3)).timeout
	canMove = true

func _face_direction(direction: Vector3, delta: float) -> void:
	direction.y = 0
	if direction.length() <= face_threshold:
		return
	var dir_norm = direction.normalized()
	# If your model's forward is -Z (usual Godot), this works. Adjust rotation_offset_degrees if needed.
	var target_yaw = atan2(-dir_norm.x, -dir_norm.z) + deg_to_rad(rotation_offset_degrees)
	rotation.y = lerp_angle(rotation.y, target_yaw, clamp(delta * rotation_speed, 0.0, 1.0))

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

func _process(delta):
		# update animation tree (same logic you had before)
	if animation_tree:
		var current_state = animation_state_machine_node.get_current_node()
		
		if current_state != "chickenPeck" and pecking:
		# just exited peck animation
			pecking = false
			
		horizontal_speed = Vector3(velocity.x, 0, velocity.z).length() 
		# getting the velocity and returning it's magnitude (or length) as speed because speed is the magnitude of velocity
		
		animation_tree.set("parameters/conditions/isWalking", horizontal_speed > 0.1 and not pecking)
		animation_tree.set("parameters/conditions/walkingToIdle", horizontal_speed <= 0.1 and not pecking)
		animation_tree.set("parameters/conditions/peckingToIdle", horizontal_speed <= 0.1 and pecking)
		animation_tree.set("parameters/conditions/peckingToWalking", horizontal_speed > 0.1 and pecking)
	
# --- physics process: unified movement + rotation logic ---
func _physics_process(delta: float) -> void:
	stomped_this_frame = false

	# --- gravity (unchanged) ---
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if absf(velocity.y) < 0.01:
			velocity.y = 0.0

	# Build the desired horizontal velocity (what we want to do, pre-avoidance)
	var desired_velocity: Vector3 = Vector3.ZERO

	if chasing_player and canMove and not pecking:
		var to_player = player.global_position - global_position
		_face_direction(to_player, delta)
		# horizontal only
		to_player.y = 0
		if to_player.length() > 0.001:
			desired_velocity = to_player.normalized() * speed
		if global_position.distance_to(player.global_position) < 1.0:
			startPecking()
			animation_state_machine_node.travel("chickenPeck")
	else:
		var next_position = Vector3.ZERO
		if not navigation_paused:
			next_position = navigation_agent.get_next_path_position()

		if next_position != Vector3.ZERO:
			var path_dir = next_position - global_position
			_face_direction(path_dir, delta)

			if canMove:
				desired_velocity = Vector3(path_dir.x, 0, path_dir.z).normalized() * speed

			# still keep your "reached target" logic
			if canMove and global_position.distance_to(navigation_agent.target_position) < 1.0:
				canMove = false
				# stop asking for movement
				desired_velocity = Vector3.ZERO
				velocity.x = 0
				velocity.z = 0
				navigationCooldown()
				set_new_random_target()
				$WanderTimer.wait_time = randf_range(5.0, 8.0)
				$WanderTimer.start()
		else:
			desired_velocity = Vector3.ZERO
			pecking = false

	# Tell the NavigationAgent what we want it to try to do.
	# The agent will compute a safe_velocity and emit velocity_computed.
	navigation_agent.set_velocity(desired_velocity)

	# NOTE:
	# Do NOT call move_and_slide() here — movement will be applied in the velocity_computed callback below.
	# (If you prefer to keep move_and_slide in _physics_process, you can cache the safe velocity in the callback
	# and apply it here instead — either pattern is used in examples.) 


func stomp_take_damage():
	if stomped_this_frame:
		return false
	flash_red()
	var stompDeduction = randi_range(13, 25)
	current_health -= stompDeduction
	if current_health <= 0:
		die()
		return true
	else:
		$HitMarker.display_damage(stompDeduction)
		return false
			
func take_damage():
	if is_dead:
		return
	#playerCamera.add_trauma(0.4)  # Amount between 0.1 (light) and 1.0 (extreme)
	flash_red()
			
	if current_health >= 0 and Global.WeaponTypeNameGlobal == "BaseWeapon":
		ImpactSoundSfx.volume_db = randf_range(-13, -11.5)
		ImpactSoundSfx.pitch_scale = randf_range(0.8, 1.2)
		ImpactSoundSfx.play()
	else:
		pass
		
	current_health -= Global.WeaponDamage
	$HitMarker.display_damage(Global.WeaponDamage)
	print("%s took %d damage. Health: %d" % [name, Global.WeaponDamage, current_health])

	if current_health <= 0:
		die()
		
func die():
	if is_dead:
		return
	emit_signal("enemy_died", self)
	is_dead = true
	player.current_health += 5
	$HitMarker.display_damage("KILL")
	feathers.emitting = false   # reset
	feathers.restart()          # force restart if it was already used
	feathers.emitting = true    # now play once
	chickendeadSfx.play()
	$HealthBar.hide()
	var IngredientRandomChance = randi_range(0,10)
	if IngredientRandomChance >= 5:
		var selectRandomIngredientRoll = randi_range(1, 5)
		var randomIngredient
		if selectRandomIngredientRoll == 1:
			randomIngredient = load("res://ingredients/broccoli.tres")
		elif selectRandomIngredientRoll == 2:
			randomIngredient = load("res://ingredients/cabbage.tres")
		elif selectRandomIngredientRoll == 3:
			randomIngredient = load("res://ingredients/carrot.tres")
		elif selectRandomIngredientRoll == 4:
			randomIngredient = load("res://ingredients/potato.tres")
		elif selectRandomIngredientRoll == 5:
			randomIngredient = load("res://ingredients/tomato.tres")
		inventory.addIngredientToInventory(randomIngredient)
	# animation_player.play("Death")
	set_physics_process(false)
	# animation_player.animation_finished.connect(_on_death_animation_finished)
	enemyMesh.hide()
	$EnemyCollisionShape.hide()
	$StaticBody3D.hide()
	await get_tree().create_timer(1.6).timeout
	queue_free() # REMOVE THIS AFTER DEATH ANIMATION IS ADDED
	
		
func flash_red():
	var original = enemyMesh.get_surface_override_material(0)
	if original == null:
		original = enemyMesh.mesh.surface_get_material(0)
	var flash = original.duplicate()
	flash.albedo_color = Color(1, 0, 0)
	enemyMesh.material_override = flash
	await get_tree().create_timer(0.15).timeout
	enemyMesh.material_override = original
# Enemy detects collisions with weapons

func play_spawn_sound_and_effects():
	print("Playing spawn sound!")
	spawn_sound.play()

func _on_vision_timer_timeout() -> void:
	var overlaps = $EnemyVision.get_overlapping_bodies()
	var seen_player = false
	for overlap in overlaps:
		if overlap.is_in_group("Player"):
			var playerPosition = overlap.global_transform.origin
			$VisionRayCast.look_at(playerPosition, Vector3.UP)
			$VisionRayCast.force_raycast_update()
			if $VisionRayCast.is_colliding():
				var collider = $VisionRayCast.get_collider()
				if collider.is_in_group("Player"):
					seen_player = true
					break
	if seen_player:
		if not chasing_player:
			# start chase: pause navigation usage and lock on player
			chasing_player = true
			navigation_paused = true
			# prevent the agent from trying to walk somewhere while chasing
			navigation_agent.target_position = global_position
		$VisionRayCast.debug_shape_custom_color = Color(1, 0, 0)
	else:
		if chasing_player:
			# lost player -> resume navigation and pick a new nav target
			chasing_player = false
			navigation_paused = false
			set_new_random_target()
		$VisionRayCast.debug_shape_custom_color = Color(0, 1, 0)

func _on_wander_timer_timeout() -> void:
	#(velocity.x <= 0 or velocity.y <= 0 or velocity.z <= 0) velocity check removed
	if not chasing_player and not navigation_paused:
		set_new_random_target()

func _on_navigation_agent_velocity_computed(safe_velocity: Vector3) -> void:
	# safe_velocity is the avoidance-adjusted velocity returned by the NavigationServer
	agent_safe_velocity = safe_velocity

	# Apply horizontal part and preserve vertical (gravity) velocity
	velocity.x = agent_safe_velocity.x
	velocity.z = agent_safe_velocity.z

	# Now move and update animations here (move_and_slide must be called once per physics frame)
	move_and_slide()

func startPecking():
	if not pecking:
		pecking = true
		if not playerdamageCooldownBool:
			player.current_health -= randf_range(6.7, 11.2) * enemyDamageScale # Enemy/chicken does damage to player
			player.damagedParticlePlay()
			playerdamageCooldown()
		player.apply_shake("pecked")
		PeckingSfx.play()
		#ChickenMissSfx.play()
		animation_state_machine_node.travel("chickenPeck")

func playerdamageCooldown():
	if playerdamageCooldownBool == false:
		playerdamageCooldownBool = true
		await get_tree().create_timer(0.7).timeout
		playerdamageCooldownBool = false
	else:
		return
		
# NEITHER OF THESE ARE WORKING WHEN BEING CALLED IN THE ANIMATION PLAYER AS OF NOW
#func peckingSfxPlay():
	#PeckingSfx.play()
# 
#func phickenMissSfxPlay():
	#ChickenMissSfx.play()

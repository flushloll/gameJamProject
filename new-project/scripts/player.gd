extends CharacterBody3D

# === Tunable Settings ===
@export var move_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_force: float = 4.5
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var air_control: float = 0.4
@export var ground_accel: float = 12.0
@export var ground_friction: float = 10.0
@export var mouse_sensitivityX: float = 0.07
@export var mouse_sensitivityY: float = 0.07
@onready var cam_view: int = 1
@onready var camTop = $Camera3D
@onready var gun_cam = $Head/SpringArm3D/GunCamera
@onready var original_local_cam_top_position = camTop.transform.origin
@onready var original_local_cam_gun_position = gun_cam.transform.origin
var is_stomp_falling: bool = false
@export var stomp_speed: float = -30.0
@export var stomp_radius: float = 5.0
@onready var stompsfx = $"../StompSfx"
@onready var fallingsfx = $"../FallingSfx"
@onready var cracksfx = $"../CrackSfx"
@onready var playerdeathsfx = $"../DeathSoundSfx"
@onready var UI = $"../UI"
@onready var stompskill = $"../UI/StompSkill"
@onready var can_stomp = true
@onready var DamagedParticle = $DamagedParticle
@onready var playerMesh = $MeshInstance3D

@onready var head: Node3D = $Head
@onready var FPS_shoot_cast = $Head/SpringArm3D/GunCamera/FPSCast
@export var randomStrength: float = 0.2  # subtle shake
@export var shakeFade: float = 10.0

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0
@export var can_shake = true
var camera_rot_tempSaved

# === Rotation state ===
var _yaw: float = 0.0
var _pitch: float = 0.0
@export var PITCH_LIMIT_DOWN := -70
@export var PITCH_LIMIT_UP := 75

# Saved view state for switching
var saved_fps_yaw : float = 0.0
var saved_fps_pitch : float = 0.0
var has_saved_fps : bool = false

var saved_cursor_target : Vector3 = Vector3.ZERO
var has_saved_cursor : bool = false
var saved_fps_target : Vector3 = Vector3.ZERO
var has_saved_fps_target : bool = false

@export var lunge_distance: float = 8.0
@export var vertical_velocity_for_lunge: float # or some custom boost   # how far the lunge goes
@export var lunge_duration: float = 0.2   # how long it takes
var is_lunging: bool = false
var lunge_timer: float = 0.0
var lunge_velocity: Vector3 = Vector3.ZERO

@onready var max_health = 100.0
@onready var current_health = 100.0
@onready var stompedYetThisFrame: bool
@onready var is_dead

@onready var in_menu = false
@onready var in_shop_kitchen = false
var interact_distance := 5.0
@onready var stomp_speed_modifier = 1.0
var is_knocked_back: bool = false
var knockback_timer: float = 0.0

func _ready() -> void:
	# Lock mouse for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _unhandled_input(event: InputEvent) -> void:
	if not Global.isPlayerDead:
		if event is InputEventMouseMotion: #and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_yaw   -= event.relative.x * mouse_sensitivityX
			_pitch -= event.relative.y * mouse_sensitivityY
			_pitch = clamp(_pitch, PITCH_LIMIT_DOWN, PITCH_LIMIT_UP)
		if Global.cameraFollowsCursor:
			head.rotation_degrees.y = _yaw
		else:
			head.rotation_degrees.x = _pitch  # only pitch

# ---------- Helper: save / restore views ----------
func save_fps_view() -> void:
	# store yaw/pitch so we can restore later when returning to FPS
	saved_fps_yaw = _yaw
	saved_fps_pitch = _pitch
	has_saved_fps = true

func restore_fps_view() -> void:
	if not has_saved_fps:
		return
	_yaw = saved_fps_yaw
	_pitch = clamp(saved_fps_pitch, PITCH_LIMIT_DOWN, PITCH_LIMIT_UP)
	rotation_degrees.y = _yaw
	head.rotation_degrees.x = _pitch
	# ensure the body/head are set to these values immediately
	rotation_degrees.y = _yaw
	head.rotation_degrees.x = _pitch

func save_cursor_view(target: Vector3) -> void:
	saved_cursor_target = target
	has_saved_cursor = true

func restore_cursor_view() -> void:
	if not has_saved_cursor:
		return
	# make the head (or camera) look at the saved cursor target
	head.look_at(saved_cursor_target, Vector3.UP)

# ---------- Camera view switching ----------
func camViewSwitchToFPS():
	# switching into FPS: save the cursor view so we can restore it when leaving FPS
	# If we are currently following cursor, capture the cursor target we were looking at
	if Global.cameraFollowsCursor:
		# store current cursor target if it exists (we maintain this in _process when ray hits)
		# If you want to ensure there's always a saved cursor target, you could use a default ahead of the player.
		# Attempt to capture from ShootCast target_position if available:
		if $ShootCast and $ShootCast.target_position:
			var world_target = $ShootCast.to_global($ShootCast.target_position)
			save_cursor_view(world_target)
		# otherwise keep any previously saved cursor_target

	# When leaving FPS we should save the fps angles; but here we are entering FPS, restore saved fps angles (if any)
	restore_fps_view()

	cam_view = 2
	gun_cam.make_current()
	rotation_degrees.y = _yaw
	head.rotation_degrees.x = _pitch
	Global.cameraFollowsCursor = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func camViewSwitchToTopView():
	# switching into top/cursor view:
	# Save current FPS angles so we can return to them later
	if not Global.cameraFollowsCursor:
		save_fps_view()

	# Restore cursor target (where the cursor was last looking) so the top view/head points there
	if has_saved_fps_target:
		save_cursor_view(saved_fps_target)
		restore_cursor_view()

	cam_view = 1
	
	camTop.make_current()
	Global.cameraFollowsCursor = true
	$Camera3D.global_rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	
	if not Global.isPlayerDead:
		if not is_on_floor():
			if Input.is_action_just_pressed("stomp") and can_stomp:
				stompedYetThisFrame = false
				is_stomp_falling = true
				can_stomp = false
				playFallingSfx()
				stomp_speed_modifier = 1.0
				velocity.y -= pow(stomp_speed, stomp_speed_modifier)  # force you downward fast
				
		if event.is_action_pressed("interact"):
			var from: Vector3 = gun_cam.global_transform.origin
			var to: Vector3 = from + -gun_cam.global_transform.basis.z * interact_distance

			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from, to)
			query.exclude = [self]
			query.collision_mask = 1  # only detect interactables

			var result = space_state.intersect_ray(query)

			if result:
				var collider = result.collider
				if collider and collider.is_in_group("Interactable"):
					if collider.name == "Shop_Kitchen" and not in_shop_kitchen:
						print("hi")  # triggers once per key press
						UI.load_or_exit_shop_kitchen("enter")
						in_menu = true
						in_shop_kitchen = true
					else:
						in_menu = false
						in_shop_kitchen = false
						UI.load_or_exit_shop_kitchen("exit")
			else:
				if in_shop_kitchen:
					in_menu = false
					in_shop_kitchen = false
					UI.load_or_exit_shop_kitchen("exit")
				else:
					return
			
# ---------- Main process ----------
func _process(delta) -> void:
	
	stomp_speed_modifier += delta
	
	if current_health <= 0 and not is_dead:
		playerdeathsfx.play()
		die()
					
	if not Global.isPlayerDead:
		if Input.is_action_just_pressed("escape") and in_menu:
			if in_shop_kitchen:
				in_menu = false
				in_shop_kitchen = false
				UI.load_or_exit_shop_kitchen("exit")
			else:
				return
		
	# === 1. Gravity ===
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	else:
		if absf(velocity.y) < 0.01:
			velocity.y = 0.0
			is_stomp_falling = false
			fallingsfx.stop()
			
	var camFollowsCursor: Camera3D = $Camera3D
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	var from: Vector3 = camFollowsCursor.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camFollowsCursor.project_ray_normal(mouse_pos) * 1000.0

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)

	var result = space_state.intersect_ray(query)
	
	if result and Global.cameraFollowsCursor:
		var target: Vector3 = result.position
		var shoot_cast = $ShootCast
		shoot_cast.target_position = shoot_cast.to_local(result.position)
		$Head.look_at(target, Vector3.UP)
		# SAVE the last seen cursor target so switching away can restore it later
		save_cursor_view(target)

	# === 2. Input direction ===
	var input2d: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")

	# Instead of using basis (camera/player rotation),
	# lock movement to fixed world axes.

	var forward: Vector3
	var right: Vector3
	
	if Global.cameraFollowsCursor:
		# Original logic: fixed world axes
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		forward = Vector3.FORWARD
		right = Vector3.RIGHT
	else:
		FPS_shoot_cast.global_transform = gun_cam.global_transform
		#FPS_shoot_cast.global_transform.origin += Vector3(0.5, 0.25, 0.0) 
		FPS_shoot_cast.target_position = Vector3(0, 0, -1000)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		var cam_basis: Basis = $Head/SpringArm3D/GunCamera.global_transform.basis
		forward = -cam_basis.z
		forward.y = 0
		forward = forward.normalized()
		right = cam_basis.x
		right.y = 0
		right = right.normalized()
		if not Global.cameraFollowsCursor:
			rotation_degrees.y = _yaw  # body follows mouse X
			head.rotation_degrees.x = _pitch  # head follows mouse Y
			# Build desired horizontal movement direction
		var fps_forward_world: Vector3 = gun_cam.global_position + (-cam_basis.z * 1000.0)
		saved_fps_target = fps_forward_world
		has_saved_fps_target = true
		
			
	var desired_dir: Vector3 = (right * input2d.x + forward * input2d.y).normalized()

	# === 3. Target horizontal velocity ===
	var target_speed: float = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	var target_hvel: Vector3 = desired_dir * target_speed

	# === 4. Acceleration or friction ===
	var hvel: Vector3 = velocity
	hvel.y = 0.0

	if is_lunging or is_knocked_back:  # skip friction/acceleration during knockback/lunge
		ground_accel = 19.0
		ground_friction = 7.0
	else:
		ground_accel = 12.0
		ground_friction = 10.0

	if is_on_floor():
		if desired_dir.length() > 0:
			hvel = hvel.lerp(target_hvel, clamp(ground_accel * delta, 0.0, 1.0))
		else:
			hvel = hvel.lerp(Vector3.ZERO, clamp(ground_friction * delta, 0.0, 1.0))
	else:
		hvel = hvel.lerp(target_hvel, clamp(air_control * delta, 0.0, 1.0))

		velocity.x = hvel.x
		velocity.z = hvel.z

	# Handle knockback timer
	if is_knocked_back:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false

	velocity.x = hvel.x
	velocity.z = hvel.z

	# === 5. Jump ===
	if not Global.isPlayerDead:
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
	
	if is_lunging:
		velocity.x = lunge_velocity.x
		velocity.y = lunge_velocity.y
		velocity.z = lunge_velocity.z

		lunge_timer -= delta
		if lunge_timer <= 0:
			is_lunging = false
			lunge_velocity = Vector3.ZERO

	# === 6. Apply movement & collision ===
	move_and_slide()
	
	if is_stomp_falling and is_on_floor():
		perform_stomp()
	
	var head_rot = head.rotation_degrees.x
	head.rotation_degrees.x = head_rot
		
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		var offset = random_offset()
		if Global.cameraFollowsCursor:	
			var new_transform = camTop.transform
			new_transform.origin = original_local_cam_top_position + offset
			camTop.transform = new_transform
		elif not Global.cameraFollowsCursor:
			var new_transform = gun_cam.transform
			new_transform.origin = original_local_cam_gun_position + offset
			gun_cam.transform = new_transform
		else:
			var new_transformTOP = camTop.transform
			new_transformTOP.origin = original_local_cam_top_position
			camTop.transform = new_transformTOP
			var new_transformFPS = gun_cam.transform
			new_transformFPS.origin = original_local_cam_gun_position + offset
			gun_cam.transform = new_transformFPS

func playFallingSfx():
	await get_tree().create_timer(1)
	if not is_on_floor():
		fallingsfx.play()
	
func perform_stomp() -> void:
	if stompedYetThisFrame:
		return
	stompedYetThisFrame = true
	is_stomp_falling = false
	playCrackSfx()
	stompsfx.play()
	apply_shake("stomp")
	current_health -= 10
		
	var killed: Array = []
	var space_state_forstomp = get_world_3d().direct_space_state
	var query_forstomp = PhysicsShapeQueryParameters3D.new()
	query_forstomp.shape = SphereShape3D.new()
	query_forstomp.shape.radius = stomp_radius
	query_forstomp.transform = Transform3D(Basis(), global_position)
	query_forstomp.collision_mask = 1 << 2  # layer 3
	var results = space_state_forstomp.intersect_shape(query_forstomp)
		# Add effects
	print("STOMP landed! Hit: ", results.size(), " enemies")
	
	for r in results:
		var collider = r.collider
		if collider == null:
			continue

		# If the collider is a child, find its CharacterBody3D parent
		while collider and not collider.has_method("stomp_take_damage"):
			collider = collider.get_parent()

		if collider and collider.has_method("stomp_take_damage"):
			print("Hit Enemy: ", collider.name)
			killed.append(collider.stomp_take_damage())
			
	if killed.has(true):
		can_stomp = true
		current_health += 10
		pass
	if not killed.has(true):
		can_stomp = false
		stompskill.resetSkillProgressBar()
		await get_tree().create_timer(6).timeout
		can_stomp = true

func apply_shake(shakeStrengthBasedOnInput):
	var shakeStrengthBasedOnInputCheck = str(shakeStrengthBasedOnInput)
	if shakeStrengthBasedOnInputCheck == "1":
		shake_strength = randomStrength
	elif shakeStrengthBasedOnInputCheck == "stomp":
		shake_strength = randomStrength * 3.3
	elif shakeStrengthBasedOnInputCheck == "damaged":
		shake_strength = randomStrength * 0.8
	elif shakeStrengthBasedOnInputCheck == "pecked":
		shake_strength = randomStrength * 0.3
	else:
		if typeof(shakeStrengthBasedOnInput) == TYPE_FLOAT or typeof(shakeStrengthBasedOnInput) == TYPE_INT:
			shake_strength = randomStrength * float(shakeStrengthBasedOnInput)

func random_offset() -> Vector3:
	return Vector3(
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength))

func start_lunge():
	if is_lunging:
		return  # don't stack lunges

	is_lunging = true
	lunge_timer = lunge_duration

	# Forward direction depends on camera or player facing
	var forward_dir: Vector3
	if Global.cameraFollowsCursor:
		forward_dir = -head.global_transform.basis.z
	else:
		var cam_basis = gun_cam.global_transform.basis
		forward_dir = -cam_basis.z

	#forward_dir.y = 0
	# Remove vertical component from forward_dir and add an initial jump-like boost
	var forward_dir_no_y = forward_dir
	forward_dir_no_y.y = 0
	var horizontal_velocity = forward_dir_no_y.normalized() * (lunge_distance / lunge_duration)
	lunge_velocity = Vector3(horizontal_velocity.x, vertical_velocity_for_lunge, horizontal_velocity.z)

func setCanStompToTrue():
	can_stomp = true

func playCrackSfx():
	cracksfx.play()
	await get_tree().create_timer(0.7)
	cracksfx.stop()

func die():
	UI.show_death_screen()
	move_speed = 0.0001
	if not Global.isPlayerDead:
		remove_from_group("Player")
	Global.isPlayerDead = true
	is_dead = true

func damagedParticlePlay():
	flash_red()
	apply_shake("hit")
	DamagedParticle.emitting = false
	DamagedParticle.emitting = true

func flash_red():
	var mat: ShaderMaterial = playerMesh.get_surface_override_material(0)

	# Save original color
	var original_color: Color = mat.get_shader_parameter("color")

	# Flash red
	mat.set_shader_parameter("color", Color(0.776, 0.76, 0.636, 1)) # "#c2be9f"
	
	await get_tree().create_timer(0.4).timeout
	# Restore
	mat.set_shader_parameter("color", original_color) # "#c2a08a" if that's default


func addHealthBuff():
	if current_health == max_health:
		current_health += Global.player_health
		max_health += Global.player_health
	else:
		max_health += Global.player_health

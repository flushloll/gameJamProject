extends CharacterBody3D

# === Tunable Settings ===
@export var move_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_force: float = 4.5
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var air_control: float = 0.4
@export var ground_accel: float = 12.0
@export var ground_friction: float = 10.0
@export var mouse_sensitivity: float = 0.1

var is_falling: bool = false
@export var stomp_speed: float = -30.0
@export var stomp_radius: float = 5.0
@export var stomp_damage: int = 20
@onready var stompsfx = get_node("/root/Main/StompSfx")
@onready var fallingsfx = get_node("/root/Main/FallingSfx")
@onready var can_stomp = true

# === Node References ===
@onready var head: Node3D = $Head
#@onready var cam: Camera3D = $Head/SpringArm3D/Camera3D

# === Rotation state ===
var _yaw: float = 0.0
var _pitch: float = 0.0
const PITCH_LIMIT := 89.0

func _ready() -> void:
	# Lock mouse for camera control
	await get_tree().create_timer(0.01).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _unhandled_input(event: InputEvent) -> void:
	# Handle mouse look
	if event is InputEventMouseMotion: #and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw   -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, -PITCH_LIMIT, PITCH_LIMIT)
		head.rotation_degrees.y = _yaw             # body rotation (yaw)
		head.rotation_degrees.x = _pitch      # head rotation (pitch)

	# Toggle mouse lock (Escape key or mapped input)
	#if event.is_action_pressed("toggle_mouse"):
		#var m = Input.get_mouse_mode()
		#Input.set_mouse_mode(
			#Input.MOUSE_MODE_HIDDEN if m == Input.MOUSE_MODE_CAPTURED
			#else Input.MOUSE_MODE_CAPTURED
		#)

func _process(delta) -> void:
	# === 1. Gravity ===
	if not is_on_floor():
		velocity.y -= gravity * delta
		if Input.is_action_just_pressed("stomp") and can_stomp:
				is_falling = true
				can_stomp = false
				fallingsfx.play()
				velocity.y = stomp_speed   # force you downward fast
	else:
		if absf(velocity.y) < 0.01:
			velocity.y = 0.0
			is_falling = false
			
			
	var cam: Camera3D = $Camera3D
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	var from: Vector3 = cam.project_ray_origin(mouse_pos)
	var to: Vector3 = from + cam.project_ray_normal(mouse_pos) * 1000.0

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)

	var result = space_state.intersect_ray(query)

	if result:
		var target: Vector3 = result.position
		var shoot_cast = $ShootCast
		shoot_cast.target_position = shoot_cast.to_local(result.position)
		$Head.look_at(target, Vector3.UP)

	# === 2. Input direction ===
	var input2d: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")

# Instead of using basis (camera/player rotation),
# lock movement to fixed world axes.
	var forward: Vector3 = Vector3.FORWARD   # (0, 0, -1)
	var right: Vector3 = Vector3.RIGHT       # (1, 0, 0)

	# Build desired horizontal movement direction
	var desired_dir: Vector3 = (right * input2d.x + forward * input2d.y).normalized()

	# === 3. Target horizontal velocity ===
	var target_speed: float = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	var target_hvel: Vector3 = desired_dir * target_speed

	# === 4. Acceleration or friction ===
	var hvel: Vector3 = velocity
	hvel.y = 0.0

	if is_on_floor():
		if desired_dir.length() > 0.0:
			# Accelerate toward desired velocity
			hvel = hvel.lerp(target_hvel, clamp(ground_accel * delta, 0.0, 1.0))
		else:
			# Slow down smoothly when idle
			hvel = hvel.lerp(Vector3.ZERO, clamp(ground_friction * delta, 0.0, 1.0))
	else:
		# Limited air steering
		hvel = hvel.lerp(target_hvel, clamp(air_control * delta, 0.0, 1.0))

	velocity.x = hvel.x
	velocity.z = hvel.z

	# === 5. Jump ===
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

	# === 6. Apply movement & collision ===
	move_and_slide()
	
	if is_falling and is_on_floor():
		perform_stomp()
	
	var head_rot = head.rotation_degrees.x
	head.rotation_degrees.x = head_rot
	
func perform_stomp() -> void:
	Global.isStomping = true
	is_falling = false
	var killed: Array =  []
	var space_state_forstomp = get_world_3d().direct_space_state
	var query_forstomp = PhysicsShapeQueryParameters3D.new()
	query_forstomp.shape = SphereShape3D.new()
	query_forstomp.shape.radius = stomp_radius
	query_forstomp.transform = Transform3D(Basis(), global_position)
	
	var results = space_state_forstomp.intersect_shape(query_forstomp)

	for r in results:
		stompsfx.play()
		fallingsfx.stop()
		if r.collider.has_method("take_damage"):
			print("Hit Enemy")
			killed.append(r.collider.take_damage())
	if killed.has(true):
		Global.isStomping = false
		can_stomp = true
		return
	elif not killed.has(true):
		Global.isStomping = false
		can_stomp = false
		await get_tree().create_timer(1).timeout
		can_stomp = true

	# Add effects
	print("STOMP landed! Hit: ", results.size(), " enemies")

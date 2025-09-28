extends Node

var time_acc := 0.0

func _process(delta: float) -> void:
	time_acc += delta
	if time_acc >= 0.5:
		print("FPS: %d" % Engine.get_frames_per_second())
		time_acc = 0.0

@export var damage: int = 10
@export var isWeaponMelee: bool
var swinging: bool = false
var WeaponCollisionCooldown: float
var WeaponDamage: int
var WeaponTypeNameGlobal: String = "BaseWeapon"
var collider
var isStomping: bool = false
var playerCamRotation = Vector3(-90.0, -90.0 + 30.2, 0.0 + 20.7)
var cameraFollowsCursor: bool = false
var can_switch: bool = true
var current_enemies = []
var can_swing = true
var current_wave_timer
var InMenu = false
var player_attack: float = 1.0
var player_melee_attack_speed: float = 1.0
var player_health: float
var enemyDamageScaleAccumulate = 1.0
var isPlayerDead: bool

func reset():
		# Reset base stats
	damage = 10
	isWeaponMelee = false
	swinging = false
	WeaponCollisionCooldown = 0.0
	WeaponDamage = 0
	WeaponTypeNameGlobal = "BaseWeapon"
	collider = null
	isStomping = false
	
	# Reset camera/player state
	playerCamRotation = Vector3(-90.0, -90.0 + 30.2, 0.0 + 20.7)
	cameraFollowsCursor = false
	can_switch = true
	
	# Clear dynamic gameplay state
	current_enemies.clear()
	can_swing = true
	current_wave_timer = null
	InMenu = false
	
	# Reset player stats
	player_attack = 1.0
	player_melee_attack_speed = 1.0
	player_health = 100.0  # or whatever your default HP is
	enemyDamageScaleAccumulate = 1.0
	isPlayerDead = false

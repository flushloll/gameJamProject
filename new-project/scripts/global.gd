extends Node

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

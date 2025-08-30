extends Node

@export var damage: int = 10
@export var isWeaponMelee: bool
var swinging: bool = false
var WeaponCollisionCooldown: float
var WeaponDamage: int
var WeaponTypeNameGlobal: String = "BaseWeapon"
var collider
var isStomping
var playerCamRotation = Vector3(-90.0, -90.0 + 30.2, 0.0 + 20.7)

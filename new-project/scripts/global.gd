extends Node

@export var damage: int = 10
@export var isWeaponMelee: bool
var swinging: bool = false
var WeaponCollisionCooldown: float
var WeaponDamage: int
var WeaponTypeNameGlobal: String = "BaseWeapon"
var collider

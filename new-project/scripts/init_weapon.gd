@tool

extends Node3D

@export var WEAPON_TYPE : Weapons:
	set(value):
		WEAPON_TYPE = value
		if Engine.is_editor_hint():
			load_weapon()

@onready var weapon_mesh : MeshInstance3D = $WeaponMesh
@onready var weapon_collision_shape : CollisionShape3D = $Area3D/WeaponCollisionShape

func _ready() -> void:
	if WEAPON_TYPE != null:
		load_weapon()
	
func load_weapon() -> void:
	weapon_mesh.mesh = WEAPON_TYPE.mesh
	position = WEAPON_TYPE.position
	rotation_degrees = WEAPON_TYPE.rotation
	var weapon_cooldown = WEAPON_TYPE.weapon_cooldown
	Global.WeaponCollisionCooldown = weapon_cooldown
	var weapon_damage = WEAPON_TYPE.weapon_damage
	Global.WeaponDamage = weapon_damage

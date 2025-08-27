@tool

extends Node3D

@export var WEAPON_TYPE : Weapons:
	set(value):
		WEAPON_TYPE = value
		if Engine.is_editor_hint():
			load_weapon()

@onready var weapon_mesh : MeshInstance3D = $WeaponMesh
@onready var weapon_collision_shape : CollisionShape3D = $Area3D/WeaponCollisionShape
@onready var playeranimationplayer = %PlayerAnimationPlayer
@onready var weaponMesh = $WeaponMesh
var baseweapon = load("res://weapons/baseweapon.tres")
var firstgun = load("res://weapons/firstgun.tres")

func _ready() -> void:
	weaponMesh.position = Vector3(0.154, -0.08, 0.006)
	weaponMesh.rotation = Vector3(134.6, 18.5, 0.0)
	if WEAPON_TYPE != null:
		load_weapon()
		
func _process(delta):
	if not Engine.is_editor_hint():
		if Input.is_action_pressed("toWeapon1"):
			WEAPON_TYPE = baseweapon
			Global.WeaponTypeNameGlobal = "BaseWeapon"
			playeranimationplayer.stop()
			weaponMesh.position = Vector3(0.154, -0.08, 0.006)
			weaponMesh.rotation = Vector3(134.6, 18.5, 0.0)
			load_weapon()
		if Input.is_action_pressed("toWeapon2"):
			WEAPON_TYPE = firstgun
			Global.WeaponTypeNameGlobal = "FirstGun"
			playeranimationplayer.stop()
			weaponMesh.position = Vector3(1, -0.102, -0.043)
			weaponMesh.rotation = Vector3(45.4, -161.5, 180.0)
			load_weapon()
	
func load_weapon() -> void:
	weapon_mesh.mesh = WEAPON_TYPE.mesh
	position = WEAPON_TYPE.position
	rotation_degrees = WEAPON_TYPE.rotation
	var weapon_cooldown = WEAPON_TYPE.weapon_cooldown
	Global.WeaponCollisionCooldown = weapon_cooldown
	var weapon_damage = WEAPON_TYPE.weapon_damage
	Global.WeaponDamage = weapon_damage

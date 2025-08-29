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
@onready var weapon = %Weapon
var baseweapon = load("res://weapons/baseweapon.tres")
var firstgun = load("res://weapons/firstgun.tres")

func _ready() -> void:
	WEAPON_TYPE = baseweapon
	if WEAPON_TYPE != null:
		load_weapon()
	elif WEAPON_TYPE.name == "BaseWeapon":
		load_weapon()
	elif WEAPON_TYPE.name != "FirstGun":
		load_weapon()
		
func _process(delta):
	if not Engine.is_editor_hint():
		if Input.is_action_pressed("toWeapon1"):
			WEAPON_TYPE = baseweapon
			Global.WeaponTypeNameGlobal = "BaseWeapon"
			playeranimationplayer.stop()
			load_weapon()
		if Input.is_action_pressed("toWeapon2"):
			WEAPON_TYPE = firstgun
			Global.WeaponTypeNameGlobal = "FirstGun"
			playeranimationplayer.stop()
			load_weapon()
	
func load_weapon() -> void:
	
	weapon_mesh.mesh = WEAPON_TYPE.mesh
	weapon_mesh.position = WEAPON_TYPE.position
	weapon_mesh.rotation_degrees = WEAPON_TYPE.rotation
	var weapon_cooldown = WEAPON_TYPE.weapon_cooldown
	Global.WeaponCollisionCooldown = weapon_cooldown
	var weapon_damage = WEAPON_TYPE.weapon_damage
	Global.WeaponDamage = weapon_damage
	
	print("Loaded weapon:", WEAPON_TYPE.name)
	print("Position:", WEAPON_TYPE.position)
	print("Rotation:", WEAPON_TYPE.rotation)

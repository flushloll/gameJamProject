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
var buffered_weapon_input: bool = false

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
		if Input.is_action_pressed("toWeapon1") and Global.can_switch:
			WEAPON_TYPE = baseweapon
			Global.WeaponTypeNameGlobal = "BaseWeapon"
			playeranimationplayer.stop()
			load_weapon()
		if Input.is_action_just_pressed("toWeapon2"):
			if Global.can_switch:
				switch_to_weapon2()
			else:
				buffered_weapon_input = true

	# Check if buffered input can now be applied
		if buffered_weapon_input and Global.WeaponTypeNameGlobal == "BaseWeapon" and Global.can_switch:
			switch_to_weapon2()
			buffered_weapon_input = false
		
func switch_to_weapon2():
	WEAPON_TYPE = firstgun
	Global.can_switch = true
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

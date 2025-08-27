extends CanvasLayer

@onready var blueCursor = load("res://ui/cursorBlue.png")
@onready var redCursor = load("res://ui/cursorRed.png")
@onready var firingCursor = load("res://ui/firingCursor.png")
@onready var knifeImage = load("res://ui/knifeImage.png")
@onready var ammocounter = $AmmoCounter
@onready var cursor = $Cursor
@onready var subViewport = $"../SubViewportContainer/SubViewport"
@onready var weapon1 = $Control1/FirstWeaponLoadout
@onready var weapon2 = $Control2/SecondWeaponLoadout
@onready var swordBox = get_node("/root/Main/SubViewportContainer/SubViewport/Player/Head/GunCamera/SpringArm3D/Weapon/Area3D")
var fade_speed = 0.5
var current_weapon_type = ""

func _process(delta: float) -> void:
	cursor.position = get_viewport().get_mouse_position()

	if Global.WeaponTypeNameGlobal != current_weapon_type:
		current_weapon_type = Global.WeaponTypeNameGlobal
		weapon1.self_modulate.a = 1  # reset alpha only on weapon change
		if current_weapon_type == "BaseWeapon":
			weapon1.texture = knifeImage
			ammocounter.hide()
			cursor.texture = blueCursor
			cursor.scale = Vector2(0.3, 0.3)
			
		elif current_weapon_type == "FirstGun":
			weapon1.texture = firingCursor
			ammocounter.show()
			cursor.texture = redCursor
			cursor.scale = Vector2(0.1, 0.1)
			
		if Global.WeaponTypeNameGlobal == "FirstGun" and Global.collider:
			if Global.collider.is_in_group("Enemies"):
				cursor.texture = firingCursor  # enemy detected
			else:
				cursor.texture = redCursor  # not an enemy

	# Fade the weapon over time
	fadeWeapon1(delta)

func fadeWeapon1(delta):
	if weapon1.self_modulate.a > 0:
		await get_tree().create_timer(1).timeout
		weapon1.self_modulate.a -= fade_speed * delta
		weapon1.self_modulate.a = max(weapon1.self_modulate.a, 0)

func _on_sword_body_entered(body):
	if body.is_in_group("Enemies"):
		if Global.WeaponTypeNameGlobal == "BaseWeapon":
			cursor.texture = knifeImage
			cursor.scale = Vector2(0.3, 0.3)

func _on_sword_body_exited(body):
	if body.is_in_group("Enemies"):
		if Global.WeaponTypeNameGlobal == "BaseWeapon":
			cursor.texture = blueCursor
			cursor.scale = Vector2(0.1, 0.1)

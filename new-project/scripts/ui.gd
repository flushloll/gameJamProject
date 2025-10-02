extends CanvasLayer

@onready var blueCursor = load("res://ui/cursorBlue.png")
@onready var redCursor = load("res://ui/cursorRed.png")
@onready var gunImage = load("res://ui/sawedOff.png")
@onready var knifeImage = load("res://ui/katanaMatching.png")
@onready var centerCursor = $CenterCursor
@onready var ammocounter = $AmmoCounter
@onready var cursor = $Cursor
@onready var subViewport = $".."
@onready var weapon1 = $Control1/FirstWeaponLoadout
@onready var weapon2 = $Control2/SecondWeaponLoadout
@onready var swordBox = $"../Player/Head/SpringArm3D/GunCamera/Weapon/MeleeRange"
@onready var shop_kitchen = $Shop_Kitchen
@onready var player = $"../Player"
@onready var shop_kitchen_margin_container = $Shop_Kitchen/VBoxContainer/PanelContainer/MarginContainer
@onready var skipTimerLabel = $SpawnTimer/skipTimerLabel
var fade_speed = 0.5
var current_weapon_type = ""

func _process(delta: float) -> void:
	
	if Global.cameraFollowsCursor == false:
		cursor.hide()
		centerCursor.visible = true
	elif Global.cameraFollowsCursor == true:
		cursor.show()
		centerCursor.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
	cursor.position = get_viewport().get_mouse_position()
	
	if Global.WeaponTypeNameGlobal != current_weapon_type:
		current_weapon_type = Global.WeaponTypeNameGlobal
		weapon1.self_modulate.a = 1  # reset alpha only on weapon change
		if current_weapon_type == "BaseWeapon":
			weapon1.texture = knifeImage
			weapon1.scale = Vector2(0.35, 0.35)
			weapon1.position = Vector2(-90, 5)
			ammocounter.hide()
			cursor.texture = blueCursor
			cursor.scale = Vector2(0.1, 0.1)
		
		elif current_weapon_type == "FirstGun":
			weapon1.texture = gunImage
			weapon1.scale = Vector2(0.35, 0.35)
			weapon1.position = Vector2(-40, 0)
			ammocounter.show()
			cursor.texture = redCursor
			cursor.scale = Vector2(0.1, 0.1)
		
		if Global.WeaponTypeNameGlobal == "FirstGun" and Global.collider:
			if Global.collider.is_in_group("Enemies"):
				cursor.texture = gunImage  # enemy detected
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

func load_or_exit_shop_kitchen(enter_or_exit: String):
	if enter_or_exit == "exit":
		shop_kitchen.hide()
		player.in_menu = false
		shop_kitchen_margin_container.enter_or_exit_ShopKitchen("exitShopKitchen")
	elif enter_or_exit == "enter":
		shop_kitchen.show()
		player.in_menu = true
		shop_kitchen_margin_container.enter_or_exit_ShopKitchen("enterShopKitchen")

func show_death_screen():
	$DeathScreenBackground.show()
	$DeathScreenMenu.show()

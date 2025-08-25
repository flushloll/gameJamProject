extends Area3D
#
#@onready var enemy = $".."
#@onready var player_inside = false
#
#func _ready() -> void:
	#monitoring = true
	#body_entered.connect(_on_body_entered)
	#body_exited.connect(_on_body_exited)
#
#func _on_body_entered(body: Node) -> void:
	#if body.is_in_group("Weapon"):  # Make sure your player is in the "Player" group
		#player_inside = true
#
#func _on_body_exited(body: Node) -> void:
	#if body.is_in_group("Weapon"):
		#player_inside = false
		
#func _on_hitbox_body_entered(body: Node):
	#checkIfPlayerAndDoDamage(body)
		#
#func checkIfPlayerAndDoDamage(body: Node):
	#if body.is_in_group("Weapon") and body.is_in_group("Swinging"):
		#enemy.take_damage()
	#else:
		#push_warning("%s has no get_damage method!" % body.name)
	

#func isBodyTheWeapon(theBody: Node):
	#var overlapping_bodies = get_overlapping_bodies() # Or get_overlapping_areas()
	#for body in overlapping_bodies:
		#if body.is_in_group("Weapon"):
			#print("Specific object is currently in the area!")
			#return true
	#return false
## _on_hitbox_body_entered()

#
#@onready var weapon_collision = get_node("/root/Main/Player/Head/SpringArm3D/Camera3D/Weapon/WeaponMesh/WeaponHitBox/WeaponCollisionShape") #Assuming the collision shape is a child node of the weapon
#@export var damage: int = 10  # Damage dealt when hitting an enemy
#@onready var playeranimation_player = get_node("/root/Main/Player/PlayerAnimationPlayer") #Make sure you have an animation player for swinging
#
#var is_swinging: bool = false  # Whether the weapon is actively swinging
#
#func _ready():
	## Connect to the area_entered signal to detect when something enters the weapon's area
	#self.body_entered.connect(on_body_entered)
#
#func _process(delta):
	#if Input.is_action_just_pressed("attack"):  # Check if the attack button is pressed
		#start_attack()
#
## When the weapon collides with an enemy
#func on_body_entered(body: Node):
#a	if is_swinging:
		#body.take_damage(damage)  # Call the enemy's take_damage method
#
## Start the weapon's attack (trigger the swing animation)
#func start_attack():
	#is_swinging = true
	#playeranimation_player.play("bat_swing")  # Make sure the swing animation exists
	#
	## Wait for the animation to finish before continuing (awaiting the animation to finish)
	#await playeranimation_player.animation_finished  # This will wait until the animation finishes
 #

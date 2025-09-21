extends ProgressBar
@onready var playerWeaponCollision = get_node("/root/GameController/World3D/Main/SubViewportContainer/SubViewport/Player/Head/SpringArm3D/GunCamera/Weapon/MeleeRange/WeaponCollisionShape")
@onready var localSkillRegenCooldown

func _ready() -> void:
	value = 100.0

func _process(delta):
	if playerWeaponCollision.knockbackCooldown:
		if localSkillRegenCooldown == false:
			value = 0.0
			localSkillRegenCooldown = true
	if value < 100.0 and localSkillRegenCooldown:
			value += delta * 17.544
	elif value == 100.0:
		localSkillRegenCooldown = false
	

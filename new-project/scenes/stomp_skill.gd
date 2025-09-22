extends TextureProgressBar
@onready var playerWeaponCollision = get_node("/root/GameController/World3D/Main/SubViewportContainer/SubViewport/Player/Head/SpringArm3D/GunCamera/Weapon/MeleeRange/WeaponCollisionShape")

func _ready() -> void:
	value = 100.0
	step = 0.001

func resetSkillProgressBar():
	value = 0.0

func _process(delta):
	value += delta * 16.667

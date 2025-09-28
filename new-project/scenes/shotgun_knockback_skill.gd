extends TextureProgressBar
@onready var playerWeaponCollision = $"../../Player/Head/SpringArm3D/GunCamera/Weapon/MeleeRange/WeaponCollisionShape"
@onready var skill1 : String

func _ready() -> void:
	value = 100.0
	step = 0.001

func resetSkillProgressBar():
	value = 0.0
	
func switchSkill(skillType):
	skill1 = str(skillType)

func _process(delta):
	if skill1 == "shotgunKnockback":
		value += delta * 10.757

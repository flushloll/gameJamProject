extends TextureButton

var hasPowerUpAvailable: bool
var stats = ["attack", "melee_attack_speed", "health"]
var powerUpAttack
var powerUpMeleeAttackSpeed
var powerUpHealth
@onready var powerUpsBoxShown = $"../../../../../../../../../../PowerUpStatsBuff"
@onready var usedPowerUpsList = $"../../../../../../../../../../UsedPowerUps"
var currentPowerUp
@onready var player = get_node("/root/GameController/World3D/Main/SubViewportContainer/SubViewport/Player")
var buffs = []

func addPowerUpToSlot(powerUpStrength):
	if powerUpStrength == "worst":
		var selectRandomPowerUpWeak = randi_range(1,1)
		if selectRandomPowerUpWeak == 1:
			var powerUpWeak = load("res://ingredients/powerups/PowerUpWorstFruitSalad.tres")
			currentPowerUp = powerUpWeak
			powerUpAttack = powerUpWeak.attack
			powerUpMeleeAttackSpeed = powerUpWeak.melee_attack_speed
			powerUpHealth = powerUpWeak.health 
			self.texture_normal = powerUpWeak.texture  # show texture on button
			hasPowerUpAvailable = true
			
	#elif powerUpStrength == "mid":
		#ingredientCurrentlyInSpot = ingredientWantingToBeAdded
		#self.texture_normal = ingredientCurrentlyInSpot.texture  # show texture on button
		#
		#ingredientInSpotAssociatedValue = ingredientWantingToBeAdded.value
		#isIngredientInSpotAlready = true
		#pass
	#elif powerUpStrength == "best":
		#ingredientCurrentlyInSpot = ingredientWantingToBeAdded
		#self.texture_normal = ingredientCurrentlyInSpot.texture  # show texture on button
		#
		#ingredientInSpotAssociatedValue = ingredientWantingToBeAdded.value
		#isIngredientInSpotAlready = true
		#pass

func apply_multi_buff():
	for stat in stats:
			match stat:
				"attack":
					Global.player_attack += powerUpAttack
				"melee_attack_speed":
					Global.player_melee_attack_speed += powerUpMeleeAttackSpeed
				"health":
					Global.player_health += powerUpHealth
					player.addHealthBuff()
	showTheUserTheStatBuffs()
	addPowerUpToUsedPowerUpList()
	powerUpAttack = 0
	powerUpMeleeAttackSpeed = 0
	powerUpHealth = 0

func usePowerUpInSlot():
	apply_multi_buff()
	self.texture_normal = null  # show texture on button
	hasPowerUpAvailable = false

func showTheUserTheStatBuffs():
	buffs.clear() # Clears old references so they don't accumulate
	
	if powerUpAttack > 0 and powerUpMeleeAttackSpeed > 0 and powerUpHealth > 0:
	
		var attackstatbuff = Label.new()
		attackstatbuff.label_settings = load("res://ingredients/powerups/userShownStatBuffsAttack.tres")
		attackstatbuff.text = "+ " + str(powerUpAttack).substr(3, -1) + "%  DAMAGE"
		attackstatbuff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		attackstatbuff.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		powerUpsBoxShown.add_child(attackstatbuff)
		buffs.append(attackstatbuff)
		
		var melee_attack_speedstatbuff = Label.new()
		melee_attack_speedstatbuff.label_settings = load("res://ingredients/powerups/userShownStatBuffsMeleeAttackSpeed.tres")
		melee_attack_speedstatbuff.text = "+ 2.5% MELEE\nATTACK SPEED"
		melee_attack_speedstatbuff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		melee_attack_speedstatbuff.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		powerUpsBoxShown.add_child(melee_attack_speedstatbuff)
		buffs.append(melee_attack_speedstatbuff)
		
		var healthstatbuff = Label.new()
		healthstatbuff.label_settings = load("res://ingredients/powerups/userShownStatBuffsHealth.tres")
		healthstatbuff.text = "+ " + str(powerUpHealth) + " HEALTH"
		healthstatbuff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		healthstatbuff.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		powerUpsBoxShown.add_child(healthstatbuff)
		buffs.append(healthstatbuff)
		
		for buff in buffs:
			var tween = create_tween()
			tween.tween_property(buff, "modulate:a", 0.0, 1.5).set_delay(1.0) # fade out after 1s delay
			tween.finished.connect(func(): 
				if is_instance_valid(buff):
					buff.queue_free()
					for child in powerUpsBoxShown.get_children():
						child.queue_free()
			)

func addPowerUpToUsedPowerUpList():
	if powerUpAttack > 0 and powerUpMeleeAttackSpeed > 0 and powerUpHealth > 0:
		var power_up_icon = TextureRect.new()
		power_up_icon.name = currentPowerUp.power_up_name
		power_up_icon.texture = currentPowerUp.texture
		power_up_icon.expand = true
		power_up_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		power_up_icon.custom_minimum_size = Vector2(96, 96) # adjust size if you want
		usedPowerUpsList.add_child(power_up_icon)

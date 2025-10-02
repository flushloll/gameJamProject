extends MarginContainer

@onready var arrow = $Arrow
@onready var options
@onready var selectionAudio = $"../../../../SelectOptionSFX"
@onready var changeSelectionSFX = $"../../../../ChangeSelectionSFX"
var current_index = 0
var arrow_offset = Vector2(67, 7)
var arrow_offset_flipped = Vector2(80, 45) # Adjust as needed
@onready var shop_kitchen = $"../../.."
@onready var UI = $"../../../.."

var target_position: Vector2
var smoothing_speed := 8.0  # higher = faster, lower = slower

var bounce_amplitude := 1.2   # how far left/right it moves
var bounce_speed := 4.0       # how fast it wiggles
var time_passed := 0.0

var showShopArrow = false
var showKitchenArrow = true
var arrowFollowingSelectionTarget
var OpenInventory: bool = false
@onready var inventory = $"../../../../Inventory"
@onready var ingredient1 = $KitchenContainer/HBoxContainer/ItemList1/HBoxContainer/VBoxContainer/MarginContainer/PanelContainer/TextureButton
@onready var ingredient2 = $KitchenContainer/HBoxContainer/ItemList1/HBoxContainer2/VBoxContainer/MarginContainer/PanelContainer/TextureButton
@onready var ingredient3 = $KitchenContainer/HBoxContainer/ItemList1/HBoxContainer3/VBoxContainer/MarginContainer/PanelContainer/TextureButton
@onready var powerUpSlot = $KitchenContainer/HBoxContainer/ItemList2/MarginContainer2/PanelContainer/TextureButton

@onready var kitchenInventorySlot1 = $"../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer/TextureRect"
@onready var kitchenInventorySlot2 = $"../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer2/TextureRect"
@onready var kitchenInventorySlot3 = $"../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer3/TextureRect"
@onready var kitchenInventorySlot4 = $"../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer4/TextureRect"
@onready var kitchenInventorySlot5 = $"../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer5/TextureRect"
@onready var kitchenInventorySlot6 = $"../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer6/TextureRect"

@onready var confirmCookSfx = $"../../../../confirmCookSfx"

var didMoveAnything

func _ready():
	var startingTarget = $KitchenContainer/HBoxContainer2/ExitFromKitchen
	target_position = startingTarget.global_position + Vector2(startingTarget.size.x, 0) + Vector2(158, 28)
	showKitchenArrow = true
	setWhatPageArrowIsOn()
	shop_kitchen.hide()
	$ShopContainer.hide()

func _input(event):
	if shop_kitchen.visible:
		# Navigate menu freely until final choice
			if event.is_action_pressed("ui_down"):
				if showKitchenArrow or showShopArrow:
					current_index = (current_index + 1) % options.size()
					playMovingAudio()
					update_arrow_position()
					if options[current_index].is_in_group("FaceRight"):
						arrow.flip_h = true
					else:
						arrow.flip_h = false
			elif event.is_action_pressed("ui_up"):
				if showKitchenArrow or showShopArrow:
					current_index = (current_index - 1 + options.size()) % options.size()
					playMovingAudio()
					update_arrow_position()
					if options[current_index].is_in_group("FaceRight"):
						arrow.flip_h = true
					else:
						arrow.flip_h = false
			if event.is_action_pressed("ui_right"):
				if OpenInventory:
					current_index = (current_index + 1) % options.size()
					playMovingAudio()
					update_arrow_position()
			if event.is_action_pressed("ui_left"):
				if OpenInventory:
					current_index = (current_index - 1 + options.size()) % options.size()
					playMovingAudio()
					update_arrow_position()
			elif event.is_action_pressed("ui_accept") and options[current_index].name == "PageSwitchLabel" and (showKitchenArrow or showShopArrow):
				switchBetweenKitchenAndShop()
				setWhatPageArrowIsOn()
			elif event.is_action_pressed("ui_accept") and options[current_index].name == "ExitFromKitchen" and (showKitchenArrow or showShopArrow):
				setWhatPageArrowIsOn()
				enter_or_exit_ShopKitchen("exitShopKitchen")
			elif event.is_action_pressed("ui_accept") and options[current_index].is_in_group("Ingredient") and showKitchenArrow:
				arrow.rotation_degrees = 90
				showKitchenArrow = false
				OpenInventory = true
				setWhatPageArrowIsOn()
				update_arrow_position()
				if current_index == 1:
					ingredient1.removeIngredientFromSpot(false)
				elif current_index == 2:
					ingredient2.removeIngredientFromSpot(false)
				elif current_index == 3:
					ingredient3.removeIngredientFromSpot(false)
			elif event.is_action_pressed("ui_accept") and options[current_index].is_in_group("Inventory") and OpenInventory:
				if current_index == 0:
					didMoveAnything = kitchenInventorySlot1.moveIngredientToCooking()
				elif current_index == 1:
					didMoveAnything = kitchenInventorySlot2.moveIngredientToCooking()
				elif current_index == 2:
					didMoveAnything = kitchenInventorySlot3.moveIngredientToCooking()
				elif current_index == 3:
					didMoveAnything = kitchenInventorySlot4.moveIngredientToCooking()
				elif current_index == 4:
					didMoveAnything = kitchenInventorySlot5.moveIngredientToCooking()
				elif current_index == 5:
					didMoveAnything = kitchenInventorySlot6.moveIngredientToCooking()
				if didMoveAnything == true:
					pass
				else:
					arrow.rotation_degrees = 0
					current_index = 4
					OpenInventory = false
					showKitchenArrow = true
					showShopArrow = false
					arrow.flip_h = true
					setWhatPageArrowIsOn()
					update_arrow_position()
					
			elif event.is_action_pressed("ui_accept") and options[current_index].is_in_group("ActivateCook"):
				if not powerUpSlot.hasPowerUpAvailable and ingredient1.isIngredientInSpotAlready and ingredient2.isIngredientInSpotAlready and ingredient3.isIngredientInSpotAlready:
					current_index = 5
					update_arrow_position()
					makeProduct()
					clearInventory()
			elif event.is_action_pressed("ui_accept") and options[current_index].is_in_group("UsePowerup"):
				powerUpSlot.usePowerUpInSlot()

func _process(delta):
	
	if shop_kitchen.visible:
	
		time_passed += delta
	
	# Smoothly move the arrow towards the target position
		arrow.global_position = arrow.global_position.lerp(target_position, smoothing_speed * delta)
	
	# Apply passive horizontal bounce
		var bounce = sin(time_passed * bounce_speed) * bounce_amplitude
		
		if showKitchenArrow or showShopArrow:
			arrow.global_position.x += bounce
		if OpenInventory:
			arrow.global_position.y += bounce

func update_arrow_position():
	arrow.scale = Vector2(0.06, 0.06)
	# Reset bounce when switching options
	var current_option = options[current_index]
	time_passed = 0.0
	
	
	
	if showKitchenArrow:
		if current_index == 0:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + Vector2(67, 7)
		elif current_index < 4 and current_index > 0:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + Vector2(-5, 45)
		elif current_index == 4:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + Vector2(-130, 50)
		elif current_index == 5:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + Vector2(-150, 60)
		elif current_index == 6:
			target_position = current_option.get_global_position() - Vector2(current_option.size.x, 0) + Vector2(170, 7)
		else:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + arrow_offset
			
			
			
	elif showShopArrow:
		if current_index == 0:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + Vector2(-60, 7)
		elif current_index == 1:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + Vector2(-60, 7)
		elif current_index == 2:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + Vector2(-60, 7)
		elif current_index == 3:
			target_position = current_option.get_global_position() - Vector2(current_option.size.x, 0) + Vector2(210, 7)
		elif current_index == 4:
			target_position = current_option.get_global_position() - Vector2(current_option.size.x, 0) + Vector2(210, 7)
		elif current_index == 5:
			target_position = current_option.get_global_position() - Vector2(current_option.size.x, 0) + Vector2(210, 7)
		elif current_index == 6:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + arrow_offset
		else:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + arrow_offset
			
			
			
	elif OpenInventory:
		if current_index >= 0:
			target_position = current_option.get_global_position() + Vector2(current_option.size.x, 0) + Vector2(-40, 145)

func switchBetweenKitchenAndShop():
	if showKitchenArrow:
		showShopArrow = true
		showKitchenArrow = false
		$ShopContainer.show()
		$KitchenContainer.hide()
		current_index = 0
		update_arrow_position()
		arrow.flip_h = false
	elif showShopArrow:
		showShopArrow = false
		showKitchenArrow = true
		$ShopContainer.hide()
		$KitchenContainer.show()
		current_index = 0
		update_arrow_position()

func enter_or_exit_ShopKitchen(enter_or_exit_ShopKitchen: String):
	if enter_or_exit_ShopKitchen == "enterShopKitchen":
		OpenInventory = false
		showKitchenArrow = true
		showShopArrow = false
		Global.InMenu = true
		current_index = 0
		arrow.rotation_degrees = 0
		setWhatPageArrowIsOn()
	elif enter_or_exit_ShopKitchen == "exitShopKitchen":
		showKitchenArrow = false
		OpenInventory = false
		showShopArrow = false
		Global.InMenu = false
		shop_kitchen.hide()

func setWhatPageArrowIsOn():
	if showKitchenArrow:
		options = []
		options.append($KitchenContainer/HBoxContainer2/ExitFromKitchen)
		options += $KitchenContainer/HBoxContainer/ItemList1.get_children()
		options += $KitchenContainer/HBoxContainer/ItemList2.get_children()
		options.append($KitchenContainer/SwitchPages/HBoxContainer2/HBoxContainer/PageSwitchLabel)
	elif OpenInventory:
		options = []
		options += $"../../PanelContainer2/InventoryMarginContainer/HBoxContainer".get_children()
	elif showShopArrow:
		options = []
		options += $ShopContainer/HBoxContainer/ItemList1.get_children()
		options += $ShopContainer/HBoxContainer/ItemList2.get_children()
		options.append($ShopContainer/SwitchPages/HBoxContainer/HBoxContainer/PageSwitchLabel)

func playMovingAudio():
	changeSelectionSFX.pitch_scale = randf_range(0.97, 1.03)
	changeSelectionSFX.play()
	
func makeProduct():
	var totalIngredientValue = ingredient1.ingredientInSpotAssociatedValue + ingredient2.ingredientInSpotAssociatedValue + ingredient3.ingredientInSpotAssociatedValue
	if totalIngredientValue >= 0 and totalIngredientValue <= 27:
		powerUpSlot.addPowerUpToSlot("worst")
		confirmCookSfx.play()
	#elif totalIngredientValue > 9 and totalIngredientValue <= 18:
		#powerUpSlot.addPowerUpToSlot("mid")
	#elif totalIngredientValue > 18 and totalIngredientValue <= 27:
		#powerUpSlot.addPowerUpToSlot("best")

func clearInventory():
	print("Clearing inventory...")
	ingredient1.removeIngredientFromSpot(true)
	ingredient2.removeIngredientFromSpot(true)
	ingredient3.removeIngredientFromSpot(true)
	print("Ingredients cleared:", ingredient1.isIngredientInSpotAlready, ingredient2.isIngredientInSpotAlready, ingredient3.isIngredientInSpotAlready)

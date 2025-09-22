extends HBoxContainer

@onready var ingredientCurrentlyBeingAdded
@onready var ingredientListIndex: Array
@onready var kitchenInventorySlots: Array = [$"../Shop_Kitchen/VBoxContainer/PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer/TextureRect",
$"../Shop_Kitchen/VBoxContainer/PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer2/TextureRect",
$"../Shop_Kitchen/VBoxContainer/PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer3/TextureRect",
$"../Shop_Kitchen/VBoxContainer/PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer4/TextureRect",
$"../Shop_Kitchen/VBoxContainer/PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer5/TextureRect",
$"../Shop_Kitchen/VBoxContainer/PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer6/TextureRect"]
@onready var preventDuplicates: int
	
func addIngredientToInventory(ingredientWantingToBeAdded):
	
	# Limit inventory to 6 items
	if get_child_count() >= 6:
		
		print("Inventory full! Can't add more ingredients.")
		return
	
	preventDuplicates += 1
	
	ingredientCurrentlyBeingAdded = ingredientWantingToBeAdded
	ingredientCurrentlyBeingAdded.ingredient_name = ingredientCurrentlyBeingAdded.ingredient_name
	ingredientListIndex.append(ingredientCurrentlyBeingAdded.ingredient_name)
		
		# Make a new TextureRect for the ingredient
	var ingredient_icon = TextureRect.new()
	var unique_id = str(Time.get_ticks_usec())  # microsecond precision
	ingredient_icon.name = unique_id
	ingredient_icon.set_meta("ingredient_name", ingredientCurrentlyBeingAdded.ingredient_name)
	ingredient_icon.texture = ingredientCurrentlyBeingAdded.texture
	ingredient_icon.expand = true
	ingredient_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ingredient_icon.custom_minimum_size = Vector2(96, 96) # adjust size if you want
	
	for slot in kitchenInventorySlots:
		if slot.isIngredientInSlotAlready == false:
			slot.addIngredientToKitchenInventory(ingredientCurrentlyBeingAdded)
			break
		
		# Add to the HBoxContainer
	add_child(ingredient_icon)

func removeIngredientFromInventory(name: String):
	for child in get_children():
		if child.has_meta("ingredient_name") and child.get_meta("ingredient_name") == name:
			remove_child(child)
			child.queue_free()
			ingredientListIndex.erase(child.get_meta("ingredient_name"))
			print("Removed ingredient:", name)
			return
	print("Ingredient not found in inventory:", name)

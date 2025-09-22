extends TextureRect

@onready var ingredientCurrentlyInSlot
@onready var ingredientInSlotAssociatedValue
@onready var isIngredientInSlotAlready: bool = false
@onready var cookingSlots: Array = [
	$"../../../../../PanelContainer/MarginContainer/KitchenContainer/HBoxContainer/ItemList1/HBoxContainer/VBoxContainer/MarginContainer/PanelContainer/TextureButton",
	$"../../../../../PanelContainer/MarginContainer/KitchenContainer/HBoxContainer/ItemList1/HBoxContainer2/VBoxContainer/MarginContainer/PanelContainer/TextureButton",
	$"../../../../../PanelContainer/MarginContainer/KitchenContainer/HBoxContainer/ItemList1/HBoxContainer3/VBoxContainer/MarginContainer/PanelContainer/TextureButton"
] # adjust paths for your scene

# Add an ingredient into this kitchen slot
func addIngredientToKitchenInventory(ingredientWantingToBeAdded):
	if not isIngredientInSlotAlready:
		ingredientCurrentlyInSlot = ingredientWantingToBeAdded
		self.texture = ingredientWantingToBeAdded.texture
		ingredientInSlotAssociatedValue = ingredientCurrentlyInSlot.value
		isIngredientInSlotAlready = true
		print("Ingredient added to kitchen slot:", ingredientCurrentlyInSlot.ingredient_name)

# Move ingredient from this slot into the first available cooking slot
func moveIngredientToCooking():
	if isIngredientInSlotAlready:
		for slot in cookingSlots:
			if slot.isIngredientInSpotAlready == false:
				slot.addIngredientToSpot(ingredientCurrentlyInSlot)
				print("Moved ingredient to cooking:", ingredientCurrentlyInSlot.ingredient_name)
				_clearSlot()
				return true
		print("No free cooking slots available!")

# Clear this slot
func _clearSlot():
	self.texture = null
	ingredientCurrentlyInSlot = null
	ingredientInSlotAssociatedValue = 0
	isIngredientInSlotAlready = false

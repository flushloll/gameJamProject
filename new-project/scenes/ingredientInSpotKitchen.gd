extends TextureButton

@onready var ingredientCurrentlyInSpot
@onready var ingredientInSpotAssociatedValue
@onready var isIngredientInSpotAlready: bool
@onready var inventory = $"../../../../../../../../../../../../Inventory"
@onready var kitchenInventorySlots: Array = [
	$"../../../../../../../../../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer/TextureRect",
	$"../../../../../../../../../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer2/TextureRect",
	$"../../../../../../../../../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer3/TextureRect",
	$"../../../../../../../../../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer4/TextureRect",
	$"../../../../../../../../../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer5/TextureRect",
	$"../../../../../../../../../../PanelContainer2/InventoryMarginContainer/HBoxContainer/PanelContainer6/TextureRect",
]

func addIngredientToSpot(ingredientWantingToBeAdded):
	if not isIngredientInSpotAlready:
		ingredientCurrentlyInSpot = ingredientWantingToBeAdded
		self.texture_normal = ingredientCurrentlyInSpot.texture  # show texture on button
		
		ingredientInSpotAssociatedValue = ingredientWantingToBeAdded.value
		isIngredientInSpotAlready = true
		print("Ingredient added to spot:", ingredientCurrentlyInSpot.ingredient_name)
		
func removeIngredientFromSpot(entirely: bool):
	if isIngredientInSpotAlready:
		if entirely:
			var ingredientWantingToBeRemoved = ingredientCurrentlyInSpot
			inventory.removeIngredientFromInventory(ingredientWantingToBeRemoved.ingredient_name)
			_clearSpot()
		else:
			for slot in kitchenInventorySlots:
				if slot.isIngredientInSlotAlready == false:
					slot.addIngredientToKitchenInventory(ingredientCurrentlyInSpot)
					_clearSpot()
					print("Ingredient removed from this spot")
					return
		

func _clearSpot():
	self.texture_normal = null
	ingredientCurrentlyInSpot = null
	ingredientInSpotAssociatedValue = 0
	isIngredientInSpotAlready = false

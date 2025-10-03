extends TextureButton

var buttonHoverText = get_parent().get_parent().get_child(0)

func _ready():
	# Get the number at the end of the button's name
	var name = self.name  # e.g., "Button3"
	var number = int(name.get_slice("_", -1)) # if "_" in name else int(name.strip_letters()) 

	# Connect the corresponding slot signal dynamically
	var signal_name = "shop_slot_" + str(number)
	ShopKitchenButtonHoverEventBus.connect(signal_name, Callable(self, "_on_slot_hover"))

	# Connect the global hide signal
	ShopKitchenButtonHoverEventBus.connect("shop_slot_hide_all", Callable(self, "hide_self"))

func _on_slot_hover():
	buttonHoverText.fadeIn()

func hide_self():
	buttonHoverText.fadeOut()

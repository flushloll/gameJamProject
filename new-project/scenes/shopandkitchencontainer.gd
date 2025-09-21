extends MarginContainer

@onready var arrow = $Arrow
@onready var options
@onready var selectionAudio = $"../../../SelectOptionSFX"
@onready var changeSelectionSFX = $"../../../ChangeSelectionSFX"
var current_index = 0
var arrow_offset = Vector2(80, 45)
var arrow_offset_flipped = Vector2(-80, 45) # Adjust as needed
@onready var locked = false
@onready var shop_kitchen = $"../.."
@onready var UI = $"../../.."

var target_position: Vector2
var smoothing_speed := 8.0  # higher = faster, lower = slower

var bounce_amplitude := 1.2   # how far left/right it moves
var bounce_speed := 4.0       # how fast it wiggles
var time_passed := 0.0

var showShopArrow = false
var showKitchenArrow = true
var arrowFollowingSelectionTarget

func _ready():
	setWhatPageArrowIsOn()
	shop_kitchen.hide()
	$ShopContainer.hide()
	call_deferred("update_arrow_position")
	target_position = arrow.global_position

func _input(event):
	if shop_kitchen.visible:
		# Navigate menu freely until final choice
			if event.is_action_pressed("ui_down"):
				current_index = (current_index + 1) % options.size()
				if options[current_index].is_in_group("NextPage"):
					arrow.flip_h = true
				else:
					arrow.flip_h = false
				update_arrow_position()
				changeSelectionSFX.pitch_scale = randf_range(0.97, 1.03)
				changeSelectionSFX.play()
			elif event.is_action_pressed("ui_up"):
				current_index = (current_index - 1 + options.size()) % options.size()
				if options[current_index].is_in_group("NextPage"):
					arrow.flip_h = true
				else:
					arrow.flip_h = false
				update_arrow_position()
				changeSelectionSFX.pitch_scale = randf_range(0.97, 1.03)
				changeSelectionSFX.play()
			elif event.is_action_pressed("ui_accept") and options[current_index].name == "PageSwitchLabel" and (showKitchenArrow or showShopArrow):
				switchBetweenKitchenAndShop()
				setWhatPageArrowIsOn()
				update_arrow_position()
			elif event.is_action_pressed("ui_accept") and options[current_index].name == "ExitFromKitchen" and (showKitchenArrow or showShopArrow):
				setWhatPageArrowIsOn()
				update_arrow_position()
				enter_or_exit_ShopKitchen("exitShopKitchen")
				UI.load_or_exit_shop_kitchen("exit")

func _process(delta):
	
	if shop_kitchen.visible:
		
		time_passed += delta
		
		# Smoothly move the arrow towards the target position
		arrow.global_position = arrow.global_position.lerp(target_position, smoothing_speed * delta)
		
		# Apply passive horizontal bounce
		var bounce = sin(time_passed * bounce_speed) * bounce_amplitude
		arrow.global_position.x += bounce
	
func update_arrow_position():
		arrow.scale = Vector2(0.06, 0.06)
		# Reset bounce when switching options
		var current_option = options[current_index]
		time_passed = 0.0
		if not arrow.flip_h:
			target_position = current_option.get_global_position()# + Vector2(current_option.size.x, 0) + arrow_offset
		elif arrow.flip_h:
			target_position = current_option.get_global_position()#  Vector2(current_option.size.x, 0) + arrow_offset_flipped

func switchBetweenKitchenAndShop():
	if showKitchenArrow:
		showShopArrow = true
		showKitchenArrow = false
		$ShopContainer.show()
		$KitchenContainer.hide()
		update_arrow_position()
		current_index = 0
		arrow.flip_h = false
	elif showShopArrow:
		showShopArrow = false
		showKitchenArrow = true
		$ShopContainer.hide()
		$KitchenContainer.show()
		update_arrow_position()
		current_index = 0

func enter_or_exit_ShopKitchen(enter_or_exit_ShopKitchen: String):
	if enter_or_exit_ShopKitchen == "enterShopKitchen":
		Global.InMenu = true
		setWhatPageArrowIsOn()
		showKitchenArrow = true
		showShopArrow = false
	elif enter_or_exit_ShopKitchen == "exitShopKitchen":
		Global.InMenu = false
		showKitchenArrow = false
		showShopArrow = false

func setWhatPageArrowIsOn():
	if showKitchenArrow:
		options = []
		options.append($KitchenContainer/HBoxContainer2/ExitFromKitchen)
		options += $KitchenContainer/HBoxContainer/ItemList1.get_children()
		options += $KitchenContainer/HBoxContainer/ItemList2.get_children()
		options.append($KitchenContainer/SwitchPages/HBoxContainer2/HBoxContainer/PageSwitchLabel)
	elif showShopArrow:
		options = []
		options += $ShopContainer/HBoxContainer/ItemList1.get_children()
		options += $ShopContainer/HBoxContainer/ItemList2.get_children()
		options.append($ShopContainer/SwitchPages/HBoxContainer/HBoxContainer/PageSwitchLabel)

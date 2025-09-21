extends Camera3D

@export var zoomed_fov: float = 60.0       # smaller FOV = zoomed in
@export var zoom_in_speed: float = 0.4  
@export var zoom_out_speed: float = 0.1       # time in seconds
var original_fov: float
var zoomed_in: bool = false
@onready var playerChar = $"../../.."

func _ready():
	original_fov = fov

func toggle_zoom():
	var tween = create_tween()
	if not zoomed_in:
		# Zoom in
		tween.tween_property(self, "fov", zoomed_fov, zoom_in_speed)
		$Weapon/WeaponVisualRoot/WeaponMesh.start_jitter()
		zoomed_in = true
	else:
		# Reset to original zoom
		tween.tween_property(self, "fov", original_fov, zoom_out_speed)
		$Weapon/WeaponVisualRoot/WeaponMesh.stop_jitter()
		zoomed_in = false

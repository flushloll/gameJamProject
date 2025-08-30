extends MeshInstance3D

var player : CharacterBody3D
var camera : Camera3D

func _ready() -> void:
	var p = get_node("/root/Main/SubViewportContainer/SubViewport/Player")
	if p is CharacterBody3D: player = p
	camera = get_node("/root/Main/SubViewportContainer/SubViewport/Player/Camera3D")
	
func _process(delta: float) -> void:
	if player and material_override and camera:
		var camera_forward = camera.global_transform.basis.z
		var screen_pos = camera.unproject_position(player.global_position + Vector3.UP * 1.25)
		var viewport_size = get_viewport().get_visible_rect().size
		var screen_uv = screen_pos / viewport_size

		material_override.set_shader_parameter("player_screen_pos", screen_uv)
		material_override.set_shader_parameter("player_position", player.global_transform.origin)
		material_override.set_shader_parameter("camera_forward", camera_forward)
		

extends MeshInstance3D

@onready var player = $"../Player"

func _process(delta):
	var player_screen_pos = get_viewport().get_camera_3d().unproject_position(player.global_position)
	
	RenderingServer.global_shader_parameter_set(
		"player_on_screen_position",
		player_screen_pos
	)
	
	#if not RenderingServer.global_shader_parameter_get("dither_texture"):
		#var tex = load("res://dither.png")
		#RenderingServer.global_shader_parameter_set("dither_texture", tex)

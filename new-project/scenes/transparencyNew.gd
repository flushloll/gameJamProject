extends Area3D

@export var roof_shader_material: ShaderMaterial

func _ready():
	body_entered.connect(_on_mesh_body_entered)
	body_exited.connect(_on_mesh_body_exited)

func _on_mesh_body_entered(body):
	if body.is_in_group("Player"):
		body.camViewSwitchToTopView()
		get_child(0).get_child(0).get_surface_override_material(0).set_shader_parameter("player_is_under_roof", true)
		get_child(0).get_child(0).get_surface_override_material(4).set_shader_parameter("player_is_under_roof", true)
		get_child(0).get_child(0).get_surface_override_material(0).set_shader_parameter("STRENGTH", 0.2)
		get_child(0).get_child(0).get_surface_override_material(4).set_shader_parameter("STRENGTH", 1)
	else:
		print("Not a player")

func _on_mesh_body_exited(body):
	if body.is_in_group("Player"):
		body.camViewSwitchToFPS()
		get_child(0).get_child(0).get_surface_override_material(0).set_shader_parameter("player_is_under_roof", false)
		get_child(0).get_child(0).get_surface_override_material(4).set_shader_parameter("player_is_under_roof", false)
		print("Exited roof area, material:")

#func _process(delta):
	#
	#var player_screen_pos = get_viewport().get_camera_3d().unproject_position(player.global_position)
	#
	#RenderingServer.global_shader_parameter_set(
		#"player_on_screen_position",
		#player_screen_pos
	#)
	
	#if not RenderingServer.global_shader_parameter_get("dither_texture"):
		#var tex = load("res://dither.png")
		#RenderingServer.global_shader_parameter_set("dither_texture", tex)

extends MeshInstance3D

var player : CharacterBody3D
var camera : Camera3D

var shader_mat : ShaderMaterial
var original_mats : Array = []
var shader_applied := false   # track state so we don’t spam

func _ready() -> void:
	# Get references
	var p = get_node("/root/Main/SubViewportContainer/SubViewport/Player")
	if p is CharacterBody3D: player = p
	camera = get_node("/root/Main/SubViewportContainer/SubViewport/Player/Camera3D2")

	# Save original surface materials
	if mesh:
		original_mats.resize(mesh.get_surface_count())
		for i in range(mesh.get_surface_count()):
			original_mats[i] = mesh.surface_get_material(i)

		print_debug("Stored %d original materials" % mesh.get_surface_count())

	# Load our special shader material
	var shader = preload("res://scenes/roof.gdshader")
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	print_debug("Shader material created")


func _process(delta: float) -> void:
	if not (player and camera and mesh):
		return

	# Check if player is under this mesh
	
	var player_pos = player.global_position
	var mesh_pos = global_position
	var mesh_scale = scale

	var inside_x = (mesh_pos.x - mesh_scale.x / 2 <= player_pos.x) and (player_pos.x <= mesh_pos.x + mesh_scale.x / 2)
	var inside_z = (mesh_pos.z - mesh_scale.z / 2 <= player_pos.z) and (player_pos.z <= mesh_pos.z + mesh_scale.z / 2)

	var under_y = player_pos.y < mesh_pos.y

	var player_under = inside_x and inside_z and under_y

	
	# Update shader params
	var camera_forward = camera.global_transform.basis.z
	var screen_pos = camera.unproject_position(player.global_position + Vector3.UP * 16.23)
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_uv = screen_pos / viewport_size
		
	if player_under:
		if not shader_applied:
			print_debug("Applying GEOMETRY override shader")
			material_override = shader_mat
			shader_applied = true

		shader_mat.set_shader_parameter("player_screen_pos", screen_uv)
		shader_mat.set_shader_parameter("player_position", player.global_transform.origin)
		shader_mat.set_shader_parameter("camera_forward", camera_forward)

	else:
		if shader_applied:
			print_debug("Restoring surface materials")
			material_override = null  # removes override, reverts to surface materials
			shader_applied = false

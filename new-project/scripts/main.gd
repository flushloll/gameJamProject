extends Node3D

var enemySpawn = load("res://scenes/enemy.tscn")
@onready var timer = $spawnTimer
@onready var cursor = $UI/Cursor

func spawn_enemy():
	var enemyInstance = enemySpawn.instantiate()
	add_child(enemyInstance)
		# Randomize position for demonstration
	enemyInstance.global_transform.origin = Vector3(randf_range(-12, 12), 10, randf_range(-8, 8))	
	
func _ready():
	Input.set_custom_mouse_cursor(cursor)
	
func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
	timer.wait_time = randf_range(0.4, 1.5)
	
func _process(delta):
	if Input.is_action_just_pressed("spawn_enemy"): # Define "spawn_cube" in Project Settings -> Input Map
		spawn_enemy()
	

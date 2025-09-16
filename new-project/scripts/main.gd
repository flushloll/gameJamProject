extends Node3D

var enemySpawn = load("res://scenes/enemy.tscn")
@onready var timer = $SubViewportContainer/SubViewport/spawnTimer
@onready var cursor = $SubViewportContainer/SubViewport/UI/Cursor

# Number of enemies per batch
var ENEMIES_PER_BATCH = 4

func spawn_enemy_batch():
	if Global.current_enemies.size() == 0: # Only spawn if no enemies alive
		for i in ENEMIES_PER_BATCH:
			var enemyInstance = enemySpawn.instantiate()
			add_child(enemyInstance)
			
			# Randomize position and scale
			enemyInstance.global_transform.origin = Vector3(randf_range(-12, 12), 2, randf_range(-8, 8))
			var random_scale = randf_range(0.8, 3) # For example, between 70% and 130% of original size
			enemyInstance.get_child(0).get_child(0).get_child(0).get_child(0).scale = Vector3(random_scale, random_scale, random_scale)
			enemyInstance.play_spawn_sound_and_effects()
			
			# Connect the enemy's death signal directly to main scene
			enemyInstance.connect("enemy_died", Callable(self, "_on_enemies_dead"))
			
			Global.current_enemies.append(enemyInstance)
		
		# Stop the timer until enemies die
		timer.stop()

func _on_enemies_dead(enemy):
	# Remove enemy from list when it dies
	Global.current_enemies.erase(enemy)
	
	# If all dead, spawn next batch after a short delay
	if Global.current_enemies.size() == 0:
		ENEMIES_PER_BATCH = randi_range(3, 7)
		timer.start(randf_range(0.4, 1.5))

func _ready():
	Input.set_custom_mouse_cursor(cursor)
	timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Spawn the first batch immediately
	spawn_enemy_batch()

func _on_spawn_timer_timeout() -> void:
	spawn_enemy_batch()

func _process(delta):
	pass # Remove unnecessary spawn_enemy_batch calls here

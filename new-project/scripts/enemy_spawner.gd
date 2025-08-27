extends Node3D

@onready var spawn_timer = $EnemySpawnTimer
@onready var player = get_parent().get_node("Player")

const enemySpawn = preload("res://scenes/enemy.tscn")

func _on_enemy_spawn_timer_timeout():
	var newEnemy = enemySpawn.instantiate()
	
	get_parent().add_child(newEnemy)
	
	newEnemy.global_position = player.global_position

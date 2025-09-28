extends Node3D

var enemySpawn = load("res://scenes/enemy.tscn")
@onready var cursor = $SubViewportContainer/SubViewport/UI/Cursor
@onready var relegatedWaveTime = 40
@onready var timerBeforeNextTick
@onready var waveTimerTickSfx = $SubViewportContainer/SubViewport/waveTimerTickSfx
@onready var waveStartedSfx = $SubViewportContainer/SubViewport/waveStartedSfx
var localrelegatedWaveTime
@onready var waveTimer = $SubViewportContainer/SubViewport/UI/SpawnTimer/waveTimer
@onready var music = $SubViewportContainer/SubViewport/MusicPlayer
@onready var current_wave = 1
@onready var musicFadedOut = true
@onready var countdown_timer: Timer = Timer.new()

# Number of enemies per batch
var ENEMIES_PER_BATCH = 21

#func _input(event: InputEvent) -> void:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("skipCountdown") and not Global.InMenu:
		localrelegatedWaveTime = 1
		_on_countdown_tick(true)
		
func spawn_enemy_batch():
	if Global.current_enemies.size() == 0: # Only spawn if no enemies alive
		Global.enemyDamageScaleAccumulate += 0.025
		for i in ENEMIES_PER_BATCH:
			var enemyInstance = enemySpawn.instantiate()
			add_child(enemyInstance)
			
			# Randomize position and scale
			enemyInstance.global_transform.origin = Vector3(randf_range(-64, 64), 2, randf_range(-64, 64))
			var random_scale = randf_range(1.6, 3) # For example, between 70% and 130% of original size
			enemyInstance.get_child(0).get_child(0).get_child(0).get_child(0).scale = Vector3(random_scale, random_scale, random_scale)
			enemyInstance.speed = randf_range(6.7, 11.3)
			enemyInstance.enemyDamageScale = Global.enemyDamageScaleAccumulate
			#enemyInstance.play_spawn_sound_and_effects()
			waveStartedSfx.play() 
			
			# Connect the enemy's death signal directly to main scene
			enemyInstance.connect("enemy_died", Callable(self, "_on_enemies_dead"))
			
			Global.current_enemies.append(enemyInstance)

func _on_enemies_dead(enemy):
	# Remove enemy from list when it dies
	Global.current_enemies.erase(enemy)
	
	# If all dead, spawn next batch after a short delay
	if Global.current_enemies.size() == 0:
		waveTimer.show()
		waveTimer.changeWaveTimerLabel("WAVE " + str(current_wave) + " COMPLETE")
		current_wave += 1
		ENEMIES_PER_BATCH = randi_range(3 + floori(current_wave), 7 + floori(current_wave))
		localrelegatedWaveTime = relegatedWaveTime
		waveTimer.fadeIn()
		await get_tree().create_timer(3.5).timeout
		startNewWaveTimerCountdown()

func startNewWaveTimerCountdown():
	 
	localrelegatedWaveTime = relegatedWaveTime
	waveTimer.changeWaveTimerLabel(localrelegatedWaveTime)
	waveTimer.fadeIn()
	startMusicWhileWaiting()
	countdown_timer.start()  # starts ticking every second
	
func _on_countdown_tick(skipped: bool = false):
	
	if skipped:
		localrelegatedWaveTime = 0
	else:
		localrelegatedWaveTime -= 1
	
	waveTimerTickSfx.play()
	waveTimer.changeWaveTimerLabel(localrelegatedWaveTime)
	
	if localrelegatedWaveTime <= 0:
		countdown_timer.stop()
		waveTimer.changeWaveTimerLabel("STARTED")
		spawn_enemy_batch()
		stopMusicAfterDoneWaiting()
		waveTimer.hide()
	
func _ready():
	Input.set_custom_mouse_cursor(cursor)
	add_child(countdown_timer)
	countdown_timer.wait_time = 1
	countdown_timer.one_shot = false
	countdown_timer.connect("timeout", Callable(self, "_on_countdown_tick"))
	startNewWaveTimerCountdown()

func stopMusicAfterDoneWaiting():
	musicFadedOut = false
	var tweenFadeOutMusic = create_tween()
	tweenFadeOutMusic.tween_property(music, "volume_db", -80.0, 3.0) # fade to quiet volume in 2 seconds
	await tweenFadeOutMusic.finished.connect(stop_music)
	localrelegatedWaveTime = relegatedWaveTime

func startMusicWhileWaiting():
	await get_tree().create_timer(1).timeout
	music.play()
	var tweenFadeInMusic = create_tween()
	tweenFadeInMusic.tween_property(music, "volume_db", -33.647, 3.5) # fade to normal volume in 3.5 seconds
	
	
func stop_music():
	music.stop()

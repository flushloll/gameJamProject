extends Node3D

@onready var Particles = $"../FeathersParticle"

func _ready():
	Particles.emitting = true

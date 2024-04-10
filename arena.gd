extends Node3D

@onready var spawn_points = $SpawnPoints

func pick_random_spawn():
	var random_spawn = spawn_points.get_children().pick_random()
	return random_spawn

extends Node3D

@onready var spawn_points = $SpawnPoints

func pick_random_spawn():
	return spawn_points.get_children().pick_random()

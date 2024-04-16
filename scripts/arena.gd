extends Node3D

@onready var spawn_points = $SpawnPoints

@rpc ("any_peer", "call_local", "reliable")
func pick_random_spawn():
	print (multiplayer.get_unique_id())
	var spawn_points_children = spawn_points.get_children()
	var spawn_points_checks = spawn_points_children.duplicate()
	
	for spawn_point in spawn_points_children:
		var random_spawn = spawn_points_children.pick_random()
		if !random_spawn.check_for_players():
			return random_spawn
		else:
			spawn_points_checks.erase(random_spawn)
	
	return spawn_points.get_children().pick_random()

extends Area3D

var players_array = []
var closest_player = null

func _ready():
	var players = get_tree().get_nodes_in_group("Player")
	if players != null:
		for player in players:
			players_array.append(player)

func handle_coin_collision():
	get_tree()
	pass

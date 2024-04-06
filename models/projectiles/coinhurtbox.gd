extends Area3D

var players_array = []
var closest_player = null
var closest_distance = 1000

var position_to_look_at = Vector3.ZERO

var coin_shot = false

@onready var raycast = $"../RayCast3D"

func _ready():
	var players = get_tree().get_nodes_in_group("Enemy")
	if players != null:
		for player in players:
			players_array.append(player)

func _process(delta):
	if coin_shot:
		raycast.look_at(position_to_look_at)
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.collision_layer == 2:
				get_tree().current_scene.spawn_tracer_pivot.rpc("gold", owner.global_position, owner.global_rotation, closest_distance / 50, position_to_look_at)
				collider.handle_damage_collision(50)
				queue_free()

func handle_coin_collision():
	if players_array != []:
		for player in players_array:
			if player.global_position.distance_to(owner.global_position) < closest_distance:
				closest_player = player
				closest_distance = closest_player.global_position.distance_to(owner.global_position)
		
		if closest_distance <= 15:
			position_to_look_at = closest_player.global_position
			
			position_to_look_at.y += 1.5
			
			raycast.target_position.z = -50
	
	coin_shot = true

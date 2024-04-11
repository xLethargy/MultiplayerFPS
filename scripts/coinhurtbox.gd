extends Area3D

var players_array = []
var closest_player = null
var closest_distance : float = 1000
var closest_collider = null

var position_to_look_at = Vector3.ZERO

var coin_shot = false

@onready var raycast = $"../RayCast3D"

var damage = 50

var ragdoll_force = 25

func _ready():
	var players = get_tree().get_nodes_in_group("Enemy")
	if players != null:
		for player in players:
			players_array.append(player)


func handle_coin_collision():
	if players_array != []:
		raycast.target_position.z = -50
		
		for player in players_array:
			if player.global_position.distance_to(owner.global_position) <= 15:
				if player.global_position.distance_to(owner.global_position) < closest_distance:
					position_to_look_at = player.global_position
					position_to_look_at.y += 1.5
					
					for i in range(3):
						raycast.look_at(position_to_look_at)
						await get_tree().create_timer(0.01).timeout
						if raycast.is_colliding():
							var collider = raycast.get_collider()
							if collider.collision_layer == 2:
								closest_player = player
								closest_distance = closest_player.global_position.distance_to(owner.global_position)
								closest_collider = collider
								break
		
		if closest_player != null:
			get_tree().current_scene.spawn_tracer_pivot.rpc("gold", owner.global_position, owner.global_rotation, closest_distance / 50, position_to_look_at)
			closest_collider.handle_damage_collision(damage)
			
			if closest_collider.health_component.current_health - damage <= 0:
				var test_boost = raycast.get_global_transform().basis.z * ragdoll_force
				get_tree().current_scene.spawn_player_ragdoll.rpc(closest_collider.global_position, closest_collider.global_rotation, -test_boost, closest_collider.owner.current_colour)
	
	owner.play_spatial_audio.rpc()
	coin_shot = true
	
	queue_free()

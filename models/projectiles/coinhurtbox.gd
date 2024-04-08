extends Area3D

var players_array = []
var closest_player = null
var closest_distance : float = 1000
var closest_collider = null

var position_to_look_at = Vector3.ZERO

var coin_shot = false

@onready var raycast = $"../RayCast3D"
@onready var clang_audio = $"../ClangAudio"

var damage = 40

func _ready():
	var players = get_tree().get_nodes_in_group("Enemy")
	if players != null:
		for player in players:
			players_array.append(player)

#func _process(_delta):
	#if coin_shot:
	#	
	#	raycast.look_at(position_to_look_at)
	#	if raycast.is_colliding():
	#		var collider = raycast.get_collider()
	#		if collider.collision_layer == 2:
	#			get_tree().current_scene.spawn_tracer_pivot.rpc("gold", owner.global_position, owner.global_rotation, closest_distance / 50, position_to_look_at)
	#			collider.handle_damage_collision(damage)
	#			queue_free()

func handle_coin_collision():
	if players_array != []:
		raycast.target_position.z = -50
		
		
		for player in players_array:
			if player.global_position.distance_to(owner.global_position) <= 15:
				if player.global_position.distance_to(owner.global_position) < closest_distance:
					position_to_look_at = player.global_position
					position_to_look_at.y += 1.5
					
					raycast.look_at(position_to_look_at)
					await get_tree().create_timer(0.01).timeout
					if raycast.is_colliding():
						var collider = raycast.get_collider()
						if collider.collision_layer == 2:
							closest_player = player
							closest_distance = closest_player.global_position.distance_to(owner.global_position)
							closest_collider = collider
		
		if closest_player != null:
			get_tree().current_scene.spawn_tracer_pivot.rpc("gold", owner.global_position, owner.global_rotation, closest_distance / 50, position_to_look_at)
			closest_collider.handle_damage_collision(damage)
	
	
	clang_audio.play()
	coin_shot = true
	
	queue_free()

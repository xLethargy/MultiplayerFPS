extends Area3D

@export var health_component : Node3D

@onready var player = owner
@onready var raycast = $"../View/Camera3D/RayCast3D"

signal change_score

func _ready():
	connect("area_entered", self._on_area_entered)
	await get_tree().create_timer(0.1).timeout 
	set_collision_layers.rpc()
	
	

@rpc ("call_local", "any_peer", "reliable")
func set_collision_layers():
	await get_tree().create_timer(0.1).timeout 
	if is_multiplayer_authority():
		if Global.players.has(multiplayer.get_unique_id()):
			var id = multiplayer.get_unique_id()
			
			# set layer to team it is on, set raycast to all teams but itself
			if Global.teams != 12:
				if Global.players[id].Team == 1:
					self.set_collision_layer_value(2, true)
					self.set_collision_mask_value(2, true)
					
					raycast.set_collision_mask_value(3, true)
					raycast.set_collision_mask_value(4, true)
					raycast.set_collision_mask_value(5, true)
				elif Global.players[id].Team == 2:
					self.set_collision_layer_value(3, true)
					self.set_collision_mask_value(3, true)
					
					raycast.set_collision_mask_value(2, true)
					raycast.set_collision_mask_value(4, true)
					raycast.set_collision_mask_value(5, true)
				elif Global.players[id].Team == 3:
					self.set_collision_layer_value(4, true)
					self.set_collision_mask_value(4, true)
					
					raycast.set_collision_mask_value(2, true)
					raycast.set_collision_mask_value(3, true)
					raycast.set_collision_mask_value(5, true)
				elif Global.players[id].Team == 4:
					self.set_collision_layer_value(5, true)
					self.set_collision_mask_value(5, true)
					
					raycast.set_collision_mask_value(2, true)
					raycast.set_collision_mask_value(3, true)
					raycast.set_collision_mask_value(4, true)
			else:
				self.set_collision_layer_value(2, true)
				self.set_collision_mask_value(2, true)
				
				raycast.set_collision_mask_value(2, true)


@rpc("any_peer", "reliable")
func handle_damage_collision(damage):
	var id = multiplayer.get_unique_id()
	_update_global_score.rpc(damage, id)
	health_component.receive_damage.rpc_id(player.get_multiplayer_authority(), damage)


func handle_speed_collision(speed_effect = player.default_speed, jump_height = player.default_jump_velocity, timer = false):
	if timer:
		await get_tree().create_timer(2.5).timeout
		player.change_speed_and_jump.rpc_id(player.get_multiplayer_authority(), speed_effect, jump_height)
	else:
		player.change_speed_and_jump.rpc_id(player.get_multiplayer_authority(), speed_effect, jump_height)


func _on_area_entered(area):
	if area.is_in_group("Melee"):
		var id = multiplayer.get_unique_id()
		_update_global_score.rpc(area.damage, id)
		health_component.receive_damage.rpc_id(player.get_multiplayer_authority(), area.damage)
		area.play_hit_effects()


@rpc ("any_peer", "call_local", "reliable")
func _update_global_score(damage, id):
	if health_component.current_health - damage <= 0:
		
		Global.players[id].Score += 1

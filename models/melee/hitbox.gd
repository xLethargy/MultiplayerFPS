extends Area3D

var damage

func _ready():
	await get_tree().create_timer(0.1).timeout
	set_collision_layers.rpc()
	damage = owner.current_damage


@rpc ("any_peer", "reliable")
func set_collision_layers():
	await get_tree().create_timer(0.1).timeout 
	if owner.player.is_multiplayer_authority():
		if Global.players.has(multiplayer.get_unique_id()):
			var id = multiplayer.get_unique_id()
			
			# set to what hitbox hurts, everything but itself
			if Global.teams != 12:
				if Global.players[id].Team == 1:
					self.set_collision_layer_value(3, true)
					self.set_collision_layer_value(4, true)
					self.set_collision_layer_value(5, true)
				elif Global.players[id].Team == 2:
					self.set_collision_layer_value(2, true)
					self.set_collision_layer_value(4, true)
					self.set_collision_layer_value(5, true)
				elif Global.players[id].Team == 3:
					self.set_collision_layer_value(2, true)
					self.set_collision_layer_value(3, true)
					self.set_collision_layer_value(5, true)
				elif Global.players[id].Team == 4:
					self.set_collision_layer_value(2, true)
					self.set_collision_layer_value(3, true)
					self.set_collision_layer_value(4, true)
				else:
					#else gets put on team 1
					self.set_collision_layer_value(3, true)
					self.set_collision_layer_value(4, true)
					self.set_collision_layer_value(5, true)
			else:
				self.set_collision_layer_value(2, true)


func play_hit_effects():
	owner.on_hit_effect()

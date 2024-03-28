extends Weapon

@onready var firing_rate = $FiringRate

var can_shoot = true


func _unhandled_input(_event):
	if Input.is_action_just_pressed("reload") and animation_player.current_animation != "reload" and current_ammo != max_ammo:
		reload_weapon.rpc()

func _process(_delta):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_pressed("shoot") and can_shoot and current_ammo >= 1:
		play_shoot_effects()
		play_spatial_audio.rpc()
		firing_rate.start()
		can_shoot = false
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			var origin = raycast.global_transform.origin
			
			var distance_check = (origin.distance_to(raycast.get_collision_point())) / 2
			distance_check = int(distance_check) 
			if distance_check >= current_damage:
				distance_check = current_damage - 1
			var falloff_damage = current_damage - distance_check
			if collider.is_in_group("Hurtbox"):
				if collider.owner.is_in_group("Enemy"):
					if collider.has_method("handle_damage_collision"):
						on_hit_effect()
						collider.handle_damage_collision(falloff_damage)
		
		recoil = true
		await get_tree().create_timer(0.1).timeout
		recoil = false


func _on_firing_rate_timeout():
	can_shoot = true

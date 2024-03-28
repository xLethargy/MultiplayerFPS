extends Weapon


func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot" and current_ammo >= 1:
		play_shoot_effects()
		play_spatial_audio.rpc()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("Hurtbox"):
				if collider.owner.is_in_group("Enemy"):
					if collider.has_method("handle_damage_collision"):
						on_hit_effect()
						collider.handle_damage_collision(current_damage)
		
		recoil = true
		await get_tree().create_timer(0.1).timeout
		recoil = false
	
	if Input.is_action_just_pressed("reload") and animation_player.current_animation != "reload" and current_ammo != max_ammo:
		reload_weapon.rpc()

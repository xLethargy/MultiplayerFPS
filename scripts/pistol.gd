extends Weapon


func _unhandled_input(event):
	if !player.is_multiplayer_authority():
		return
	
	if event.is_action_pressed("shoot") and animation_player.current_animation != "shoot" and current_ammo >= 1:
		play_shoot_effects()
		play_spatial_audio.rpc()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			handle_collision(collider)
		
		recoil = true
		await get_tree().create_timer(0.1).timeout
		recoil = false
	
	if event.is_action_pressed("reload") and animation_player.current_animation != "reload" and current_ammo != max_ammo:
		reload_weapon.rpc()

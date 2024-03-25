extends Weapon

var aiming = false

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("right_click") and current_ammo > 0:
		aiming = true
		hud.sniper_ads.show()
		hud.healthbar.hide()
		self.hide()
		player.camera.fov = 30
		
		player.change_speed_and_jump(2)
	elif Input.is_action_just_released("right_click") or current_ammo == 0:
		aiming = false
		hud.sniper_ads.hide()
		hud.healthbar.show()
		self.show()
		player.camera.fov = 90
		
		player.change_speed_and_jump()
	
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot" and current_ammo >= 1:
		if !aiming:
			var random_spread_y = randf_range(-10, 10)
			var random_spread_x = randf_range(-10, 10)
			raycast.target_position.y = random_spread_y
			raycast.target_position.x = random_spread_x
		elif aiming:
			raycast.target_position = Vector3(0, 0, -50)
		
		play_shoot_effects()
		play_spatial_audio.rpc()
		
		await get_tree().create_timer(0.01).timeout
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("Hurtbox"):
				on_hit_effect()
				collider.handle_damage_collision(current_damage)
		
		recoil = true
		await get_tree().create_timer(0.1).timeout
		recoil = false
	
	if Input.is_action_just_pressed("reload") and animation_player.current_animation != "reload" and current_ammo != max_ammo:
		reload_weapon.rpc()

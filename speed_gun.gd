extends Weapon

var animation_increase = 0.1
var damage_increase = 0.5
var player_speed_increase = 0.5


func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot" and current_ammo > 0:
		play_shoot_effects()
		play_spatial_audio.rpc()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("Hurtbox"):
				on_hit_effect()
				collider.handle_damage_collision(current_damage)
				
				handle_speed_gun_variables.rpc()
			else:
				reset_stat_gun.rpc(false)
		else:
			reset_stat_gun.rpc(false)
		
		recoil = true
		await get_tree().create_timer(0.1).timeout
		recoil = false
	
	if Input.is_action_just_pressed("reload") and animation_player.current_animation != "reload" and current_ammo != max_ammo:
		reload_weapon.rpc()



@rpc ("any_peer", "call_local", "reliable")
func handle_speed_gun_variables():
	if player.current_speed < 25:
		player.increase_speed(player_speed_increase)
		if player.current_speed > 25:
			player.change_speed_and_jump.rpc(25)
	if current_damage < 100:
		current_damage += damage_increase
		if current_damage > 100:
			current_damage = 100
	
	if animation_player.speed_scale < 5:
		current_animation_speed += animation_increase
		animation_player.speed_scale = current_animation_speed
		if animation_player.speed_scale > 5:
			current_animation_speed = 5
	
	if player.camera.fov < 140:
		player.camera.fov += 1
		if player.camera.fov > 140:
			player.camera.fov = 140


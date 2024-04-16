extends Weapon

var gun_animation_increase = 0.1
var gun_damage_increase = 0.5
var player_speed_increase = 0.5
var player_fov_increase = 1
var player_ragdoll_force_increase = 0.5

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot" and current_ammo > 0:
		play_shoot_effects()
		play_spatial_audio.rpc()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			
			handle_collision(collider)
			
			if collider.is_in_group("Hurtbox"):
				if collider.health_component.current_health - current_damage <= 0:
					handle_speed_gun_variables.rpc(player_speed_increase * 2, gun_damage_increase * 2, gun_animation_increase * 2, player_fov_increase * 2, player_ragdoll_force_increase * 2)
				else:
					handle_speed_gun_variables.rpc(player_speed_increase, gun_damage_increase, gun_animation_increase, player_fov_increase, player_ragdoll_force_increase)
			else:
				_half_stat_variables.rpc()
		else:
			_half_stat_variables.rpc()
		
		recoil = true
		await get_tree().create_timer(0.1).timeout
		recoil = false
	
	if Input.is_action_just_pressed("reload") and animation_player.current_animation != "reload" and current_ammo != max_ammo:
		reload_weapon.rpc()


@rpc ("any_peer", "call_local", "reliable")
func handle_speed_gun_variables(speed_increase, damage_increase, animation_increase, fov_increase, ragdoll_force_increase):
	if player.current_speed < 25:
		player.increase_speed.rpc(speed_increase)
	
	if current_damage < 100:
		current_damage += damage_increase
		if current_damage > 100:
			current_damage = 100
	
	if animation_player.speed_scale < 5:
		current_animation_speed += animation_increase
		animation_player.speed_scale = current_animation_speed
		if animation_player.speed_scale > 5:
			current_animation_speed = 5
	
	if animation_player_2.speed_scale < 5:
		current_animation_speed += animation_increase
		animation_player_2.speed_scale = current_animation_speed
		if animation_player_2.speed_scale > 5:
			current_animation_speed = 5
	
	if player.camera.fov < 140:
		player.camera.fov += fov_increase
		if player.camera.fov > 140:
			player.camera.fov = 140
	
	if current_ragdoll_force < 20:
		current_ragdoll_force += ragdoll_force_increase
		if current_ragdoll_force > 20:
			current_ragdoll_force = 20


@rpc ("call_local", "any_peer", "reliable")
func _half_stat_variables():
	var halved_speed = player.current_speed - 4
	var halved_animation_speed = current_animation_speed - 0.8
	var halved_damage = current_damage - 4
	var halved_fov = player.camera.fov - 8
	var halved_ragdoll = current_ragdoll_force - 4
	
	if halved_speed < player.default_speed:
		halved_speed = player.default_speed
	if halved_animation_speed < default_animation_speed:
		halved_animation_speed = default_animation_speed
	if halved_damage < default_damage:
		halved_damage = default_damage
	if halved_fov < 90:
		halved_fov = 90
	if halved_ragdoll < 4:
		halved_ragdoll = 4
	
	player.change_speed_and_jump.rpc(halved_speed)
	current_animation_speed = halved_animation_speed
	animation_player.speed_scale = current_animation_speed
	animation_player_2.speed_scale = current_animation_speed
	current_damage = halved_damage
	player.camera.fov = halved_fov
	current_ragdoll_force = halved_ragdoll

extends Weapon

@onready var tracer_spawn = $WeaponSway/TracerSpawn
@onready var gun = $WeaponSway/AllMesh/Gun
@export var bullet_tracer_scene : PackedScene

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("right_click") and current_ammo > 0 and !aiming:
		aiming = true
		hud.sniper_ads.show()
		hud.healthbar.hide()
		_play_ads_animation.rpc("aiming")
		self.hide()
		tracer_spawn.position = Vector3(-0.435, 0.162, -0.394)
		player.camera.fov = 20
		
		player.change_speed_and_jump(2)
	if (Input.is_action_just_released("right_click") or current_ammo == 0) and aiming:
		aiming = false
		hud.sniper_ads.hide()
		hud.healthbar.show()
		
		tracer_spawn.position = Vector3(0, 0.162, -0.394)
		
		self.show()
		_play_ads_animation.rpc("RESET")
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
			var collider_collision_point = raycast.get_collision_point()
			spawn_tracer_pivot.rpc(collider_collision_point)
			
			if collider.is_in_group("Hurtbox"):
				on_hit_effect()
				collider.handle_damage_collision(current_damage)
		else:
			spawn_tracer_pivot.rpc()
		
		recoil = true
		await get_tree().create_timer(0.1).timeout
		recoil = false
	
	if Input.is_action_just_pressed("reload") and animation_player.current_animation != "reload" and current_ammo != max_ammo:
		reload_weapon.rpc()


@rpc ("any_peer", "call_local", "reliable")
func spawn_tracer_pivot(collider = null):
	var distance = 1
	if collider != null:
		distance = raycast.global_position.distance_to(collider) / 50
	
	var bullet_tracer = bullet_tracer_scene.instantiate()
	
	bullet_tracer.position = tracer_spawn.global_position
	bullet_tracer.rotation = tracer_spawn.global_rotation
	
	bullet_tracer.scale.z = distance
	
	bullet_tracer.name = "item" + str(randf_range(0, 10))
	
	get_tree().current_scene.add_child(bullet_tracer, true)
	
	if collider != null:
		bullet_tracer.look_at(collider)
	await get_tree().create_timer(2).timeout
	bullet_tracer.queue_free()

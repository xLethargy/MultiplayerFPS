extends Weapon

@onready var coin_marker = $CoinMarker
@onready var coin_scene = preload("res://models/projectiles/coin.tscn")
@onready var coin_cooldown_timer = $CoinCooldown

var can_use_coin = true

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("right_click") and current_ammo > 0 and can_use_coin:
		_play_animation.rpc("flick")
		
		can_use_coin = false
		
		var boost_z = get_global_transform().basis.z
		
		if Input.is_action_pressed("move_up"):
			boost_z *= 10
		elif Input.is_action_pressed("move_down"):
			boost_z *= -2
		else:
			boost_z *= 2
		
		boost_z.y -= 4
		if boost_z.y > -5:
			boost_z.y = -5
		elif boost_z.y < -8.5:
			boost_z.y= -8.5
		_spawn_coin.rpc(boost_z)
		coin_cooldown_timer.start()
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot" and current_ammo >= 1:
		play_shoot_effects()
		play_spatial_audio.rpc()
		handle_raycast(raycast)
		
		recoil = true
		await get_tree().create_timer(0.1).timeout
		recoil = false
	
	if Input.is_action_just_pressed("reload") and animation_player.current_animation != "reload" and current_ammo != max_ammo:
		reload_weapon.rpc()


func handle_raycast(given_raycast):
	if given_raycast.is_colliding():
		var collider = given_raycast.get_collider()
		
		if collider.is_in_group("Hurtbox"):
			if collider.owner.is_in_group("Enemy"):
				if collider.has_method("handle_damage_collision"):
					on_hit_effect()
					collider.handle_damage_collision(current_damage)
			elif collider.has_method("handle_coin_collision"):
				on_hit_effect()
				collider.handle_coin_collision()
				make_coin_invisible.rpc(collider.owner.get_path())


@rpc ("call_local", "any_peer", "reliable")
func _spawn_coin(boost):
	var coin = coin_scene.instantiate()
	
	coin.position = coin_marker.global_position
	coin.rotation = coin_marker.global_rotation
	
	coin.name = "coin"
	
	coin.change_values(-boost, "forward")
	get_tree().current_scene.add_child(coin, true)


@rpc("any_peer", "call_local")
func make_coin_invisible(coin_path):
	var coin = get_node(coin_path)
	coin.mesh.visible = false
	coin.muzzle_flash.visible = false


func _on_coin_cooldown_timeout():
	can_use_coin = true

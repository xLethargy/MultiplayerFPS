extends Weapon

@onready var coin_marker = $CoinMarker
@onready var coin_scene = preload("res://models/projectiles/coin.tscn")
var coin_in_tree = false

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("right_click") and current_ammo > 0 and !coin_in_tree:
		_spawn_coin.rpc()
		
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
		var collider_collision_point = given_raycast.get_collision_point()
		
		if collider.is_in_group("Hurtbox"):
			if collider.owner.is_in_group("Enemy"):
				if collider.has_method("handle_damage_collision"):
					on_hit_effect()
					collider.handle_damage_collision(current_damage)
				elif collider.has_method("handle_coin_collision"):
					on_hit_effect()
					collider.handle_coin_collision()


@rpc ("any_peer", "call_local", "reliable")
func _spawn_coin():
	var distance = 1
	
	var coin = coin_scene.instantiate()
	
	coin.position = coin_marker.global_position
	coin.rotation = coin_marker.global_rotation
	
	coin.name = "coin " + str(randf_range(0, 10))
	
	get_tree().current_scene.add_child(coin, true)

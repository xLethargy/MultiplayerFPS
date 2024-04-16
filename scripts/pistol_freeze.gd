extends Weapon

@onready var freeze_regen_timer = $FreezeRegenTimer
@onready var ice_shatter_audio = $IceShatterLocal

var freeze_damage = 15

var hit_player = {}
var hits = 0

var slow_speed = 1.5
var jump_height = 1.5

var player_died = false

var current_health

var freeze_regen = false

var old_collider_speed
var frozen_collider

func _unhandled_input(event):
	if !player.is_multiplayer_authority():
		return
	
	if event.is_action_pressed("shoot") and animation_player.current_animation != "shoot" and ammo_bar.value > 0:
		play_shoot_effects()
		ammo_bar.value -= 10
		
		gun_audio.pitch_scale = 1.5 + (ammo_bar.value / 200)
		local_gun_audio.pitch_scale = 1.5 + (ammo_bar.value / 200)
		
		play_spatial_audio.rpc(gun_audio.pitch_scale)
		
		freeze_regen = false
		freeze_regen_timer.stop()
		freeze_regen_timer.start()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			handle_collision(collider)
			
			if collider.is_in_group("Hurtbox"):
				if collider.owner.is_in_group("Enemy"):
					current_health = collider.owner.health_component.current_health - current_damage
					
					if !hit_player.has(collider):
						hit_player[collider] = {
							"ID": collider.multiplayer.get_unique_id(),
							"HitsTaken": 0,
						}
						collider.owner.connect("remove_freeze_count", _remove_freeze_count.bind(hit_player[collider]))
					
					collider.owner.freeze_count_timer.stop()
					
					if current_health > 0:
						collider.owner.freeze_count_timer.start()
						store_freeze_information(collider)
					elif current_health <= 0:
						collider.owner.slow_timer.stop()
						hit_player[collider].HitsTaken = 0
		
		recoil = true
		await get_tree().create_timer(0.1).timeout
		recoil = false


func _process(delta):
	if freeze_regen and ammo_bar.value != ammo_bar.max_value:
		ammo_bar.value += 20 * delta


@rpc ("any_peer", "reliable")
func store_freeze_information(collider):
	hit_player[collider].HitsTaken += 1
	
	if hit_player[collider].HitsTaken == 3:
		ice_shatter_audio.play()
		
		hit_player[collider].HitsTaken = 0
		
		frozen_collider = collider
		
		old_collider_speed = collider.player.current_speed
		collider.player.old_speed = old_collider_speed
		
		collider.handle_damage_collision(freeze_damage)
		current_health = collider.owner.health_component.current_health - freeze_damage
		
		if current_health - current_damage > 0:
			collider.owner.change_speed_and_jump.rpc(slow_speed, jump_height, "frozen")
			collider.owner.slow_timer.start()
		else:
			collider.owner.slow_timer.stop()
			var boost = get_global_transform().basis.z * 1
			get_tree().current_scene.spawn_player_ragdoll.rpc(collider.owner.global_position, collider.owner.global_rotation, -boost, collider.owner.current_colour, collider.owner.hat)
			


func _on_freeze_regen_timer_timeout():
	freeze_regen = true


func _remove_freeze_count(player_no_count):
	player_no_count.HitsTaken = 0

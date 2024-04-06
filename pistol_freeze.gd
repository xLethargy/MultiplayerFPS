extends Weapon

@onready var freeze_regen_timer = $FreezeRegenTimer
@onready var ice_shatter_audio = $IceShatterLocal

var freeze_damage = 20

var hit_player = {}
var hits = 0

var slow_speed = 1.5
var jump_height = 1.5

var player_died = false

var current_health

var freeze_regen = false

var frozen = false

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot" and ammo_bar.value > 0:
		play_shoot_effects()
		ammo_bar.value -= 10
		
		gun_audio.pitch_scale = 1.5 + (ammo_bar.value / 200)
		local_gun_audio.pitch_scale = 1.5 + (ammo_bar.value / 200)
		
		print (gun_audio.pitch_scale)
		
		freeze_regen = false
		freeze_regen_timer.stop()
		freeze_regen_timer.start()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("Hurtbox"):
				if collider.owner.is_in_group("Enemy"):
					if collider.has_method("handle_damage_collision"):
						on_hit_effect()
						collider.handle_damage_collision(current_damage)
				
				current_health = collider.owner.health_component.current_health - current_damage
				
				if !hit_player.has(collider):
					hit_player[collider] = {
						"ID": collider.multiplayer.get_unique_id(),
						"HitsTaken": 0
					}
				
				if current_health > 0 and !frozen:
					store_freeze_information(collider)
				else:
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
		
		frozen = true
		
		var old_collider_speed = collider.player.default_speed
		
		collider.handle_damage_collision(freeze_damage)
		current_health = collider.owner.health_component.current_health - freeze_damage
		
		if current_health - current_damage > 0:
			collider.handle_speed_collision(slow_speed, jump_height)
			if !collider == null:
				collider.handle_speed_collision(old_collider_speed, collider.player.default_jump_velocity, true)
				frozen = false
		else:
			frozen = false


func _on_freeze_regen_timer_timeout():
	freeze_regen = true

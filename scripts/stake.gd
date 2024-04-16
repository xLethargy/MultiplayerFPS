extends Weapon

@onready var dash_cooldown_timer = $DashCooldown
@onready var hit_audio = $HitAudio

@onready var ability_dash_enabled = preload("res://images/abilities/dash_enabled.png")
@onready var ability_dash_disabled = preload("res://images/abilities/dash_disabled.png")

@onready var disable_hitbox_timer = $DisableHitboxTimer
@onready var hitbox = $Hitbox/CollisionShape3D

var thud_dir_path = "res://sounds/thud.wav"
var stab_dir_path = "res://sounds/stab.wav"

var charge_attack = false
var can_dash = true

var count = 1.5
var collider_in_way = false

func _process(delta):
	if charging and count < 5:
		count += delta
	elif count > 5:
		count = 5


func _unhandled_input(event):
	if !player.is_multiplayer_authority():
		return
	
	if event.is_action_pressed("shoot") and animation_player.current_animation != "shoot":
		hitbox.disabled = false
		disable_hitbox_timer.start()
		if raycast.is_colliding():
			if !raycast.get_collider().is_in_group("Hurtbox") and !raycast.get_collider().is_in_group("Player"):
				collider_in_way = true
				_play_spatial_for_all.rpc(hit_audio.get_path(), thud_dir_path, 0.8, 1.2)
			else:
				collider_in_way = false
		else:
			collider_in_way = false
		
		var random_pitch = randf_range(0.75, 1.25)
		gun_audio.pitch_scale = random_pitch
		local_gun_audio.pitch_scale = random_pitch
		
		play_shoot_effects()
		play_spatial_audio.rpc()
	
	if can_dash:
		if event.is_action_pressed("right_click"):
			_play_animation.rpc("charging")
			
			charging = true
			player.charging_dash = true
		
		elif event.is_action_released("right_click") and !player.in_dash and charging:
			_play_animation.rpc("dash")
			ability_icon.texture = ability_dash_disabled
			
			can_dash = false
			charging = false
			
			player.charging_dash = false
			player.in_dash = true
			
			player.charge_amount = count
			
			player.in_air_timer.start()
			
			dash_cooldown_timer.start()
			count = 1.5


func _on_dash_cooldown_timeout():
	can_dash = true
	ability_icon.texture = ability_dash_enabled


func _on_hitbox_area_entered(area):
	if player.is_multiplayer_authority():
		if area.owner.is_in_group("Team"):
			return
		
		await get_tree().create_timer(0.01).timeout
		if area.owner.is_in_group("Enemy"):
			if !collider_in_way:
				on_hit_effect()
				_play_spatial_for_all.rpc(hit_audio.get_path(), stab_dir_path, 0.8, 1.2)
				
				var damage_given = current_damage
				if player.in_dash and player.velocity.y < 0:
					damage_given = area.health_component.max_health
					area.handle_damage_collision(damage_given)
				else:
					area.handle_damage_collision(damage_given)
				
				
				if area.health_component.current_health - damage_given <= 0:
					var boost = raycast.get_global_transform().basis.z * current_ragdoll_force
					get_tree().current_scene.spawn_player_ragdoll.rpc(area.global_position, area.global_rotation, -boost, area.owner.current_colour, area.owner.hat)


func _on_enable_hitbox_timer_timeout():
	hitbox.disabled = true

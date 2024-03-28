extends Weapon

@onready var dash_cooldown_timer = $DashCooldown

var charging = false
var charge_attack = false
var can_dash = true

var count = 15


func _process(delta):
	if charging:
		count += delta * 5


func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot":
		play_shoot_effects()
		play_spatial_audio.rpc()
	
	if can_dash:
		if Input.is_action_just_pressed("right_click"):
			charging = true
			player.charging_dash = true
		elif Input.is_action_just_released("right_click") and !player.in_dash and charging:
			can_dash = false
			charging = false
			var boost_z = get_global_transform().basis.z * count
			boost_z.y = -15
			
			player.charging_dash = false
			player.in_air = true
			player.in_dash = true
			player.current_gravity *= 2
			player.in_air_timer.start()
			player.velocity = -boost_z
			
			dash_cooldown_timer.start()
			count = 15


func _on_dash_cooldown_timeout():
	can_dash = true


func _on_hitbox_area_entered(area):
	if player.is_multiplayer_authority():
		if area.owner.is_in_group("Enemy"):
			area.handle_damage_collision(current_damage)
			on_hit_effect()

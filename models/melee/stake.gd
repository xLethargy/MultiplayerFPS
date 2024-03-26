extends Weapon

var charging = false
var charge_attack = false

var count = 0

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot":
		play_shoot_effects()
		play_spatial_audio.rpc()
	
	if Input.is_action_just_pressed("right_click"):
		charging = true
	elif Input.is_action_just_released("right_click"):
		charging = false
		var target_position = Vector3(player.global_position.x + 10, player.global_position.y + 5, player.global_position.z + 10)
		#target_position.y = player.global_position.y + 5
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(player, "position", target_position, 1)
		#player.animation_player.play("charge")

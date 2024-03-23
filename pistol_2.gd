extends Node3D

@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer

@onready var animation_player = $AnimationPlayer
@onready var muzzle_flash = $MuzzleFlash
@onready var hitmarker = $Hitmarker
@onready var hitmarker_timer = $Hitmarkerlength

@onready var raycast = $"../Camera3D/RayCast3D"

@onready var level_scene = get_tree().current_scene
@onready var player = get_parent().get_parent()

var damage = 15

var can_shoot = true

func _physics_process(_delta):
	if !player.is_multiplayer_authority():
		return
	
	if !animation_player.current_animation == "shoot":
		if player.input_dir != Vector2.ZERO and player.is_on_floor():
			_play_animation.rpc("move")
		else:
			_play_animation.rpc("idle")
	
	if Input.is_action_pressed("shoot") and can_shoot:
		play_shoot_effects.rpc()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			var origin = raycast.global_transform.origin

			var distance_check = (origin.distance_to(raycast.get_collision_point())) / 2
			distance_check = int(distance_check) 
			if distance_check >= damage:
				distance_check = damage - 1
			var falloff_damage = damage - distance_check
			print (falloff_damage)
			if collider.is_in_group("Hurtbox"):
				play_local_shoot_effects()
				audio_player.play()
				collider.handle_damage_collision(falloff_damage)


@rpc ("call_local", "any_peer")
func play_shoot_effects():
	animation_player.stop()
	animation_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
	
	can_shoot = false
	$FiringRate.start()
	
	#level_scene.spawn_bullet(bullet_scene, bullet_spawn_location, owner)

@rpc ("call_local", "any_peer")
func _play_animation(animation_string):
	animation_player.play(animation_string)


func play_local_shoot_effects():
	hitmarker.show()
	hitmarker_timer.start()


func _on_hitmarkerlength_timeout():
	hitmarker.hide()


func _on_firing_rate_timeout():
	can_shoot = true

extends Node3D

@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer

@onready var animation_player = $AnimationPlayer
@onready var muzzle_flash = $MuzzleFlash
@onready var hitmarker = $Hitmarker
@onready var hitmarker_timer = $Hitmarkerlength

@onready var raycast = $"../RayCast3D"

@onready var level_scene = get_tree().current_scene
@onready var player = get_parent().get_parent()

var damage = 30

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("Hurtbox"):
				play_local_shoot_effects()
				audio_player.play()
				collider.handle_damage_collision(damage)


func _physics_process(_delta):
	if !player.is_multiplayer_authority():
		return
	
	if !animation_player.current_animation == "shoot":
		if player.input_dir != Vector2.ZERO and player.is_on_floor():
			_play_animation.rpc("move")
		else:
			_play_animation.rpc("idle")


@rpc ("call_local", "any_peer")
func play_shoot_effects():
	animation_player.stop()
	animation_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc ("call_local", "any_peer")
func _play_animation(animation_string):
	animation_player.play(animation_string)


func play_local_shoot_effects():
	hitmarker.show()
	hitmarker_timer.start()


func _on_hitmarkerlength_timeout():
	hitmarker.hide()

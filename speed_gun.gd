extends Node3D

@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer

@onready var animation_player = $AnimationPlayer
@onready var muzzle_flash = $Gun/MuzzleFlash
@onready var hitmarker = $Hitmarker
@onready var hitmarker_timer = $Hitmarkerlength
@onready var arm = $Pivot/Arm
@onready var revolver_audio = $RevolverAudio
@onready var local_revolver_audio = $LocalRevolverAudio

@onready var raycast = $"../Camera3D/RayCast3D"

@onready var level_scene = get_tree().current_scene
@onready var player = get_parent().get_parent()

var damage = 10

var animation_increase = 0.1
var damage_increase = 0.5
var player_speed_increase = 0.5

func _ready():
	player.default_speed = 4
	player.change_speed_and_jump()
	player.health_component.connect("death", reset_speed_gun)

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot":
		play_shoot_effects()
		play_spatial_audio.rpc()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("Hurtbox"):
				hitmarker_effect()
				audio_player.play()
				collider.handle_damage_collision(damage)
				
				handle_speed_gun_variables.rpc()
			else:
				reset_speed_gun.rpc()
		else:
			reset_speed_gun.rpc()


func _physics_process(_delta):
	if !player.is_multiplayer_authority():
		return
	
	if !animation_player.current_animation == "shoot":
		if player.input_dir != Vector2.ZERO and player.is_on_floor():
			_play_animation.rpc("move")
		else:
			_play_animation.rpc("idle")


func play_shoot_effects():
	local_revolver_audio.play()
	animation_player.stop()
	animation_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true


@rpc ("any_peer")
func play_spatial_audio():
	revolver_audio.play()
	animation_player.stop()
	animation_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true


@rpc ("call_local", "any_peer")
func _play_animation(animation_string):
	animation_player.play(animation_string)


func hitmarker_effect():
	hitmarker.show()
	hitmarker_timer.start()


func _on_hitmarkerlength_timeout():
	hitmarker.hide()


@rpc ("any_peer", "call_local")
func handle_speed_gun_variables():
	if player.current_speed < 25:
		player.increase_speed(player_speed_increase)
		if player.current_speed > 25:
			player.change_speed_and_jump.rpc(25)
	if damage < 100:
		damage += damage_increase
		if damage > 100:
			damage = 100
	
	if animation_player.speed_scale < 4:
		animation_player.speed_scale += animation_increase
		if animation_player.speed_scale > 4:
			animation_player.speed_scale = 4


@rpc ("any_peer", "call_local")
func reset_speed_gun(animation_speed = 0.5):
	player.change_speed_and_jump()
	animation_player.speed_scale = animation_speed
	damage = 15

class_name Weapon
extends Node3D

@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer

@onready var animation_player = $AnimationPlayer
@export var muzzle_flash : GPUParticles3D
@onready var hitmarker = $Hitmarker
@onready var hitmarker_timer = $Hitmarkerlength
@onready var arm = %Arm
@export var gun_audio : AudioStreamPlayer3D
@export var local_gun_audio : AudioStreamPlayer

@onready var raycast = $"../Camera3D/RayCast3D"

@onready var level_scene = get_tree().current_scene
@onready var player = get_parent().get_parent()

@onready var ammo_counter = get_tree().current_scene.get_node("MultiplayerMenu/HUD/Ammo")
@onready var ammo_bar = get_tree().current_scene.get_node("MultiplayerMenu/HUD/AmmoBar")

@export var default_damage = 20
@onready var current_damage = default_damage

@onready var default_animation_speed = animation_player.speed_scale
@onready var current_animation_speed = default_animation_speed

@export var max_ammo : int

@export var default_player_speed = 6.5

@export var current_ammo = max_ammo
var queued_reload = false

@export var mag_type : String

func _ready():
	if player.is_multiplayer_authority():
		player.default_speed = default_player_speed
		player.change_speed_and_jump()
		current_ammo = max_ammo
		
		hitmarker_timer.connect("timeout", _on_hitmarkerlength_timeout)
		animation_player.connect("animation_finished", _on_animation_player_animation_finished)
		ammo_counter.text = str(current_ammo)
		
		if is_in_group("AmmoBar"):
			ammo_bar.show()
			ammo_counter.hide()
		elif is_in_group("AmmoCounter"):
			ammo_bar.hide()
			ammo_counter.show()
		else:
			ammo_bar.hide()
			ammo_counter.hide()
		
		player.health_component.connect("death", reset_stat_gun)

func _unhandled_input(_event):
	if !player.is_multiplayer_authority():
		return


func _physics_process(_delta):
	if !player.is_multiplayer_authority():
		return
	
	if !animation_player.current_animation == "shoot" and !animation_player.current_animation == "reload":
		if player.input_dir != Vector2.ZERO and player.is_on_floor():
			_play_animation.rpc("move")
		else:
			_play_animation.rpc("idle")


@rpc ("call_local", "any_peer")
func reload_weapon():
	if animation_player.current_animation == "shoot" and !queued_reload:
		animation_player.queue("reload")
		queued_reload = true
	elif !queued_reload:
		animation_player.stop()
		animation_player.play("reload")


func play_shoot_effects():
	if local_gun_audio != null:
		local_gun_audio.play()
	
	animation_player.stop()
	animation_player.play("shoot")
	
	if is_in_group("Ranged"):
		muzzle_flash.restart()
		muzzle_flash.emitting = true
		current_ammo -= 1
		queued_reload = false
		ammo_counter.text = str(current_ammo)

@rpc ("call_local", "any_peer", "reliable")
func _play_animation(animation_string):
	if animation_string == "idle" or animation_string == "move":
		return
	
	animation_player.play(animation_string)


@rpc ("any_peer")
func play_spatial_audio():
	if gun_audio != null:
		gun_audio.play()
	
	animation_player.stop()
	animation_player.play("shoot")
	
	if is_in_group("Ranged"):
		muzzle_flash.restart()
		muzzle_flash.emitting = true


func on_hit_effect():
	audio_player.play()
	hitmarker.show()
	hitmarker_timer.start()


func _on_hitmarkerlength_timeout():
	hitmarker.hide()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "reload":
		if mag_type == "Single":
			current_ammo = max_ammo
			ammo_counter.text = str(current_ammo)
			queued_reload = false
		elif mag_type == "Revolver":
			current_ammo += 1
			ammo_counter.text = str(current_ammo)
			if current_ammo != max_ammo:
				_play_animation.rpc("reload")
			else:
				queued_reload = false
	elif current_ammo == 0 and !queued_reload:
		_play_animation.rpc("reload")


func reset_stat_gun(reset_ammo = true):
	player.change_speed_and_jump()
	current_animation_speed = default_animation_speed
	animation_player.speed_scale = current_animation_speed
	current_damage = default_damage
	
	player.camera.fov = 90
	
	if reset_ammo:
		current_ammo = max_ammo
		ammo_counter.text = str(current_ammo)
		ammo_bar.value = ammo_bar.max_value

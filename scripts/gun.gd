class_name Weapon
extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var animation_player_2 = $AnimationPlayer2
@export var muzzle_flash : GPUParticles3D
@onready var arm = %Arm
@onready var arm_two = %Arm2
@export var gun_audio : AudioStreamPlayer3D
@export var local_gun_audio : AudioStreamPlayer
@export var hurtbox_arms : Area3D

@onready var raycast = $"../Camera3D/RayCast3D"

@export var weapon_sway_node : Node3D

@onready var level_scene = get_tree().current_scene
@onready var player = get_parent().get_parent()
@onready var view = get_parent()

@onready var ammo_counter = get_tree().current_scene.get_node("MultiplayerMenu/HUD/Ammo")
@onready var ammo_bar = get_tree().current_scene.get_node("MultiplayerMenu/HUD/AmmoBar")
@onready var ability_icon = get_tree().current_scene.get_node("MultiplayerMenu/HUD/Ability")

@export var default_damage = 20
@onready var current_damage = default_damage

@onready var default_animation_speed = animation_player.speed_scale
@onready var current_animation_speed = default_animation_speed

@export var max_ammo : int

@export var default_player_speed = 6.5

@export var current_ammo = max_ammo
var queued_reload = false

@export var mag_type : String
@export var weapon_rotation_amount = 0.5

@onready var crosshair = level_scene.get_node("MultiplayerMenu/HUD/Crosshair")
@onready var hud = level_scene.get_node("MultiplayerMenu/HUD")
@onready var hitmarker = level_scene.get_node("MultiplayerMenu/HUD/Hitmarker")
@onready var hitmarker_timer = level_scene.get_node("MultiplayerMenu/HUD/Hitmarker/Hitmarkerlength")
@onready var audio_player : AudioStreamPlayer = level_scene.get_node("MultiplayerMenu/HUD/Hitmarker/HitmarkerAudio")

var recoil = false
@export var recoil_amount : float = 1

var tracer_timer : Timer
var aiming = false
var charging = false

@export var ability_icon_enabled : CompressedTexture2D

@export var default_ragdoll_force : float
@onready var current_ragdoll_force : float = default_ragdoll_force

@export var hat : String

func _ready():
	await get_tree().create_timer(0.1).timeout
	if player.is_multiplayer_authority():
		
		if is_in_group("Hat"):
			if player.hat != null:
				player.remove_hat.rpc()
			player.add_hat(hat)
		else:
			if player.hat != null:
				player.remove_hat.rpc()
			player.hat = null
		
		
		raycast.target_position = Vector3(0, 0, -50)
		
		player.default_speed = default_player_speed
		player.change_speed_and_jump(default_player_speed)
		current_ammo = max_ammo
		player.weapon_rotation_amount = weapon_rotation_amount
		
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
		
		if is_in_group("NoCrosshair"):
			crosshair.hide()
		else:
			crosshair.show()
		
		if is_in_group("Melee"):
			raycast.target_position.z = -2
		else:
			raycast.target_position.z = -50
		
		if is_in_group("Ability"):
			ability_icon.texture = ability_icon_enabled
			ability_icon.show()
		else:
			ability_icon.hide()
		
		player.health_component.connect("death", reset_stat_gun_rpc)


func _physics_process(delta):
	if !player.is_multiplayer_authority():
		return
	
	if player.input_dir != Vector2.ZERO and player.is_on_floor() and !aiming and !charging:
		_play_animation.rpc("move", animation_player_2.get_path())
	elif (player.input_dir == Vector2.ZERO or !player.is_on_floor()) and !aiming:
		_play_animation.rpc("idle", animation_player_2.get_path())
	
	if recoil:
		var recoil_adjustment = view.rotation.x + recoil_amount * delta
		if recoil_adjustment > deg_to_rad(90):
			recoil_adjustment = deg_to_rad(90)
		view.rotation.x = recoil_adjustment


@rpc ("call_local", "any_peer", "reliable")
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
	
	if animation_player.current_animation != "aiming":
		animation_player.stop()
	animation_player.play("shoot")
	
	if is_in_group("Ranged"):
		muzzle_flash.restart()
		muzzle_flash.emitting = true
		current_ammo -= 1
		queued_reload = false
		ammo_counter.text = str(current_ammo)


@rpc ("call_local", "any_peer", "reliable")
func _play_animation(animation_string, given_player_path = animation_player.get_path()):
	var given_player = get_node_or_null(given_player_path)
	
	if given_player != null:
		given_player.play(animation_string)


@rpc ("any_peer", "reliable")
func _play_ads_animation(animation_string):
	animation_player.play(animation_string)

@rpc ("any_peer", "reliable")
func play_spatial_audio(given_pitch_scale = 1):
	if gun_audio != null:
		gun_audio.pitch_scale = given_pitch_scale
		gun_audio.play()
	
	animation_player.stop()
	animation_player.play("shoot")
	
	if is_in_group("Ranged"):
		muzzle_flash.restart()
		muzzle_flash.emitting = true


func on_hit_effect(audio = true):
	if audio:
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
			if current_ammo < max_ammo:
				_play_animation.rpc("reload")
			else:
				queued_reload = false
	elif current_ammo == 0 and !queued_reload:
		_play_animation.rpc("reload")

func reset_stat_gun_rpc():
	call_deferred("reset_stat_gun")

@rpc ("any_peer", "call_local", "reliable")
func reset_stat_gun(reset_ammo = true):
	animation_player.stop()
	animation_player_2.stop()
	
	player.change_speed_and_jump()
	current_animation_speed = default_animation_speed
	animation_player.speed_scale = default_animation_speed
	animation_player_2.speed_scale = default_animation_speed
	current_damage = default_damage
	
	animation_player.play("RESET")
	animation_player_2.play("RESET")
	
	player.camera.fov = 90
	
	player.old_speed = default_player_speed
	
	current_ragdoll_force = default_ragdoll_force
	
	aiming = false
	hud.sniper_ads.hide()
	hud.healthbar.show()
	
	if reset_ammo:
		current_ammo = max_ammo
		ammo_counter.text = str(current_ammo)
		ammo_bar.value = ammo_bar.max_value


@rpc("any_peer", "call_local")
func make_coin_invisible(coin_path):
	var coin = get_node(coin_path)
	coin.mesh.visible = false
	coin.muzzle_flash.visible = false


func handle_collision(collider, given_damage = current_damage):
	if collider.is_in_group("Hurtbox"):
<<<<<<< HEAD
		if collider.has_method("handle_coin_collision"):
=======
		if collider.owner.is_in_group("Enemy"):
			if collider.has_method("handle_damage_collision"):
				on_hit_effect()
				collider.handle_damage_collision(given_damage)
				
				if collider.health_component.current_health - given_damage <= 0:
					var test_boost = get_global_transform().basis.z * current_ragdoll_force
					
					#print (collider.owner.hat)
					get_tree().current_scene.spawn_player_ragdoll.rpc(collider.global_position, collider.global_rotation, -test_boost, collider.owner.current_colour)
		elif collider.has_method("handle_coin_collision"):
>>>>>>> parent of e101728 (Heavy bug fixing, gun reworks, and more)
			on_hit_effect(false)
			collider.handle_coin_collision()
			make_coin_invisible.rpc(collider.owner.get_path())
		elif collider.owner.is_in_group("Enemy") or collider.owner.player.is_in_group("Enemy"):
			var collider_player
			if collider.owner.is_in_group("Enemy"):
				collider_player = collider.owner
			elif collider.owner.player.is_in_group("Enemy"):
				collider_player = collider.owner.player
			if collider_player.hurtbox.has_method("handle_damage_collision"):
				on_hit_effect()
				collider_player.hurtbox.handle_damage_collision(given_damage)
				
				if collider_player.health_component.current_health - given_damage <= 0:
					var boost = get_global_transform().basis.z * current_ragdoll_force
					boost.y *= 2
					get_tree().current_scene.spawn_player_ragdoll.rpc(collider_player.global_position, collider_player.global_rotation, -boost, collider_player.current_colour, collider_player.hat)


func play_footstep():
	player.play_footstep_audio.rpc()


@rpc ("any_peer", "call_local", "reliable")
func _play_spatial_for_all(given_audio_path, stream, min_pitch_scale_range = 1, max_pitch_scale_range = 1):
	var given_audio = get_node_or_null(given_audio_path)
	if given_audio != null:
		given_audio.stream = load(stream)
		given_audio.pitch_scale = randf_range(min_pitch_scale_range, max_pitch_scale_range)
		given_audio.play()

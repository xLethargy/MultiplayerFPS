extends Node3D

@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer

@onready var animation_player = $AnimationPlayer
@onready var muzzle_flash = $MuzzleFlash
@onready var hitmarker = $Hitmarker
@onready var hitmarker_timer = $Hitmarkerlength

@onready var raycast = $"../RayCast3D"

@onready var level_scene = get_tree().current_scene
@onready var player = get_parent().get_parent()

var damage = 10
var freeze_damage = 19

var hit_player = {}
var hits = 0

var slow_speed = 1.5
var jump_height = 1.5

var player_died = false

var current_health

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
				current_health = collider.owner.health_component.current_health - damage
				
				if !hit_player.has(collider):
					hit_player[collider] = {
						"ID": collider.multiplayer.get_unique_id(),
						"HitsTaken": 0
					}
				
				if current_health > 0:
					store_freeze_information(collider)
				else:
					hit_player[collider].HitsTaken = 0
				


@rpc ("any_peer")
func store_freeze_information(collider):
	hit_player[collider].HitsTaken += 1
	
	if hit_player[collider].HitsTaken == 3:
		hit_player[collider].HitsTaken = 0
		
		var old_collider_speed = collider.player.current_speed
		
		collider.handle_damage_collision(freeze_damage)
		collider.handle_speed_collision(slow_speed, jump_height)
		current_health = collider.owner.health_component.current_health - freeze_damage
		
		
		
		$SlowTimer.start()
		await $SlowTimer.timeout
		if !collider == null:
			collider.handle_speed_collision(old_collider_speed)
	
	

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
	
	#level_scene.spawn_bullet(bullet_scene, bullet_spawn_location, owner)

@rpc ("call_local", "any_peer")
func _play_animation(animation_string):
	animation_player.play(animation_string)


func play_local_shoot_effects():
	hitmarker.show()
	hitmarker_timer.start()


func _on_hitmarkerlength_timeout():
	hitmarker.hide()
